import json
import os
from decimal import Decimal
import boto3

# --- Lógica para determinar el entorno (Local vs. AWS) ---
IS_OFFLINE = os.environ.get('AWS_SAM_LOCAL')

if IS_OFFLINE:
    dynamodb = boto3.resource('dynamodb', endpoint_url="http://host.docker.internal:8000")
else:
    dynamodb = boto3.resource('dynamodb')

# --- Variables de Entorno y Tabla ---
TABLA_INCIDENCIAS = os.environ.get('TABLA_INCIDENCIAS', 'IncidenciasBD')
tabla = dynamodb.Table(TABLA_INCIDENCIAS)

# --- Función Auxiliar para crear respuestas HTTP (consistente con otras lambdas) ---
def _serializar_dynamodb(value):
    # Convierte valores de DynamoDB a tipos JSON serializables.
    if isinstance(value, Decimal):
        if value % 1 == 0:
            return int(value)
        return float(value)
    if isinstance(value, dict):
        return {k: _serializar_dynamodb(v) for k, v in value.items()}
    if isinstance(value, list):
        return [_serializar_dynamodb(v) for v in value]
    return value


def _crear_respuesta(status_code, body):
    # Crea una respuesta HTTP estándar con cabeceras CORS.
    cuerpo_serializado = _serializar_dynamodb(body)
    return {
        "statusCode": status_code,
        "headers": {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Methods": "GET,POST,PUT,PATCH,DELETE,OPTIONS",
            "Access-Control-Allow-Headers": "Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token"
        },
        "body": json.dumps(cuerpo_serializado)
    }


def _payload_justificacion():
    # Devuelve el payload que debe persistirse para una incidencia justificada.
    return {
        'estadoIncidencia': 'JUSTIFICADA',
        'nota': 'La falta ha sido justificada por un administrador.',
        'tipoIncidencia': {'id': 5, 'nombre': 'Justificado'}
    }

def lambda_handler(event, context):
    # --- Manejo de Peticiones OPTIONS (Pre-vuelo de CORS) ---
    if event.get('httpMethod') == 'OPTIONS':
        return _crear_respuesta(200, {"mensaje": "Pre-vuelo CORS exitoso"})

    try:
        http_method = event.get('httpMethod', 'GET')
        path_parameters = event.get('pathParameters') or {}
        incidencia_id = path_parameters.get('id')

        if not incidencia_id:
            return _crear_respuesta(400, {"mensaje": "El ID de la incidencia es obligatorio"})

        # --- ACCIÓN 1: ELIMINAR INCIDENCIA (DELETE /incidencias/{id}) ---
        if http_method == 'DELETE':
            respuesta_delete = tabla.delete_item(
                Key={'id': incidencia_id},
                ReturnValues='ALL_OLD'
            )
            return _crear_respuesta(200, {
                "mensaje": f"Incidencia {incidencia_id} eliminada con éxito.",
                "incidencia": respuesta_delete.get('Attributes', {})
            })

        # --- ACCIÓN 2: JUSTIFICAR INCIDENCIA (PATCH /incidencias/{id}) ---
        elif http_method in ['PUT', 'PATCH']:
            try:
                item_actual = tabla.get_item(Key={'id': incidencia_id}).get('Item', {})

                if not item_actual:
                    return _crear_respuesta(404, {
                        "mensaje": f"No existe la incidencia {incidencia_id}.",
                        "error": "Item no encontrado"
                    })

                payload_justificacion = _payload_justificacion()
                tipo_actual = item_actual.get('tipoIncidencia', {})
                ya_justificada = (
                    item_actual.get('estadoIncidencia') == 'JUSTIFICADA' and
                    tipo_actual.get('id') == 5 and
                    tipo_actual.get('nombre') == 'Justificado'
                )

                if ya_justificada:
                    return _crear_respuesta(200, {
                        "mensaje": f"La incidencia {incidencia_id} ya estaba justificada.",
                        "incidencia": item_actual
                    })

                respuesta_update = tabla.update_item(
                    Key={'id': incidencia_id},
                    UpdateExpression="SET #estado = :estado, nota = :nota, tipoIncidencia = :tipoIncidencia",
                    ExpressionAttributeNames={'#estado': 'estadoIncidencia'},
                    ExpressionAttributeValues={
                        ':estado': payload_justificacion['estadoIncidencia'],
                        ':nota': payload_justificacion['nota'],
                        ':tipoIncidencia': payload_justificacion['tipoIncidencia']
                    },
                    ReturnValues='ALL_NEW'
                )
                return _crear_respuesta(200, {
                    "mensaje": f"Incidencia {incidencia_id} justificada con éxito.",
                    "incidencia": respuesta_update.get('Attributes', {})
                })
            except Exception as update_error:
                return _crear_respuesta(500, {
                    "mensaje": f"No fue posible justificar la incidencia {incidencia_id}.",
                    "error": str(update_error)
                })

        # Si no es DELETE, PUT u OPTIONS, es una acción no soportada
        return _crear_respuesta(405, {"mensaje": f"Método {http_method} no permitido en esta ruta."})

    except Exception as e:
        print(f"Error en incidencia_individual: {e}")
        return _crear_respuesta(500, {"mensaje": "Error procesando la incidencia", "error": str(e)})