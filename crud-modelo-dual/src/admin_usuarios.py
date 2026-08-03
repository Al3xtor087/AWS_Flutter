import json
import os
import boto3

# --- Lógica para determinar el entorno (Local vs. AWS) ---
IS_OFFLINE = os.environ.get('AWS_SAM_LOCAL')

if IS_OFFLINE:
    # Conexión a DynamoDB local si estamos en modo offline
    dynamodb = boto3.resource('dynamodb', endpoint_url="http://host.docker.internal:8000")
else:
    # Conexión a DynamoDB en la nube de AWS
    dynamodb = boto3.resource('dynamodb')

cognito_client = boto3.client('cognito-idp')

# --- Variables de Entorno ---
TABLA_USUARIOS = os.environ.get('TABLA_USUARIOS', 'UsuariosBD')
TABLA_ALUMNOS = os.environ.get('TABLA_ALUMNOS', 'AlumnosBD')
USER_POOL_ID = os.environ.get('USER_POOL_ID')

# --- Tablas de DynamoDB ---
tabla_usuarios = dynamodb.Table(TABLA_USUARIOS)
tabla_alumnos = dynamodb.Table(TABLA_ALUMNOS)

# --- Función Auxiliar para crear respuestas HTTP ---
def _crear_respuesta(status_code, body):
    # Crea una respuesta HTTP estándar con cabeceras CORS.
    return {
        "statusCode": status_code,
        "headers": {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Methods": "GET,POST,PUT,DELETE,OPTIONS",
            "Access-Control-Allow-Headers": "Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token"
        },
        "body": json.dumps(body)
    }

