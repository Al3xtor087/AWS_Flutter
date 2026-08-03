import 'package:flutter/material.dart';
import '../models/alumno_disponible.dart';
import '../services/admin_service.dart';
import '../services/auth_service.dart';
import '../widgets/register_card.dart';

/// Pantalla de registro de nuevos usuarios.
///
/// Permite a un alumno sin cuenta crear un nuevo perfil en el sistema,
/// asociando su registro escolar con un correo y contraseña.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}
/// Lógica y estado para la pantalla [RegisterScreen].
class _RegisterScreenState extends State<RegisterScreen> {
  // --- LLAVES Y SERVICIOS ---
  /// Llave global para identificar y validar el formulario de registro.
  final _formKey = GlobalKey<FormState>();
  /// Servicio para manejar las operaciones de autenticación (registro).
  final _authService = AuthService();
  /// Servicio para obtener datos administrativos (lista de alumnos sin cuenta).
  final _adminService = AdminService();

  // --- CONTROLADORES DE TEXTO ---
  /// Controlador para el campo de correo electrónico.
  final _emailController = TextEditingController();
  /// Controlador para el campo de contraseña.
  final _passwordController = TextEditingController();
  /// Controlador para el campo de repetir contraseña.
  final _repeatPasswordController = TextEditingController();

  // --- ESTADO DE LA UI ---
  /// Controla la visibilidad del indicador de carga durante operaciones asíncronas.
  bool _isLoading = false;
  /// Lista de alumnos que aún no tienen una cuenta, para mostrar en el dropdown.
  List<AlumnoDisponible> _alumnosDisponibles = [];
  /// ID del alumno seleccionado en el dropdown.
  String? _selectedAlumnoId;

  @override
  void initState() {
    super.initState();
    // Carga la lista de alumnos disponibles al iniciar la pantalla.
    _cargarAlumnos();
  }

  /// Carga la lista de alumnos sin cuenta desde el [AdminService].
  ///
  /// Muestra un indicador de carga mientras se realiza la petición y
  /// maneja los posibles errores de conexión, mostrando un [SnackBar].
  Future<void> _cargarAlumnos() async {
    setState(() => _isLoading = true);
    try {
      final alumnos = await _adminService.getAlumnosSinCuenta();
      if (!mounted) return;
      setState(() => _alumnosDisponibles = alumnos);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Valida que la contraseña cumpla con la política de seguridad.
  ///
  /// Requisitos:
  /// - Mínimo 6 caracteres.
  /// - Al menos una mayúscula, una minúscula, un número y un símbolo.
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor, ingresa una contraseña.';
    }
    if (value.length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres.';
    }
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Debe contener al menos una minúscula.';
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Debe contener al menos una mayúscula.';
    }
    if (!RegExp(r'\d').hasMatch(value)) {
      return 'Debe contener al menos un número.';
    }
    // Regex para símbolos comunes.
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>\-_]').hasMatch(value)) {
      return 'Debe contener al menos un símbolo.';
    }
    return null;
  }

  /// Procesa el envío del formulario de registro.
  ///
  /// Valida los campos y, si son correctos, llama al [AuthService] para
  /// crear la nueva cuenta. Muestra un mensaje de éxito o error y,
  /// si el registro es exitoso, regresa a la pantalla de login.
  Future<void> _submit() async {
    // Valida que todos los campos del formulario sean correctos.
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);

      final result = await _authService.register(
        _emailController.text.trim(),
        _passwordController.text,
        _selectedAlumnoId!,
      );

      if (!mounted) return;

        setState(() => _isLoading = false);
        if (result['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('¡Registro Exitoso! Ya puedes iniciar sesión.'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(); // Volver al login
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Error en el registro.'),
              backgroundColor: Colors.red,
            ),
          );
        }
    }
  }

  @override
  void dispose() {
    // Limpia los controladores para liberar memoria.
    _emailController.dispose();
    _passwordController.dispose();
    _repeatPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const grisFondo = Color(0xFFF8FAFC);

    return Scaffold(
      backgroundColor: grisFondo,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
            child: ConstrainedBox(
              // El widget RegisterCard contiene la UI del formulario.
              constraints: const BoxConstraints(maxWidth: 450),
              child: RegisterCard(
                formKey: _formKey,
                emailController: _emailController,
                passwordController: _passwordController,
                repeatPasswordController: _repeatPasswordController,
                alumnosDisponibles: _alumnosDisponibles,
                selectedAlumnoId: _selectedAlumnoId,
                onAlumnoChanged: (value) => setState(() => _selectedAlumnoId = value),
                isLoading: _isLoading,
                onSubmit: _submit,
                passwordValidator: _validatePassword,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
