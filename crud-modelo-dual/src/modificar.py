import json
import os
import boto3

# --- Lógica para determinar el entorno (Local vs. AWS) ---
IS_OFFLINE = os.environ.get('AWS_SAM_LOCAL')

if IS_OFFLINE:
    dynamodb = boto3.resource('dynamodb', endpoint_url="http://host.docker.internal:8000")
else:
    dynamodb = boto3.resource('dynamodb')

# --- Tablas de DynamoDB ---
TABLA_ALUMNOS = os.environ.get('TABLA_ALUMNOS', 'AlumnosBD')
TABLA_CARRERAS = os.environ.get('TABLA_CARRERAS', 'CarrerasBD')
TABLA_PROYECTOS = os.environ.get('TABLA_PROYECTOS', 'ProyectosBD')
TABLA_DOCENTES = os.environ.get('TABLA_DOCENTES', 'DocentesBD')

tabla_alumnos = dynamodb.Table(TABLA_ALUMNOS)
tabla_carreras = dynamodb.Table(TABLA_CARRERAS)
tabla_proyectos = dynamodb.Table(TABLA_PROYECTOS)
tabla_docentes = dynamodb.Table(TABLA_DOCENTES)

TIPOS_PARTICIPACION = [
    {"id": 1, "nombre": "Servicio Social"},
    {"id": 2, "nombre": "Residencia Profesional"},
    {"id": 3, "nombre": "Servicio Social (no oficial)"},
    {"id": 4, "nombre": "Residencia Profesional (no oficial)"},
    {"id": 5, "nombre": "Proyecto de Investigación"}
]

def modificarAlumno(event, context):
    try:
        path_parameters = event.get('pathParameters') or {}
        id_alumno = path_parameters.get('id')
        
        if not id_alumno or not event.get('body'):
            return {
                "statusCode": 400,
                "headers": { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
                "body": json.dumps({"message": "Faltan datos obligatorios para la actualización"})
            }

        body = json.loads(event['body'])

        # --- Lógica de Denormalización para Actualización ---
        update_payload = {} # Aquí guardaremos los campos a actualizar.

        # Campos directos
        for campo in ['nombreCompleto', 'numeroControl', 'semestre', 'horarios']:
            if campo in body:
                update_payload[campo] = body[campo]

        # Campos que requieren consulta a catálogos
        if 'carreraId' in body:
            carrera_id = body['carreraId']
            carrera_data = tabla_carreras.get_item(Key={'id': str(carrera_id)}).get('Item', {})
            update_payload['carreraId'] = carrera_id
            update_payload['carrera'] = carrera_data

        if 'proyectoId' in body:
            proyecto_id = body['proyectoId']
            proyecto_data = tabla_proyectos.get_item(Key={'id': str(proyecto_id)}).get('Item', {})
            update_payload['proyectoId'] = proyecto_id
            update_payload['proyecto'] = proyecto_data

        if 'docenteId' in body:
            docente_id = body['docenteId']
            docente_data = tabla_docentes.get_item(Key={'id': str(docente_id)}).get('Item', {})
            update_payload['docenteId'] = docente_id
            update_payload['docente'] = docente_data

        if 'tipoParticipacionId' in body:
            tipo_id = int(body['tipoParticipacionId'])
            participacion_data = next((p for p in TIPOS_PARTICIPACION if p['id'] == tipo_id), {})
            update_payload['tipoParticipacionId'] = tipo_id
            update_payload['tipoParticipacion'] = participacion_data

        if not update_payload:
            return {
                "statusCode": 400,
                "headers": { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
                "body": json.dumps({"message": "No se proporcionaron campos válidos para actualizar"})
            }

        # --- Construcción dinámica de la expresión de actualización ---
        update_expression_parts = []
        expression_attribute_values = {}
        for key, value in update_payload.items():
            update_expression_parts.append(f"{key} = :{key}")
            expression_attribute_values[f":{key}"] = value

        update_expression = "SET " + ", ".join(update_expression_parts)

        # Ejecutar la actualización en DynamoDB
        respuesta = tabla_alumnos.update_item(
            Key={'id': id_alumno},
            UpdateExpression=update_expression,
            ExpressionAttributeValues=expression_attribute_values,
            ReturnValues="ALL_NEW"
        )

        return {
            "statusCode": 200,
            "headers": { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
            "body": json.dumps({
                "message": f"Alumno con ID {id_alumno} modificado con éxito.",
                "alumno": respuesta.get('Attributes')
            })
        }
    except Exception as e:
        print(e)
        return {
            "statusCode": 500,
            "headers": { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
            "body": json.dumps({"message": "Error al modificar el alumno", "error": str(e)})
        }