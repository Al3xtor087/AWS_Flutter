import json
import os
import boto3
from decimal import Decimal

# --- Lógica para determinar el entorno (Local vs. AWS) ---
IS_OFFLINE = os.environ.get('AWS_SAM_LOCAL')

if IS_OFFLINE:
    dynamodb = boto3.resource('dynamodb', endpoint_url="http://host.docker.internal:8000")
else:
    dynamodb = boto3.resource('dynamodb')

TABLA_USUARIOS = os.environ.get('TABLA_USUARIOS', 'UsuariosBD')
TABLA_ALUMNOS = os.environ.get('TABLA_ALUMNOS', 'AlumnosBD')
tabla_usuarios = dynamodb.Table(TABLA_USUARIOS)
tabla_alumnos = dynamodb.Table(TABLA_ALUMNOS)

class DecimalEncoder(json.JSONEncoder):
    def default(self, o):
        if isinstance(o, Decimal):
            return float(o) if o % 1 else int(o)
        return super(DecimalEncoder, self).default(o)

def keys_to_camel_case(d):
    if isinstance(d, list):
        return [keys_to_camel_case(i) for i in d]
    if isinstance(d, dict):
        return { (k[0].lower() + k[1:] if k else ''): keys_to_camel_case(v) for k, v in d.items()}
    return d

def lambda_handler(event, context):
    try:
        # 1. Obtener todos los usuarios de la tabla de usuarios
        response_usuarios = tabla_usuarios.scan()
        usuarios = response_usuarios.get('Items', [])
        
        # 2. Procesar cada usuario para vincular la información del alumno
        for usuario in usuarios:
            if 'alumnoId' in usuario and usuario['alumnoId']:
                try:
                    response_alumno = tabla_alumnos.get_item(
                        Key={'id': str(usuario['alumnoId'])}
                    )
                    if 'Item' in response_alumno:
                        # Adjuntamos la información del alumno directamente
                        usuario['alumno'] = response_alumno['Item']
                except Exception as e:
                    print(f"Error fetching student for user {usuario['id']}: {e}")
                    usuario['alumno'] = None
        
        # 3. Formatear la respuesta
        usuarios_camel_case = keys_to_camel_case(usuarios)

        # 4. Construir la respuesta final con la estructura que el frontend espera
        usuarios_finales = []
        for u in usuarios_camel_case:
            alumno_info = u.get('alumno')
            usuario_formateado = {
                'id': u.get('id'),
                'email': u.get('email', ''),
                'rol': u.get('rol', 'ALUMNO'),
                'alumnoId': u.get('alumnoId'),
                'alumno': 'No vinculado',
                'numeroControl': 'N/A'
            }
            if alumno_info:
                usuario_formateado['alumno'] = alumno_info.get('nombreCompleto', 'No vinculado')
                usuario_formateado['numeroControl'] = alumno_info.get('numeroControl', 'N/A')
            
            usuarios_finales.append(usuario_formateado)

        return {
            "statusCode": 200,
            "headers": {
                "Content-Type": "application/json",
                "Access-Control-Allow-Origin": "*",
            },
            "body": json.dumps(usuarios_finales, cls=DecimalEncoder)
        }
        
    except Exception as e:
        print(f"Error in lambda_handler: {e}")
        return {
            "statusCode": 500,
            "headers": {
                "Content-Type": "application/json",
                "Access-Control-Allow-Origin": "*",
            },
            "body": json.dumps({"error": str(e)})
        }