import json
import os
import boto3
import uuid

# --- Lógica para determinar el entorno (Local vs. AWS) ---
IS_OFFLINE = os.environ.get('AWS_SAM_LOCAL')

if IS_OFFLINE:
    dynamodb = boto3.resource('dynamodb', endpoint_url="http://host.docker.internal:8000")
else:
    dynamodb = boto3.resource('dynamodb')

cognito_client = boto3.client('cognito-idp', region_name='us-east-1')

# SAM inyectará esta variable desde tu template.yaml
CLIENT_ID = os.environ.get('COGNITO_CLIENT_ID') 
TABLA_USUARIOS = os.environ.get('TABLA_USUARIOS', 'UsuariosBD')
TABLA_ALUMNOS = os.environ.get('TABLA_ALUMNOS', 'AlumnosBD')

tabla_usuarios = dynamodb.Table(TABLA_USUARIOS)
tabla_alumnos = dynamodb.Table(TABLA_ALUMNOS)

def lambda_handler(event, context):
    try:
        # 1. Validar que el cuerpo de la petición no venga vacío
        if not event.get('body'):
            return {
                "statusCode": 400,
                "headers": { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
                "body": json.dumps({"mensaje": "El cuerpo de la petición no puede estar vacío"})
            }
        
        body = json.loads(event['body'])
        
        # 2. Extraer los datos del formulario de Angular
        email = body.get('email')
        password = body.get('password')
        alumno_id = body.get('alumnoId') # Vinculación con tu BD de Dynamo
        nombre = body.get('nombreCompleto') or body.get('nombre') or "Alumno Nuevo"

        if not email or not password:
            return {
                "statusCode": 400,
                "headers": { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
                "body": json.dumps({"mensaje": "El email y el password son campos obligatorios"})
            }

        # 3. Registrar al usuario en AWS Cognito sin pedir token previo
        respuesta_cognito = cognito_client.sign_up(
            ClientId=CLIENT_ID,
            Username=email,
            Password=password,
            UserAttributes=[
                {'Name': 'email', 'Value': email},
                {'Name': 'custom:rol', 'Value': 'ALUMNO'},
                {'Name': 'custom:alumnoId', 'Value': str(alumno_id or '0')},
                
                # Ahora sí, 'nombre' ya existe y no romperá el código
                {'Name': 'name', 'Value': str(nombre)}, 
                {'Name': 'profile', 'Value': 'https://example.com/default-avatar.png'}
            ]
        )

        # 4. Crear el registro del usuario en nuestra tabla local 'UsuariosBD'
        user_id = str(uuid.uuid4())
        nuevo_usuario = {
            'id': user_id,
            'email': email,
            'rol': 'ALUMNO',
            'alumnoId': alumno_id,
            'alumno': None
        }

        # Si se proporcionó un alumnoId, buscamos sus datos para denormalizarlos
        if alumno_id:
            try:
                respuesta_scan = tabla_alumnos.scan(
                    FilterExpression="id = :aid",
                    ExpressionAttributeValues={':aid': str(alumno_id)}
                )
                if 'Items' in respuesta_scan and len(respuesta_scan['Items']) > 0:
                    alumno_data = respuesta_scan['Items'][0]

                    # Este código elimina cualquier campo que sea nulo o una cadena vacía.
                    alumno_a_vincular = {
                        'id': alumno_data.get('id'),
                        'nombreCompleto': alumno_data.get('nombreCompleto'),
                        'numeroControl': alumno_data.get('numeroControl')
                    }
                    
                    # El diccionario final solo contendrá campos con valores válidos.
                    nuevo_usuario['alumno'] = {k: v for k, v in alumno_a_vincular.items() if v}
            except Exception as e:
                print(f"Advertencia: No se pudo vincular al alumno {alumno_id} durante el registro. Error: {e}")

        # Guardar en DynamoDB
        tabla_usuarios.put_item(Item=nuevo_usuario)

        print(f"[DEBUG] Nuevo usuario registrado en Cognito y DynamoDB: {email}")

        return {
            "statusCode": 201,
            "headers": { 
                "Content-Type": "application/json", 
                "Access-Control-Allow-Origin": "*",
                "Access-Control-Allow-Headers": "Content-Type,Authorization",
                "Access-Control-Allow-Methods": "POST,OPTIONS"
            },
            "body": json.dumps({
                "mensaje": "Usuario registrado exitosamente",
                "userSub": respuesta_cognito.get('UserSub')
            })
        }

    except cognito_client.exceptions.UsernameExistsException:
        return {
            "statusCode": 400,
            "headers": { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
            "body": json.dumps({"mensaje": "Este correo electrónico ya se encuentra registrado"})
        }
    except Exception as e:
        print(f"[ERROR CRÍTICO] Falló el registro de usuario: {str(e)}")
        return {
            "statusCode": 500,
            "headers": { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
            "body": json.dumps({"mensaje": "Error interno al procesar el registro", "error": str(e)})
        }