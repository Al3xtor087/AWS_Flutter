import json
import os
import boto3

# --- Lógica para determinar el entorno (Local vs. AWS) ---
IS_OFFLINE = os.environ.get('AWS_SAM_LOCAL')

if IS_OFFLINE:
    dynamodb = boto3.resource('dynamodb', endpoint_url="http://host.docker.internal:8000")
else:
    dynamodb = boto3.resource('dynamodb')
TABLA_ALUMNOS = os.environ['TABLA_ALUMNOS']
tabla = dynamodb.Table(TABLA_ALUMNOS)

def eliminarAlumno(event, context):
    try:
        path_parameters = event.get('pathParameters') or {}
        id_alumno = path_parameters.get('id')

        if not id_alumno:
            return {
                "statusCode": 400,
                "headers": { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
                "body": json.dumps({"message": "La matrícula en la URL es obligatoria"})
            }

        # Eliminar el elemento por su Clave Primaria
        tabla.delete_item(Key={'id': id_alumno})

        return {
            "statusCode": 200,
            "headers": { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
            "body": json.dumps({"message": f"Alumno con matrícula {id_alumno} eliminado con éxito."})
        }
    except Exception as e:
        print(e)
        return {
            "statusCode": 500,
            "headers": { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
            "body": json.dumps({"message": "Error al eliminar el alumno", "error": str(e)})
        }