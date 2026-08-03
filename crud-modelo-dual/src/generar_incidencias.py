import json
import os
import boto3
import uuid
from datetime import datetime, time, timedelta
from zoneinfo import ZoneInfo

# --- Lógica para determinar el entorno (Local vs. AWS) ---
IS_OFFLINE = os.environ.get('AWS_SAM_LOCAL')

if IS_OFFLINE:
    dynamodb = boto3.resource('dynamodb', endpoint_url="http://host.docker.internal:8000")
else:
    dynamodb = boto3.resource('dynamodb')

TABLA_ASISTENCIAS = os.environ['TABLA_ASISTENCIAS']
TABLA_ALUMNOS = os.environ['TABLA_ALUMNOS']
TABLA_INCIDENCIAS = os.environ.get('TABLA_INCIDENCIAS', 'IncidenciasBD')
TABLA_PARTICIPACIONES = os.environ.get('TABLA_PARTICIPACIONES', 'ParticipacionesBD')
TIMEZONE = os.environ.get('TIMEZONE', 'America/Mexico_City')

tabla_asistencias = dynamodb.Table(TABLA_ASISTENCIAS)
tabla_alumnos = dynamodb.Table(TABLA_ALUMNOS)
tabla_participaciones = dynamodb.Table(TABLA_PARTICIPACIONES)
tabla_incidencias = dynamodb.Table(TABLA_INCIDENCIAS)

# Mapeo de días
DIAS_MAP = {
    0: "Lunes",
    1: "Martes",
    2: "Miércoles",
    3: "Jueves",
    4: "Viernes",
    5: "Sábado",
    6: "Domingo"
}

def _crear_objeto_incidencia(
    fecha,
    alumno_db,
    participacion_activa,
    tipo_id,
    descripcion,
    asistencia_original=None,
    hora_entrada_esperada=None,
    hora_salida_esperada=None,
):
    # Función auxiliar para construir un objeto de incidencia consistente.
    nombres_enum = {1: "Retardo", 2: "Falta", 3: "Salida Anticipada", 4: "Fuera de Horario"}
    
    # Limpiamos los datos del alumno para evitar guardar strings vacíos en DynamoDB
    alumno_limpio = {
        'id': alumno_db.get('id'),
        'nombreCompleto': alumno_db.get('nombreCompleto'),
        'numeroControl': alumno_db.get('numeroControl'),
        'carrera': alumno_db.get('carrera', {})
    }
    alumno_limpio = {k: v for k, v in alumno_limpio.items() if v is not None and v != ''}

    incidencia = {
        'id': f"INC-{uuid.uuid4()}",
        'fecha': fecha,
        'alumnoId': alumno_db.get('id'),
        'alumno': alumno_limpio,
        'proyecto': participacion_activa.get('proyecto', {}) if participacion_activa else {},
        'tipoIncidencia': {
            'id': tipo_id,
            'nombre': nombres_enum.get(tipo_id, 'Desconocida')
        },
        'descripcion': descripcion,
        'estadoIncidencia': 'PENDIENTE', # Estado por defecto para nuevas incidencias
        'nota': ''
    }
    if asistencia_original:
        incidencia['asistenciaOriginalId'] = asistencia_original.get('id')
        incidencia['horaChecada'] = asistencia_original.get('hora')

    if hora_entrada_esperada:
        incidencia['horaEntradaEsperada'] = hora_entrada_esperada

    if hora_salida_esperada:
        incidencia['horaSalidaEsperada'] = hora_salida_esperada

    return incidencia

