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

tabla = dynamodb.Table(os.environ.get('TABLA_INCIDENCIAS', 'IncidenciasBD'))

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
            "Access-Control-Allow-Methods": "GET,POST,PUT,DELETE,OPTIONS",
            "Access-Control-Allow-Headers": "Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token"
        },
        "body": json.dumps(body, cls=DecimalEncoder)
    }
    
def _valor_en_rutas(objeto, rutas):
    # Busca un valor en varias rutas posibles de un diccionario.
    for ruta in rutas:
        actual = objeto
        for parte in ruta:
            if not isinstance(actual, dict):
                actual = None
                break
            if isinstance(parte, (list, tuple)):
                if len(parte) == 1:
                    parte = parte[0]
                else:
                    actual = None
                    break
            actual = actual.get(parte)
        if actual is not None and actual != '':
            return actual
    return None


def keys_to_camel_case(d):
    # Convierte las llaves a camelCase y aplana el objeto anidado de DynamoDB
    # para que se adapte perfectamente a la IncidenciaInterface de Angular.
    if isinstance(d, list):
        # Aplicamos la transformación a cada item de la lista
        return [keys_to_camel_case(item) for item in d] # Recursivo para listas
    
    if isinstance(d, dict):
        # 1. Convertimos todas las llaves a camelCase de forma recursiva
        objeto_final = {}
        for key, value in d.items():
            camel_key = key[0].lower() + key[1:] if isinstance(key, str) and key else key
            objeto_final[camel_key] = keys_to_camel_case(value) # Recursivo para diccionarios/listas anidadas
        
        # 2. APLANADO: Creamos los campos de acceso rápido que el frontend necesita
        if 'alumno' in objeto_final and isinstance(objeto_final['alumno'], dict):
            alumno = objeto_final['alumno']
            objeto_final['alumnoNombre'] = alumno.get('nombreCompleto', '')
            objeto_final['numeroControl'] = alumno.get('numeroControl', '')
            objeto_final['carreraNombre'] = alumno.get('carrera', {}).get('nombre', 'No asignada')
            objeto_final['alumnoId'] = alumno.get('id')
            objeto_final['carreraId'] = _valor_en_rutas(alumno, [('carreraId',), ('carrera', 'id')])

        # El frontend espera 'tipoIncidencia' como un string, no como un objeto.
        if 'tipoIncidencia' in objeto_final and isinstance(objeto_final['tipoIncidencia'], dict):
            incidencia_obj = objeto_final['tipoIncidencia']
            objeto_final['tipoIncidenciaId'] = incidencia_obj.get('id')
            objeto_final['tipoIncidencia'] = incidencia_obj.get('nombre', 'Desconocida') # Sobreescribe el objeto con el string

        proyecto = objeto_final.get('proyecto', {}) if isinstance(objeto_final.get('proyecto'), dict) else {}
        objeto_final['proyectoNombre'] = proyecto.get('nombre', 'No asignado')
        objeto_final['docenteResponsable'] = proyecto.get('docente', {}).get('nombre', 'No especificado')
        objeto_final['proyectoId'] = _valor_en_rutas(objeto_final, [('proyectoId',), ('proyecto', 'id')])

        # Si el backend trae el tipo de participación como objeto anidado, lo exponemos como string.
        if 'tipoParticipacion' in objeto_final and isinstance(objeto_final['tipoParticipacion'], dict):
            participacion_obj = objeto_final['tipoParticipacion']
            objeto_final['tipoParticipacion'] = participacion_obj.get('nombre', 'No especificado')
            objeto_final['tipoParticipacionId'] = participacion_obj.get('id')

        # Si el backend trae el tipo de participación en otro lugar, lo exponemos también como string.
        if 'tipoParticipacion' not in objeto_final or not objeto_final.get('tipoParticipacion'):
            tipo_participacion = objeto_final.get('participacion', {}).get('tipoParticipacion', {}) if isinstance(objeto_final.get('participacion'), dict) else {}
            if isinstance(tipo_participacion, dict):
                objeto_final['tipoParticipacion'] = tipo_participacion.get('nombre', 'No especificado')
                objeto_final['tipoParticipacionId'] = tipo_participacion.get('id')

        if 'tipoParticipacionId' not in objeto_final:
            objeto_final['tipoParticipacionId'] = _valor_en_rutas(objeto_final, [('tipoParticipacionId',), ('participacion', 'tipoParticipacionId')])

        if 'horaChecada' in objeto_final and 'hora' not in objeto_final:
            objeto_final['hora'] = objeto_final['horaChecada']

        if 'horaChecada' in objeto_final and 'horaAsistencia' not in objeto_final:
            objeto_final['horaAsistencia'] = objeto_final['horaChecada']

        if 'hora' in objeto_final and 'horaAsistencia' not in objeto_final:
            objeto_final['horaAsistencia'] = objeto_final['hora']

        return objeto_final

    return d

