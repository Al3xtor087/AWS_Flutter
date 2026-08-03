import json
import os
import boto3
from decimal import Decimal
from botocore.config import Config

# Helper para manejar números Decimal de DynamoDB sin romper el JSON
class DecimalEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, Decimal):
            return float(obj) if obj % 1 != 0 else int(obj)
        return super(DecimalEncoder, self).default(obj)

# Timeout estricto de 2 segundos para evitar que la API local se congele si Cognito no responde
config_timeout = Config(connect_timeout=2, read_timeout=2, retries={'max_attempts': 1})

# --- Lógica para determinar el entorno (Local vs. AWS) ---
IS_OFFLINE = os.environ.get('AWS_SAM_LOCAL')

if IS_OFFLINE:
    dynamodb = boto3.resource('dynamodb', endpoint_url="http://host.docker.internal:8000")
else:
    dynamodb = boto3.resource('dynamodb')
cognito_client = boto3.client('cognito-idp', config=config_timeout)

TABLA_ALUMNOS = os.environ['TABLA_ALUMNOS']
USER_POOL_ID = os.environ.get('USER_POOL_ID')
tabla = dynamodb.Table(TABLA_ALUMNOS)

def obtenerAlumnos(event, context):
    try:
        # 1. Escanear los alumnos desde tu nueva BD estandarizada
        respuesta_db = tabla.scan()
        alumnos = respuesta_db.get('Items', [])

        # Set para almacenar los IDs de los alumnos que ya tienen cuenta en el sistema
        ids_con_cuenta = set()
        
        # 2. Consultar Cognito en segundo plano
        if USER_POOL_ID and "xxxxxxxxx" not in USER_POOL_ID:
            try:
                respuesta_cognito = cognito_client.list_users(UserPoolId=USER_POOL_ID)
                for user in respuesta_cognito.get('Users', []):
                    for attr in user.get('Attributes', []):
                        # Mapeamos contra el atributo personalizado que guarda el AlumnoId
                        if attr['Name'] == 'custom:alumnoId':
                            ids_con_cuenta.add(str(attr['Value']))
            except Exception as cognito_err:
                print(f"Cognito omitido/timeout en entorno de desarrollo: {cognito_err}")

        # 3. Filtrar alumnos disponibles (Sin Cuenta)
        alumnos_disponibles = []
        for a in alumnos:
            id_alumno = str(a.get('id', ''))
            
            # Si el ID del alumno no está en Cognito, significa que está disponible para registrarse
            if id_alumno not in ids_con_cuenta:
                # Aplanamos ligeramente la respuesta para cumplir con la interfaz del Front de Angular
                alumnos_disponibles.append({
                    "id": a.get('id'),
                    "nombreCompleto": a.get('nombreCompleto'),
                    "numeroControl": a.get('numeroControl'),
                    "carreraNombre": a.get('carrera', {}).get('nombre', 'Sin carrera')
                })

        return {
            "statusCode": 200,
            "headers": { 
                "Content-Type": "application/json", 
                "Access-Control-Allow-Origin": "*",
                "Access-Control-Allow-Headers": "Content-Type,Authorization"
            },
            "body": json.dumps(alumnos_disponibles, cls=DecimalEncoder)
        }
        
    except Exception as e:
        print(f"Error crítico en Lambda: {e}")
        return {
            "statusCode": 500,
            "headers": { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
            "body": json.dumps({"message": "Error al listar alumnos", "error": str(e)})
        }