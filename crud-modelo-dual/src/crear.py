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

TABLA_ALUMNOS = os.environ.get('TABLA_ALUMNOS', 'AlumnosBD')
TABLA_CARRERAS = os.environ.get('TABLA_CARRERAS', 'CarrerasBD')
TABLA_PROYECTOS = os.environ.get('TABLA_PROYECTOS', 'ProyectosBD')
TABLA_DOCENTES = os.environ.get('TABLA_DOCENTES', 'DocentesBD')
TABLA_PARTICIPACIONES = os.environ.get('TABLA_PARTICIPACIONES', 'ParticipacionesBD')

# --- Tablas de DynamoDB ---
tabla_alumnos = dynamodb.Table(TABLA_ALUMNOS)
tabla_carreras = dynamodb.Table(TABLA_CARRERAS)
tabla_proyectos = dynamodb.Table(TABLA_PROYECTOS)
tabla_docentes = dynamodb.Table(TABLA_DOCENTES)
tabla_participaciones = dynamodb.Table(TABLA_PARTICIPACIONES)


def crearAlumno(event, context):
    try:
        if not event.get('body'):
            return {
                "statusCode": 400,
                "headers": { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
                "body": json.dumps({"message": "El cuerpo de la petición no puede estar vacío"})
            }
        
        body = json.loads(event['body'])
        
        if 'numeroControl' not in body:
            return {
                "statusCode": 400,
                "headers": { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
                "body": json.dumps({"message": "El numeroControl es obligatorio"})
            }

        # --- Lógica de Denormalización: Consultar catálogos y anidar datos ---
        carrera_id = body.get('carreraId')
        proyecto_id = body.get('proyectoId')
        tipo_participacion_id = body.get('tipoParticipacionId')

        carrera_data = {}
        if carrera_id:
            carrera_data = tabla_carreras.get_item(Key={'id': str(carrera_id)}).get('Item', {})

        proyecto_data = {}
        if proyecto_id:
            proyecto_data = tabla_proyectos.get_item(Key={'id': str(proyecto_id)}).get('Item', {})

        # Como tipoParticipacion es estático, lo buscamos en una lista en memoria
        tipos_participacion = [
            {"id": 1, "nombre": "Servicio Social"},
            {"id": 2, "nombre": "Residencia Profesional"},
            {"id": 3, "nombre": "Servicio Social (no oficial)"},
            {"id": 4, "nombre": "Residencia Profesional (no oficial)"},
            {"id": 5, "nombre": "Proyecto de Investigación"}
        ]
        participacion_data = {}
        if tipo_participacion_id:
            # Usamos next() para encontrar el diccionario que coincida con el ID
            participacion_data = next((p for p in tipos_participacion if p['id'] == int(tipo_participacion_id)), {})


        # --- Construcción del objeto Alumno con datos anidados ---
        alumno_id = str(body.get('id') or uuid.uuid4())
        nuevo_alumno = {
            'id': alumno_id,
            'nombreCompleto': body.get('nombreCompleto', ''),
            'numeroControl': body['numeroControl'],
            'semestre': int(body.get('semestre', 1)),
            'horarios': body.get('horarios', []),
            'carreraId': carrera_id,
            'carrera': carrera_data
        }

        nueva_participacion = {
            'id': str(uuid.uuid4()), # ID único de la participación
            'alumnoId': alumno_id,   # FK al alumno
            'proyectoId': proyecto_id,
            'proyecto': proyecto_data,
            'tipoParticipacionId': tipo_participacion_id,
            'tipoParticipacion': participacion_data,
            'fechaInicio': body.get('fechaInicio'),
            'fechaTermino': body.get('fechaTermino')
        }

        # --- Guardado en Base de Datos ---
        tabla_alumnos.put_item(Item=nuevo_alumno)
        tabla_participaciones.put_item(Item=nueva_participacion)

        return {
            "statusCode": 201,
            "headers": { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
            "body": json.dumps({"alumno": nuevo_alumno, "participacion": nueva_participacion})
        }
    except Exception as e:
        print(f"Error en crearAlumno: {e}")
        return {
            "statusCode": 500,
            "headers": { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
            "body": json.dumps({"message": "Error al registrar el alumno", "error": str(e)})
        }