def aplicar_filtros(resultados, query_params):
    #Aplica filtros de fecha y demás criterios a la lista de incidencias.
    try:
        fecha = query_params.get('fecha')
        if fecha:
            resultados = [r for r in resultados if str(r.get('fecha', '')) == str(fecha)]

        buscar = query_params.get('buscar')
        if buscar:
            termino = str(buscar).lower()
            resultados = [
                r for r in resultados
                if termino in str(r.get('alumno', {}).get('nombreCompleto', '')).lower() or
                   termino in str(r.get('alumno', {}).get('numeroControl', '')).lower() or
                   termino in str(r.get('alumnoNombre', '')).lower() or
                   termino in str(r.get('numeroControl', '')).lower()
            ]

        carrera_id = query_params.get('carreraId')
        if carrera_id not in (None, ''):
            c_id = str(carrera_id)
            resultados = [
                r for r in resultados
                if str(_valor_en_rutas(r, [('carreraId',), ('alumno', 'carreraId'), ('alumno', 'carrera', 'id')])) == c_id
            ]

        proyecto_id = query_params.get('proyectoId')
        if proyecto_id not in (None, ''):
            p_id = str(proyecto_id)
            resultados = [
                r for r in resultados
                if str(_valor_en_rutas(r, [('proyectoId',), ('proyecto', 'id'), ('participacion', 'proyectoId')])) == p_id
            ]

        tipo_participacion_id = query_params.get('tipoParticipacionId')
        if tipo_participacion_id not in (None, ''):
            tp_id = str(tipo_participacion_id)
            resultados = [
                r for r in resultados
                if str(_valor_en_rutas(r, [('tipoParticipacionId',), ('tipoParticipacion', 'id'), ('participacion', 'tipoParticipacionId')])) == tp_id
            ]

        return resultados
    except Exception as e:
        print(f"[WARN] Error aplicando filtros: {e}")
        return resultados


def lambda_handler(event, context):
    try:
        # --- Manejo de Peticiones OPTIONS ---
        if event.get('httpMethod') == 'OPTIONS':
            return _crear_respuesta(200, {"mensaje": "Pre-vuelo CORS exitoso"})

        path_parameters = event.get('pathParameters') or {}
        path = event.get('path', '')
        
        query_params = event.get('queryStringParameters') or {}
        
        # Lista temporal para guardar los resultados filtrados
        resultados = []

        if '/incidencias/fecha/' in path:
            fecha_buscar = path_parameters.get('fecha')
            respuesta = tabla.query(
                IndexName='FechaIndex',
                KeyConditionExpression="fecha = :f",
                ExpressionAttributeValues={":f": fecha_buscar}
            )
            asistencias = respuesta.get('Items', [])
            resultados = [item for item in asistencias if item.get('estadoIncidencia') != 'ANULADA']

        # ESCENARIO 2: Angular llama al Buscador Avanzado /incidencias/listado? ...
        elif '/incidencias/listado' in path:
            respuesta = tabla.scan()
            items = respuesta.get('Items', [])
            resultados = [i for i in items if i.get('estadoIncidencia') != 'ANULADA']

            # Filtrado en memoria (sobre los datos originales con su case mixto)
            resultados = aplicar_filtros(resultados, query_params)

        resultados_camel = keys_to_camel_case(resultados)

        # Devolvemos la respuesta usando la función estandarizada
        return _crear_respuesta(200, resultados_camel)

    except Exception as e:
        print(f"❌ Error en la Lambda listar_asistencias: {e}")
        # Si algo falla, devolvemos el mensaje de error textualmente de forma segura
        return _crear_respuesta(500, {"error": str(e)})