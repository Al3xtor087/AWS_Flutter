import 'package:flutter/material.dart';
import 'package:jwt_decode/jwt_decode.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';
import 'register_screen.dart';
import '../widgets/login_card.dart';

/// Pantalla de acceso principal de la app.
///
/// Responsabilidades:
/// - Capturar credenciales y validar el formulario.
/// - Invocar autenticación en [AuthService].
/// - Gestionar estados de carga y error de inicio de sesión.
/// - Navegar al [HomeScreen] cuando el login es exitoso.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  /// Llave para validar el formulario contenido en [LoginCard].
  final _formKey = GlobalKey<FormState>();

  /// Controladores de entrada para correo y contraseña.
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  /// Servicio responsable de comunicarse con el backend de autenticación.
  final _authService = AuthService();

  /// Estado visual de carga para bloquear acciones concurrentes.
  bool _isLoading = false;

  /// Mensaje de error mostrado en la UI cuando el login falla.
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Ejecuta el flujo completo de autenticación.
  ///
  /// Secuencia:
  /// 1. Valida el formulario.
  /// 2. Llama a [AuthService.login].
  /// 3. Si hay éxito, navega a [HomeScreen].
  /// 4. Si falla, actualiza [_errorMessage].
  Future<void> _login() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        final result = await _authService.login(
          _emailController.text.trim(),
          _passwordController.text,
        );

        if (!mounted) return;

        if (result['success'] == true) {
          final String token = result['token'];
          final Map<String, dynamic>? profile = result['profile'];
          _navigateOnLogin(
            token,
            profile,
          );
        } else {
          setState(() {
            _errorMessage = result['message'];
            _isLoading = false;
          });
        }
      } catch (e) {
        setState(() {
          _errorMessage = 'Ocurrió un error inesperado. Intente de nuevo.';
          _isLoading = false;
        });
      }
    }
  }

  /// Verifica el token JWT y reemplaza la pantalla actual por [HomeScreen].
  ///
  /// Si el token es inválido, se reporta el error en pantalla para que el
  /// usuario pueda reintentar el inicio de sesión.
  void _navigateOnLogin(String token, Map<String, dynamic>? userProfile) {
    try {
      Jwt.parseJwt(token);
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
            builder: (context) =>
                HomeScreen(token: token, userProfile: userProfile)),
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al procesar la sesión. Token inválido.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const grisFondo = Color(0xFFF8FAFC);

    return Scaffold(
      backgroundColor: grisFondo,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 450),
              child: LoginCard(
                formKey: _formKey,
                emailController: _emailController,
                passwordController: _passwordController,
                isLoading: _isLoading,
                errorMessage: _errorMessage,
                onLogin: _login,
                onGoToRegister: () {
                  if (!_isLoading) {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const RegisterScreen()),
                    );
                  }
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}