import 'dart:convert';
import 'package:http/http.dart'
    as http;
import '../models/incidencia.dart';
import '../environments/environment.dart';
import 'auth_service.dart';


class IncidenciaService {

  static const String baseUrl = '${Environment.baseUrl}incidencias/';

  /// Método asíncrono que consulta el listado filtrado de incidencias mediante Query Parameters.
  Future<List<Incidencia>> getFiltrado({String? buscar, String? fecha}) async {
    try {
      final Map<String, String> queryParameters = {};

      // Mapea el texto de búsqueda si el parámetro no se encuentra vacío.
      if (buscar != null && buscar.isNotEmpty) {
        queryParameters['buscar'] = buscar;
      }

      // Mapea la fecha para que el backend pueda procesarla desde la Query String.
      if (fecha != null && fecha.isNotEmpty) {
        queryParameters['fecha'] = fecha;
      }

      // Ensambla la URL completa adjuntando la subruta y los Query Parameters estructurados.
      final Uri urlCompleta = Uri.parse(
        '${baseUrl}listado',
      ).replace(queryParameters: queryParameters);

      // Lanza de forma asíncrona la petición HTTP GET hacia el servidor.
      final response = await http.get(
        urlCompleta,
        headers: AuthService.authHeaders(),
      );

      // Valida el código de estado del servidor para confirmar que la respuesta sea correcta (200 OK).
      if (response.statusCode == 200) {
        // Transforma la cadena de texto plana del cuerpo en una lista dinámica de mapas JSON.
        final List<dynamic> datosDecodificados = json.decode(response.body);

        // Mapea recursivamente la colección cruda transformándola en una lista fuertemente tipada de objetos Incidencia.
        return datosDecodificados
            .map((item) => Incidencia.fromJson(item))
            .toList();
      } else {
        return [];
      }
    } catch (e) {
      // Captura fallos críticos de red o desconexiones físicas del backend local.
      return [];
    }
  }

  /// Método asíncrono que despacha una petición HTTP PATCH para conmutar el estado a "Justificada".
  Future<bool> justificarIncidencia(String id) async {
    try {
      if (id.isEmpty || id == '0') {
        print('Error: Intento de justificar incidencia con ID inválido: $id');
        return false;
      }

      // Acopla el identificador numérico directamente como parámetro de ruta de la URL.
      final Uri url = Uri.parse('$baseUrl$id');

      // Lanza la solicitud parcial de modificación asíncrona hacia el controlador de C#.
      final response = await http.patch(
        url,
        headers: AuthService.authHeaders(),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  /// Método asíncrono que envía una instrucción HTTP DELETE para remover permanentemente el registro.
  Future<bool> eliminarIncidencia(String id) async {
    try {
      // ✅ VALIDACIÓN: No intentar la llamada si el ID es inválido o '0'.
      if (id.isEmpty || id == '0') {
        print('Error: Intento de eliminar incidencia con ID inválido: $id');
        return false;
      }

      // Estructura la URL inyectando el identificador de la incidencia a destruir.
      final Uri url = Uri.parse('$baseUrl$id');

      // Ejecuta la petición asíncrona de borrado físico en la base de datos de SQL Server.
      final response = await http.delete(
        url,
        headers: AuthService.authHeaders(),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  /// Método asíncrono que despacha un objeto JSON vía HTTP POST para registrar una nueva asistencia.
  Future<Map<String, dynamic>> registrarAsistencia(String alumnoId) async {
    try {
      // Muta el texto de la URL base para redirigir la petición hacia el controlador secundario de asistencias.
      final String urlAsistencias = baseUrl.replaceAll(
        'incidencias/',
        'asistencias',
      );
      final Uri url = Uri.parse(urlAsistencias);

      // Construye la estructura de mapa equivalente al DTO de creación esperado en el backend.
      final Map<String, dynamic> cuerpoJson = {'alumnoId': alumnoId};

      // Realiza la inserción enviando explícitamente las cabeceras y el cuerpo serializado en texto JSON.
      final response = await http.post(
        url,
        headers: AuthService.authHeaders(),
        body: json.encode(cuerpoJson),
      );

      // Decodifica la respuesta JSON de forma tolerante para soportar distintos backends.
      Map<String, dynamic> respuestaBackend = {};
      try {
        final dynamic decoded = json.decode(response.body);
        if (decoded is Map<String, dynamic>) {
          respuestaBackend = decoded;
        }
      } catch (_) {
        respuestaBackend = {};
      }

      final bool esHttpExitoso =
          response.statusCode >= 200 && response.statusCode < 300;
      final bool exitoBackend =
          respuestaBackend['exito'] == true || respuestaBackend['success'] == true;
      final bool exito = esHttpExitoso || exitoBackend;

      if (exito) {
        // Retorna un mapa indicando éxito junto con las propiedades anónimas calculadas por el controlador.
        return {
          'exito': true,
          'mensaje':
              respuestaBackend['mensaje'] ??
              respuestaBackend['message'] ??
              'Registro exitoso',
          'tipo': respuestaBackend['tipo'] ?? 'Entrada',
          'hora': respuestaBackend['hora'] ?? '--:--',
        };
      } else {
        // Maneja las respuestas controladas de error mapeando los mensajes nativos del backend.
        return {
          'exito': false,
          'mensaje':
              respuestaBackend['mensaje'] ??
              respuestaBackend['message'] ??
              response.body,
        };
      }
    } catch (e) {
      return {
        'exito': false,
        'mensaje': 'No se pudo establecer conexión con el servidor.',
      };
    }
  }

  /// Método asíncrono que consulta el endpoint híbrido por fecha para forzar el cálculo diario de incidencias.
  Future<bool> generarIncidenciasDelDia(String fecha) async {
    try {
      // Estructura la ruta de consulta anexando el string de la fecha (YYYY-MM-DD) como parámetro.
      final Uri url = Uri.parse('$baseUrl$fecha');

      // Invoca de manera asíncrona la ejecución del algoritmo de cruzado de horarios en el servidor.
      final response = await http.get(
        url,
        headers: AuthService.authHeaders(),
      );

      // Evalúa los estatus válidos de procesamiento exitoso controlados por el endpoint híbrido.
      if (response.statusCode == 200 || response.statusCode == 404) {
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Método GET para consultar una única incidencia específica por su ID primario
  Future<Incidencia?> obtenerDetalleIncidencia(String id) async {
    try {
      final Uri url = Uri.parse('${baseUrl}detalle/$id');

      final response = await http.get(
        url,
        headers: AuthService.authHeaders(),
      );

      if (response.statusCode == 200) {
        // Decodificamos el objeto JSON plano recibido
        final Map<String, dynamic> datosDecodificados = json.decode(
          response.body,
        );

        // Lo transformamos y retornamos como un objeto fuertemente tipado de Dart
        return Incidencia.fromJson(datosDecodificados);
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }
}
