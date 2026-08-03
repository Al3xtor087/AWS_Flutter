import json
import os
import boto3
from decimal import Decimal

# --- Configuración de DynamoDB ---
IS_OFFLINE = os.environ.get('AWS_SAM_LOCAL')
if IS_OFFLINE:
    dynamodb = boto3.resource('dynamodb', endpoint_url="http://host.docker.internal:8000")
else:
    dynamodb = boto3.resource('dynamodb')

TABLA_USUARIOS = os.environ.get('TABLA_USUARIOS', 'UsuariosBD')
TABLA_ALUMNOS = os.environ.get('TABLA_ALUMNOS', 'AlumnosBD')
tabla_usuarios = dynamodb.Table(TABLA_USUARIOS)
tabla_alumnos = dynamodb.Table(TABLA_ALUMNOS)

# --- Clases y Funciones de Ayuda ---
class DecimalEncoder(json.JSONEncoder):
    #Clase para convertir objetos Decimal de DynamoDB a int/float.
    def default(self, o):
        if isinstance(o, Decimal):
            return float(o) if o % 1 else int(o)
        return super(DecimalEncoder, self).default(o)

def crear_respuesta(status_code, body):
    #Crea una respuesta HTTP estándar con cabeceras CORS.
    return {
        "statusCode": status_code,
        "headers": {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
        },
        "body": json.dumps(body, cls=DecimalEncoder)
    }

# --- Handler Principal de la Lambda ---
def lambda_handler(event, context):
    #Obtiene el perfil del usuario autenticado desde la tabla UsuariosBD.
    try:
        # 1. Obtener los datos del usuario desde el token de Cognito.
        # El autorizador de API Gateway pasa los claims del token en el contexto.
        claims = event.get('requestContext', {}).get('authorizer', {}).get('claims', {})
        email_usuario = claims.get('email')
        rol_cognito = claims.get('custom:rol')
        alumno_id_cognito = claims.get('custom:alumnoId')

        if not email_usuario:
            return crear_respuesta(403, {"mensaje": "No se pudo identificar al usuario desde el token."})

        # 2. Construir el perfil usando Cognito como fuente principal.
        perfil_usuario = {
            "email": email_usuario,
            "rol": rol_cognito or "ALUMNO",
            "alumnoId": alumno_id_cognito,
        }

        # 3. Enriquecer con la fila local solo como respaldo, sin sobreescribir
        # los datos que vienen en el token.
        respuesta_scan = tabla_usuarios.scan(
            FilterExpression="email = :email",
            ExpressionAttributeValues={':email': email_usuario}
        )

        items = respuesta_scan.get('Items', [])
        if items:
            registro_local = items[0]
            perfil_usuario["id"] = registro_local.get("id")
            if not perfil_usuario.get("alumnoId"):
                perfil_usuario["alumnoId"] = registro_local.get("alumnoId")

        # 4. Si hay alumno vinculado, anexamos su información.
        alumno_id = perfil_usuario.get("alumnoId")
        if alumno_id:
            respuesta_alumno = tabla_alumnos.get_item(Key={"id": str(alumno_id)})
            perfil_usuario["alumno"] = respuesta_alumno.get("Item")
        else:
            perfil_usuario["alumno"] = None

        return crear_respuesta(200, perfil_usuario)

    except Exception as e:
        print(f"[ERROR] en perfil_usuario: {str(e)}")
        return crear_respuesta(500, {"mensaje": "Error interno del servidor.", "error": str(e)})