def lambda_handler(event, context):
    try:
        zona_horaria = ZoneInfo(TIMEZONE)
        ahora = datetime.now(zona_horaria)
        fecha_hoy = ahora.strftime('%Y-%m-%d')
        nombre_dia = DIAS_MAP.get(ahora.weekday(), "Lunes")

        # 1. PRE-FETCH: Cargar todos los datos necesarios en memoria para evitar consultas en bucle.
        respuesta_alumnos = tabla_alumnos.scan()
        alumnos_map = {a['id']: a for a in respuesta_alumnos.get('Items', [])}

        respuesta_participaciones = tabla_participaciones.scan()
        participaciones_map = {}
        for p in respuesta_participaciones.get('Items', []):
            aid = p.get('alumnoId')
            if aid:
                if aid not in participaciones_map:
                    participaciones_map[aid] = []
                participaciones_map[aid].append(p)

        respuesta_asistencias = tabla_asistencias.query(
            IndexName='FechaIndex',
            KeyConditionExpression="fecha = :f",
            ExpressionAttributeValues={":f": fecha_hoy}
        )
        asistencias_por_alumno = {}
        for asis in respuesta_asistencias.get('Items', []):
            aid = asis.get('alumnoId')
            if aid:
                if aid not in asistencias_por_alumno:
                    asistencias_por_alumno[aid] = []
                asistencias_por_alumno[aid].append(asis)

        # 2. LIMPIEZA: Eliminar incidencias autogeneradas del día para que el proceso sea idempotente.
        respuesta_incidencias_viejas = tabla_incidencias.query(
            IndexName='FechaIndex',
            KeyConditionExpression="fecha = :f",
            ExpressionAttributeValues={":f": fecha_hoy}
        )
        with tabla_incidencias.batch_writer() as batch:
            for inc in respuesta_incidencias_viejas.get('Items', []):
                if inc.get('estadoIncidencia') not in ['JUSTIFICADA', 'ANULADA']:
                    batch.delete_item(Key={'id': inc['id']})

        # 3. LÓGICA PRINCIPAL: Iterar sobre los ALUMNOS.
        incidencias_a_crear = []
        for alumno_id, alumno_db in alumnos_map.items():
            horario_programado = next((h for h in alumno_db.get('horarios', []) if h.get('diaSemana') == nombre_dia), None)
            asistencias_hoy = asistencias_por_alumno.get(alumno_id, [])
            asistencias_hoy.sort(key=lambda x: x['hora'])

            participacion_activa = None
            for p in participaciones_map.get(alumno_id, []):
                if p.get('fechaInicio') and p.get('fechaTermino') and p['fechaInicio'] <= fecha_hoy <= p['fechaTermino']:
                    participacion_activa = p
                    break

            # CASO 1: El alumno SÍ tiene horario asignado para hoy.
            if horario_programado:
                # 1a: No hay checadas = FALTA POR AUSENCIA
                if not asistencias_hoy:
                    desc = f"Ausencia. El alumno no registró asistencia el día {nombre_dia}."
                    incidencia = _crear_objeto_incidencia(
                        fecha_hoy,
                        alumno_db,
                        participacion_activa,
                        2,
                        desc,
                        hora_entrada_esperada=horario_programado.get('entrada1'),
                        hora_salida_esperada=horario_programado.get('salida1'),
                    )
                    incidencias_a_crear.append(incidencia)
                    continue
                
                # 1b: Hay checadas, se procesan para encontrar Retardos, Salidas Anticipadas, etc.
                for idx, asistencia in enumerate(asistencias_hoy):
                    hora_asistencia = datetime.strptime(asistencia['hora'], '%H:%M:%S').time()
                    es_entrada = (idx % 2 == 0)
                    
                    entrada_esperada_str = horario_programado.get('entrada1')
                    salida_esperada_str = horario_programado.get('salida1')
                    if hora_asistencia > time(12, 0) and horario_programado.get('entrada2'):
                        entrada_esperada_str = horario_programado.get('entrada2')
                        salida_esperada_str = horario_programado.get('salida2')

                    if not entrada_esperada_str or not salida_esperada_str: continue

                    entrada_esperada = datetime.strptime(entrada_esperada_str, '%H:%M:%S').time()
                    salida_esperada = datetime.strptime(salida_esperada_str, '%H:%M:%S').time()
                    dt_asistencia = datetime.combine(ahora.date(), hora_asistencia)
                    dt_entrada = datetime.combine(ahora.date(), entrada_esperada)
                    dt_salida = datetime.combine(ahora.date(), salida_esperada)
                    dif_entrada = abs((dt_asistencia - dt_entrada).total_seconds() / 60.0)
                    dif_salida = abs((dt_asistencia - dt_salida).total_seconds() / 60.0)

                    tipo_id, desc = None, ""
                    if dif_entrada > 120 and dif_salida > 120:
                        tipo_id, desc = 4, f"Checada a las {asistencia['hora']} fuera del rango de horario laboral."
                    elif es_entrada:
                        if dt_asistencia > (dt_entrada + timedelta(minutes=20)):
                            tipo_id, desc = 2, f"Falta por retraso mayor a 20 min. Llegó a las {asistencia['hora']}."
                        elif dt_asistencia > (dt_entrada + timedelta(minutes=10)):
                            tipo_id, desc = 1, f"Retardo. Llegó a las {asistencia['hora']} (esperado: {entrada_esperada_str})."
                    else: # Es Salida
                        if dt_asistencia < (dt_salida - timedelta(minutes=60)):
                            tipo_id, desc = 2, f"Abandono de turno. Salió a las {asistencia['hora']}."
                        elif dt_asistencia < (dt_salida - timedelta(minutes=5)):
                            tipo_id, desc = 3, f"Salida anticipada. Salió a las {asistencia['hora']} (esperado: {salida_esperada_str})."
                    
                    if tipo_id:
                        incidencia = _crear_objeto_incidencia(
                            fecha_hoy,
                            alumno_db,
                            participacion_activa,
                            tipo_id,
                            desc,
                            asistencia,
                            hora_entrada_esperada=entrada_esperada_str,
                            hora_salida_esperada=salida_esperada_str,
                        )
                        incidencias_a_crear.append(incidencia)

            # CASO 2: El alumno NO tiene horario, pero SÍ checó = FUERA DE HORARIO
            elif asistencias_hoy:
                for asistencia in asistencias_hoy:
                    desc = f"El alumno checó el día sin tener horario asignado."
                    incidencia = _crear_objeto_incidencia(fecha_hoy, alumno_db, participacion_activa, 4, desc, asistencia)
                    incidencias_a_crear.append(incidencia)

        # 4. GUARDADO: Escribir todas las incidencias generadas en la base de datos.
        if incidencias_a_crear:
            with tabla_incidencias.batch_writer() as batch:
                for inc in incidencias_a_crear:
                    batch.put_item(Item=inc)

        return {
            "statusCode": 200,
            "body": json.dumps({"message": f"Procesamiento de incidencias concluido para {fecha_hoy}. Incidencias generadas: {len(incidencias_a_crear)}."})
        }
        
    except Exception as e:
        print(f"[ERROR] Fallo en la generación de incidencias: {str(e)}")
        return {
            "statusCode": 500,
            "body": json.dumps({"error": str(e)})
        }