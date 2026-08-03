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

def lambda_handler(event, context):
    try:
        # 1. Escanear absolutamente toda la tabla en Docker
        respuesta_db = tabla.scan()
        alumnos = respuesta_db.get('Items', [])

        # 2. Formatear la lista completa tal como la espera tu interfaz de Angular
        lista_completa = []
        for a in alumnos:
            lista_completa.append({
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
            "body": json.dumps(lista_completa, cls=DecimalEncoder)
        }
        
    except Exception as e:
        print(f"[ERROR] Error al listar todos los alumnos: {e}")
        return {
            "statusCode": 500,
            "headers": { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
            "body": json.dumps({"message": "Error al obtener la lista global de alumnos", "error": str(e)})
        }