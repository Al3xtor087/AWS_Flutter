import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:jwt_decode/jwt_decode.dart';
import '../environments/environment.dart';

class AuthService {
  // Construimos la URL del endpoint de login usando la variable de entorno.
  static const String _authUrl = '${Environment.baseUrl}auth/login';
  static const String _profileUrl = '${Environment.baseUrl}auth/perfil'; // Endpoint para obtener el perfil
  static const String _registerUrl = '${Environment.baseUrl}auth/registrar';

  /// Token de autorización en memoria durante la sesión.
  static String? currentToken;

  /// Cabeceras comunes para llamadas autenticadas.
  static Map<String, String> authHeaders({Map<String, String>? extra}) {
    final headers = <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
      if (extra != null) ...extra,
    };

    if (currentToken != null) {
      headers['Authorization'] = 'Bearer $currentToken';
    }

    return headers;
  }

  /// Borra el token guardado al cerrar sesión.
  static void clearToken() {
    currentToken = null;
  }

  /// Obtiene el email del usuario logueado desde el token.
  static String? getCurrentUserEmail() {
    if (currentToken == null) return null;
    try {
      final payload = Jwt.parseJwt(currentToken!);
      // La 'claim' estándar de Cognito para el email es 'email'
      return payload['email'];
    } catch (e) {
      return null;
    }
  }

  /// Envía las credenciales al backend para autenticar al usuario.
  ///
  /// Devuelve un `Map` con el resultado:
  /// - En caso de éxito: `{'success': true, 'token': '...'}`
  /// - En caso de error: `{'success': false, 'message': '...'}`
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse(_authUrl),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Login exitoso. Asumimos que el backend devuelve un token.
        final token = responseData['token'];
        AuthService.currentToken = token;

        // Después del login, obtenemos el perfil completo del usuario desde el backend.
        final profile = await getProfile();

        return {
          'success': true,
          'token': token,
          'profile': profile, // Devolvemos el perfil junto con el token.
        };
      } else {
        // Error de credenciales o del servidor.
        return {'success': false, 'message': responseData['mensaje'] ?? 'Credenciales incorrectas.'};
      }
    } catch (e) {
      // Error de red o de conexión.
      return {'success': false, 'message': 'No se pudo conectar al servidor. Revisa tu conexión.'};
    }
  }

  /// Obtiene el perfil completo de un usuario desde el backend.
  Future<Map<String, dynamic>?> getProfile() async {
    try {
      final response = await http.get(
        Uri.parse(_profileUrl),
        headers: authHeaders(),
      );
      if (response.statusCode == 200) {
        // El endpoint /auth/perfil ahora devuelve directamente el objeto del usuario.
        return jsonDecode(utf8.decode(response.bodyBytes));
      }
    } catch (e) {
      // Si falla, no es crítico. La app puede continuar solo con el token.
      return null;
    }
    return null;
  }

  /// Envía los datos de registro al backend.
  ///
  /// Devuelve un `Map` con el resultado:
  /// - En caso de éxito: `{'success': true}`
  /// - En caso de error: `{'success': false, 'message': '...'}`
  Future<Map<String, dynamic>> register(String email, String password, String alumnoId) async {
    try {
      final response = await http.post(
        Uri.parse(_registerUrl),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'alumnoId': alumnoId,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        // Registro exitoso.
        return {'success': true};
      } else {
        final responseData = jsonDecode(response.body);
        return {'success': false, 'message': responseData['mensaje'] ?? 'Error en el registro.'};
      }
    } catch (e) {
      return {'success': false, 'message': 'No se pudo conectar al servidor. Revisa tu conexión.'};
    }
  }
}