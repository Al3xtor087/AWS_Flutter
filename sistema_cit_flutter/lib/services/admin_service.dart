import 'dart:convert';
import 'package:http/http.dart' as http;
import '../environments/environment.dart';
import '../models/alumno_disponible.dart';
import '../models/usuario.dart';
import 'auth_service.dart';

class AdminService {
  static const String _alumnosSinCuentaUrl = '${Environment.baseUrl}alumnos';
  static const String _usuariosUrl = '${Environment.baseUrl}usuarios';
  static const String _adminUrl = '${Environment.baseUrl}admin';

  /// Obtiene la lista de alumnos que aún no tienen una cuenta creada.
  Future<List<AlumnoDisponible>> getAlumnosSinCuenta() async {
    try {
      // Este endpoint debe ser público para que cualquiera pueda registrarse.
      final response = await http.get(Uri.parse(_alumnosSinCuentaUrl));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        return data.map((json) => AlumnoDisponible.fromJson(json)).toList();
      } else {
        // Si el servidor responde con un error, lanzamos una excepción para que la UI la maneje.
        String errorMessage = 'Error del servidor al cargar alumnos.';
        try {
          final errorData = jsonDecode(response.body);
          errorMessage = errorData['mensaje'] ?? errorMessage;
        } catch (_) {
          // El cuerpo del error no es JSON, usamos el mensaje por defecto.
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      // Si hay un error de conexión o de parseo, lo relanzamos para que la UI lo muestre.
      throw Exception('No se pudo obtener la lista de alumnos. Revisa tu conexión a internet $e.');
    }
  }

  /// Obtiene la lista completa de usuarios del sistema.
  /// Similar a la lógica del panel de admin en el frontend.
  Future<List<Usuario>> getUsuarios() async {
    try {
      // Este endpoint podría requerir un token de autenticación.
      final response = await http.get(
        Uri.parse(_usuariosUrl),
        headers: AuthService.authHeaders(),
      );
  
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        return data.map((json) => Usuario.fromJson(json)).toList();
      } else {
        throw Exception('Error del servidor al cargar usuarios.');
      }
    } catch (e) {
      throw Exception('No se pudo obtener la lista de usuarios. Revisa tu conexión.');
    }
  }

  /// Cambia el rol de un usuario.
  Future<void> cambiarRol(String email, String nuevoRol) async {
    try {
      final response = await http.put(
        Uri.parse('$_adminUrl/cambiar-rol'),
        headers: AuthService.authHeaders(),
        body: jsonEncode({'email': email, 'nuevoRol': nuevoRol}),
      );
      if (response.statusCode != 200) {
        String errorMessage = 'Error al cambiar el rol.';
        try {
          final errorData = jsonDecode(response.body);
          errorMessage = errorData['mensaje'] ?? errorMessage;
        } catch (_) {
          // El cuerpo del error no es JSON, usamos el mensaje por defecto.
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      // Relanzamos la excepción para que la UI pueda manejarla.
      // Esto incluye errores de red o la excepción que lanzamos arriba.
      throw Exception('No se pudo cambiar el rol. $e');
    }
  }

  /// Vincula una cuenta de usuario a un registro de alumno.
  /// Devuelve el usuario actualizado en caso de éxito.
  Future<Usuario?> vincularAlumno(String email, String alumnoId) async {
    try {
      final response = await http.put(
        Uri.parse('$_adminUrl/vincular-alumno'),
        headers: AuthService.authHeaders(),
        body: jsonEncode({'email': email, 'alumnoId': alumnoId}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return Usuario.fromJson(data);
      } else {
        String errorMessage = 'Error al vincular la cuenta.';
        try {
          final errorData = jsonDecode(response.body);
          errorMessage = errorData['mensaje'] ?? errorMessage;
        } catch (_) {
          // El cuerpo del error no es JSON, usamos el mensaje por defecto.
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      // Relanzamos la excepción para que la UI pueda manejarla.
      throw Exception('No se pudo vincular la cuenta. $e');
    }
  }

  /// Elimina un usuario del sistema.
  Future<bool> eliminarUsuario(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$_adminUrl/usuario/$id'),
        headers: AuthService.authHeaders(),
      );
      if (response.statusCode != 200) {
        String errorMessage = 'Error al eliminar el usuario.';
        try {
          final errorData = jsonDecode(response.body);
          errorMessage = errorData['mensaje'] ?? errorMessage;
        } catch (_) {
          // El cuerpo del error no es JSON, usamos el mensaje por defecto.
        }
        throw Exception(errorMessage);
      }
      return true;
    } catch (e) {
      throw Exception('No se pudo eliminar el usuario. $e');
    }
  }
}