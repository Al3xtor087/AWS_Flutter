import json
import os
import boto3
from decimal import Decimal

# Encoder para que los números de DynamoDB no rompan el JSON
class DecimalEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, Decimal):
            return float(obj) if obj % 1 != 0 else int(obj)
        return super(DecimalEncoder, self).default(obj)

# --- Lógica para determinar el entorno (Local vs. AWS) ---
IS_OFFLINE = os.environ.get('AWS_SAM_LOCAL')

if IS_OFFLINE:
    dynamodb = boto3.resource('dynamodb', endpoint_url="http://host.docker.internal:8000")
else:
    dynamodb = boto3.resource('dynamodb')
TABLA_ALUMNOS = os.environ['TABLA_ALUMNOS']
tabla = dynamodb.Table(TABLA_ALUMNOS)

def obtenerAlumno(event, context):
    try:
        # Extraer el id (NumeroControl) de la URL
        path_parameters = event.get('pathParameters') or {}
        id_alumno = path_parameters.get('id')

        if not id_alumno:
            return {
                "statusCode": 400,
                "headers": { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
                "body": json.dumps({"message": "La matrícula en la URL es obligatoria"})
            }

        # Buscar de manera directa por la Partition Key (id)
        respuesta = tabla.get_item(Key={'id': id_alumno})
        alumno = respuesta.get('Item')

        if not alumno:
            return {
                "statusCode": 404,
                "headers": { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
                "body": json.dumps({"message": f"El alumno con matrícula {id_alumno} no existe."})
            }

        return {
            "statusCode": 200,
            "headers": { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
            "body": json.dumps(alumno, cls=DecimalEncoder)
        }
    except Exception as e:
        print(e)
        return {
            "statusCode": 500,
            "headers": { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
            "body": json.dumps({"message": "Error al obtener el alumno", "error": str(e)})
        }