def lambda_handler(event, context):
    # --- Manejo de Peticiones OPTIONS (Pre-vuelo de CORS) ---
    if event.get('httpMethod') == 'OPTIONS':
        # Devuelve una respuesta exitosa para la petición de pre-vuelo.
        # El navegador realiza esta petición automáticamente antes de PUT, DELETE, etc.
        return _crear_respuesta(200, {"mensaje": "Pre-vuelo CORS exitoso"})
        
    try:
        http_method = event.get('httpMethod')
        # Extraemos la ruta para saber qué acción realizar (ej: /cambiar-rol)
        path = event.get('path', '')

        # --- ACCIÓN: ELIMINAR USUARIO (Maneja peticiones DELETE) ---
        if http_method == 'DELETE' and '/admin/usuario/' in path:
            try:
                # 1. Extraer el ID del usuario desde la URL (ej: /admin/usuario/uuid-1234)
                usuario_id = path.split('/')[-1]

                # 2. Buscar al usuario en nuestra base de datos (DynamoDB) para obtener su email
                respuesta_db = tabla_usuarios.get_item(Key={'id': usuario_id})
                if 'Item' not in respuesta_db:
                    # Si el usuario ya no existe en DynamoDB, consideramos la operación exitosa.
                    return _crear_respuesta(200, {"mensaje": "Usuario ya había sido eliminado."})
                
                email_a_eliminar = respuesta_db['Item'].get('email')

                # 3. Eliminar el usuario de AWS Cognito
                if email_a_eliminar and USER_POOL_ID:
                    try:
                        cognito_client.admin_delete_user(
                            UserPoolId=USER_POOL_ID,
                            Username=email_a_eliminar
                        )
                    except cognito_client.exceptions.UserNotFoundException:
                        # Si no está en Cognito, no es un error crítico. Lo registramos y continuamos.
                        print(f"Advertencia: Usuario {email_a_eliminar} no encontrado en Cognito, pero se eliminará de DynamoDB.")
                
                # 4. Eliminar el registro del usuario de nuestra tabla 'UsuariosBD' en DynamoDB
                tabla_usuarios.delete_item(Key={'id': usuario_id})

                return _crear_respuesta(200, {"mensaje": "Usuario eliminado de Cognito y la base de datos."})

            except Exception as e:
                print(f"Error durante la eliminación del usuario: {e}")
                return _crear_respuesta(500, {"mensaje": "Error interno al eliminar el usuario."})

        # --- LÓGICA PARA PETICIONES PUT (cambiar rol, vincular) ---
        body = json.loads(event.get('body', '{}'))
        email = body.get('email')

        if not email:
            return _crear_respuesta(400, {"mensaje": "El email del usuario es obligatorio."})

        # --- ACCIÓN 1: CAMBIAR ROL ---
        if 'cambiar-rol' in path:
            nuevo_rol = body.get('nuevoRol')
            if not nuevo_rol:
                return _crear_respuesta(400, {"mensaje": "El nuevo rol es obligatorio."})

            # 1. Actualizar el atributo 'custom:rol' en Cognito
            cognito_client.admin_update_user_attributes(
                UserPoolId=USER_POOL_ID,
                Username=email,
                UserAttributes=[{'Name': 'custom:rol', 'Value': nuevo_rol}]
            )

            # 2. Actualizar el rol en nuestra tabla local 'UsuariosBD' para consistencia
            respuesta_scan = tabla_usuarios.scan(FilterExpression="email = :e", ExpressionAttributeValues={":e": email})
            if respuesta_scan.get('Items'):
                usuario_id = respuesta_scan['Items'][0]['id']
                tabla_usuarios.update_item(
                    Key={'id': usuario_id},
                    UpdateExpression="SET rol = :r",
                    ExpressionAttributeValues={":r": nuevo_rol}
                )

            return _crear_respuesta(200, {"mensaje": f"Rol del usuario {email} actualizado a {nuevo_rol}."})

        # --- ACCIÓN 2: VINCULAR ALUMNO ---
        elif 'vincular-alumno' in path:
            alumno_id = body.get('alumnoId')
            if not alumno_id:
                return _crear_respuesta(400, {"mensaje": "El ID del alumno es obligatorio."})

            # 1. Actualizar el 'custom:alumnoId' en Cognito
            cognito_client.admin_update_user_attributes(
                UserPoolId=USER_POOL_ID,
                Username=email,
                UserAttributes=[{'Name': 'custom:alumnoId', 'Value': str(alumno_id)}]
            )

            # 2. Buscar datos del alumno en 'AlumnosBD' para denormalizarlos
            respuesta_alumno = tabla_alumnos.get_item(Key={'id': str(alumno_id)})
            if 'Item' not in respuesta_alumno:
                return _crear_respuesta(404, {"mensaje": "El alumno a vincular no existe."})
            
            alumno_data = respuesta_alumno['Item']

            # Construimos y "limpiamos" el objeto del alumno antes de guardarlo.
            alumno_a_vincular = {
                'id': alumno_data.get('id'),
                'nombreCompleto': alumno_data.get('nombreCompleto'),
                'numeroControl': alumno_data.get('numeroControl')
            }
            alumno_limpio = {k: v for k, v in alumno_a_vincular.items() if v}

            # 3. Actualizar la tabla 'UsuariosBD' y obtener el registro actualizado
            respuesta_scan = tabla_usuarios.scan(FilterExpression="email = :e", ExpressionAttributeValues={":e": email})
            if respuesta_scan.get('Items'):
                usuario_id = respuesta_scan['Items'][0]['id']
                respuesta_actualizada = tabla_usuarios.update_item(
                    Key={'id': usuario_id},
                    UpdateExpression="SET alumnoId = :aid, alumno = :adata",
                    ExpressionAttributeValues={
                        ":aid": alumno_id,
                        ":adata": alumno_limpio
                    },
                    ReturnValues="ALL_NEW"
                )

                return _crear_respuesta(200, respuesta_actualizada.get('Attributes', {}))

            # Si no se encontró el usuario para actualizar, devolvemos un error.
            return _crear_respuesta(404, {"mensaje": f"No se encontró un usuario con el email {email}."})

        # Si la ruta no coincide con ninguna acción
        return _crear_respuesta(404, {"mensaje": "Acción no encontrada."})

    except Exception as e:
        print(f"Error en Lambda de Administración: {e}")
        # Devolvemos una respuesta genérica de error
        return _crear_respuesta(500, {"error": str(e)})