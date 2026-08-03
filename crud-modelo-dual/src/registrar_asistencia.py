import json
import os
import boto3
from datetime import datetime
from zoneinfo import ZoneInfo


from decimal import Decimal
class DecimalEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, Decimal):
            return float(obj) if obj % 1 != 0 else int(obj)
        return super(DecimalEncoder, self).default(obj)

# --- Lógica para determinar el entorno ---
IS_OFFLINE = os.environ.get('AWS_SAM_LOCAL')

if IS_OFFLINE:
    dynamodb = boto3.resource('dynamodb', endpoint_url="http://host.docker.internal:8000")
else:
    dynamodb = boto3.resource('dynamodb')

TABLA_ASISTENCIAS = os.environ['TABLA_ASISTENCIAS']
TABLA_ALUMNOS = os.environ['TABLA_ALUMNOS']
TABLA_PARTICIPACIONES = os.environ.get('TABLA_PARTICIPACIONES', 'ParticipacionesBD')
TIMEZONE = os.environ.get('TIMEZONE', 'America/Mexico_City')

tabla_asistencias = dynamodb.Table(TABLA_ASISTENCIAS)
tabla_alumnos = dynamodb.Table(TABLA_ALUMNOS)
tabla_participaciones = dynamodb.Table(TABLA_PARTICIPACIONES)

def lambda_handler(event, context):
    try:
        if not event.get('body'):
            return {
                "statusCode": 400,
                "headers": { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
                "body": json.dumps({"message": "El cuerpo de la petición no puede estar vacío"})
            }
        
        body = json.loads(event['body'])
        
        # Tolerancia: Aceptamos tanto 'alumnoId' (Angular) como 'AlumnoId' (C#)
        alumno_id_crudo = body.get('alumnoId') or body.get('AlumnoId')

        if not alumno_id_crudo:
            return {
                "statusCode": 400,
                "headers": { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
                "body": json.dumps({"message": "El campo alumnoId es obligatorio"})
            }

        alumno_id = str(alumno_id_crudo)

        respuesta_alumno = tabla_alumnos.get_item(Key={'id': alumno_id})
        alumno_db = respuesta_alumno.get('Item')

        if not alumno_db:
            return {
                "statusCode": 404,
                "headers": { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
                "body": json.dumps({"message": f"No se encontró un alumno registrado con el Id {alumno_id} en la base de datos."})
            }
        
        zona_horaria = ZoneInfo(TIMEZONE)
        ahora = datetime.now(zona_horaria)
        fecha_hoy = ahora.strftime('%Y-%m-%d')
        participacion_activa = None
        try:
            # Usamos el índice secundario 'AlumnoIdIndex' para buscar eficientemente
            respuesta_participaciones = tabla_participaciones.query(
                IndexName='AlumnoIdIndex',
                KeyConditionExpression="alumnoId = :aid",
                FilterExpression="fechaInicio <= :hoy AND fechaTermino >= :hoy",
                ExpressionAttributeValues={
                    ":aid": alumno_id,
                    ":hoy": fecha_hoy
                }
            )
            participaciones = respuesta_participaciones.get('Items', [])
            if participaciones:
                participacion_activa = participaciones[0] # Tomamos la primera activa que encontremos
        except Exception as e:
            # Si el índice no existe o hay un error, no es crítico, solo no se vinculará el proyecto.
            print(f"Advertencia: No se pudo buscar la participación para el alumno {alumno_id}. Error: {e}")
        
        # 4. Extraemos los datos del alumno
        numero_control = alumno_db.get('numeroControl', 'SIN_CONTROL')
        nombre_completo = alumno_db.get('nombreCompleto', 'Alumno Registrado')
        carrera_id = int(alumno_db.get('carreraId', 0))
        semestre = int(alumno_db.get('semestre', 1))

        # 2. Tiempos del servidor
        hora_actual = ahora.strftime('%H:%M:%S') 

        # 3. Lógica para determinar Entrada o Salida (Par o Impar) de hoy
        # Consultamos por fecha y luego filtramos por alumnoId real (minúsculas) para contar solo sus registros.
        respuesta_scan = tabla_asistencias.query(
            IndexName='FechaIndex',
            KeyConditionExpression='fecha = :f',
            FilterExpression='alumnoId = :aid',
            ExpressionAttributeValues={":aid": alumno_id, ":f": fecha_hoy}
        )
        asistencias_hoy = respuesta_scan.get('Items', [])
        tipo_movimiento = "Entrada" if (len(asistencias_hoy) % 2 == 0) else "Salida"

        # 4. Clave compuesta única para la Partition Key de DynamoDB
        registro_id = f"{numero_control}#{ahora.strftime('%Y%m%d%H%M%S')}"

        # 5 Construcción de una entidad limpia y consistente (camelCase)
        entidad_asistencia = {
            'id': registro_id,
            'fecha': fecha_hoy,
            'tipo': tipo_movimiento,
            'hora': hora_actual,
            'alumnoId': alumno_id,
            'mensaje': f"¡{tipo_movimiento} Exitosa!",
            'nota': f"Tu asistencia ha sido capturada y será procesada al final del día.",
            'alumno': {
                'id': alumno_id,
                'nombreCompleto': nombre_completo,
                'numeroControl': numero_control,
                'carreraId': carrera_id,
                'semestre': semestre
            },            
            'proyecto': participacion_activa.get('proyecto', {}) if participacion_activa else {},
            'docente': participacion_activa.get('proyecto', {}).get('docente', {}) if participacion_activa else {},

            'Incidencia': None 
        }
        
        # Guardar en DynamoDB la asistencia procesada
        tabla_asistencias.put_item(Item=entidad_asistencia)

        return {
            "statusCode": 201,
            "headers": { 
                "Content-Type": "application/json", 
                "Access-Control-Allow-Origin": "*",
                "Access-Control-Allow-Headers": "Content-Type,Authorization",
                "Access-Control-Allow-Methods": "POST,OPTIONS"
            },
            "body": json.dumps(entidad_asistencia, cls=DecimalEncoder)
        }

    except Exception as e:
        print(f"[ERROR] Ocurrió un fallo procesando la asistencia: {str(e)}")
        return {
            "statusCode": 500,
            "headers": { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
            "body": json.dumps({"message": "Error al procesar la asistencia", "error": str(e)})
        }