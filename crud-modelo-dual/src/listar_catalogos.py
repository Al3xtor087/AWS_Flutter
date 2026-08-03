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

# Mapeo de rutas a nombres de tablas de DynamoDB (inyectados por SAM)
TABLAS_CATALOGO = {
    "carreras": os.environ.get("TABLA_CARRERAS"),
    "proyectos": os.environ.get("TABLA_PROYECTOS"),
    "docentes": os.environ.get("TABLA_DOCENTES"),
    "tipo-participacion": None
}

class DecimalEncoder(json.JSONEncoder):
    def default(self, o):
        if isinstance(o, Decimal):
            return float(o) if o % 1 else int(o)
        return super(DecimalEncoder, self).default(o)

def _crear_respuesta(status_code, body):
    # Crea una respuesta HTTP estándar con cabeceras CORS.
    return {
        "statusCode": status_code,
        "headers": {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Methods": "GET,OPTIONS",
            "Access-Control-Allow-Headers": "Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token"
        },
        "body": json.dumps(body, cls=DecimalEncoder)
    }

def lambda_handler(event, context):
    if event.get('httpMethod') == 'OPTIONS':
        return _crear_respuesta(200, {"mensaje": "Pre-vuelo CORS exitoso"})

    path = event.get('path', '').strip('/')
    catalogo_solicitado = path.split('/')[-1]
    nombre_tabla = TABLAS_CATALOGO.get(catalogo_solicitado)

    if nombre_tabla:
        try:
            tabla = dynamodb.Table(nombre_tabla)
            respuesta_db = tabla.scan()
            return _crear_respuesta(200, respuesta_db.get('Items', []))
        except Exception as e:
            print(f"Error al leer el catálogo '{catalogo_solicitado}': {e}")
            return _crear_respuesta(500, {"mensaje": "Error al cargar el catálogo."})
    elif catalogo_solicitado == "tipo-participacion":
        datos = [
            {"id": 1, "nombre": "Servicio Social"},
            {"id": 2, "nombre": "Residencia Profesional"},
            {"id": 3, "nombre": "Servicio Social (no oficial)"},
            {"id": 4, "nombre": "Residencia Profesional (no oficial)"},
            {"id": 5, "nombre": "Proyecto de Investigación"}
        ]
        return _crear_respuesta(200, datos)
    
    return _crear_respuesta(404, {"mensaje": f"El catálogo '{catalogo_solicitado}' no existe."})