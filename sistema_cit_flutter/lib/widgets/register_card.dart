import 'package:flutter/material.dart';
import '../models/alumno_disponible.dart';

class RegisterCard extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController repeatPasswordController;
  final List<AlumnoDisponible> alumnosDisponibles;
  final String? selectedAlumnoId;
  final ValueChanged<String?> onAlumnoChanged;
  final bool isLoading;
  final Future<void> Function() onSubmit;
  final String? Function(String?) passwordValidator;

  const RegisterCard({
    super.key,
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.repeatPasswordController,
    required this.alumnosDisponibles,
    required this.selectedAlumnoId,
    required this.onAlumnoChanged,
    required this.isLoading,
    required this.onSubmit,
    required this.passwordValidator,
  });

  @override
  State<RegisterCard> createState() => _RegisterCardState();
}

class _RegisterCardState extends State<RegisterCard> {
  bool _isPasswordVisible = false;
  bool _isRepeatPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    const azulMarino = Color(0xFF1B2F55);
    const azulBoton = Color(0xFF5084D1);
    const grisBorde = Color(0xFFCBD5E1);

    return Form(
      key: widget.formKey,
      child: Card(
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Encabezado de la tarjeta con botón para regresar integrado
            Container(
              color: azulMarino,
              padding: const EdgeInsets.symmetric(
                vertical: 12,
                horizontal: 12,
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 22,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Crear cuenta',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),

            // Cuerpo del formulario de Registro
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 28.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Icono decorativo idéntico a web
                  Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: azulMarino.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person_add_alt_1_rounded,
                        size: 40,
                        color: azulMarino,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Crear cuenta',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: azulMarino,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Regístrate para acceder al sistema',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Selector de Alumno (Dropdown)
                  const Text(
                    'Nombre completo',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: azulMarino,
                    ),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: widget.selectedAlumnoId,
                    hint: const Text(
                      'Selecciona tu nombre',
                      style: TextStyle(fontSize: 14),
                    ),
                    isExpanded: true,
                    items: widget.alumnosDisponibles.map((alumno) {
                      return DropdownMenuItem(
                        value: alumno.id,
                        child: Text(
                          alumno.nombreCompleto,
                          style: const TextStyle(fontSize: 14),
                        ),
                      );
                    }).toList(),
                    onChanged: widget.onAlumnoChanged,
                    validator: (value) => value == null ? 'Debes seleccionar un alumno.' : null,
                    decoration: _buildInputDecoration(
                      prefixIcon: Icons.search,
                      azulBoton: azulBoton,
                      grisBorde: grisBorde,
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Campo de Correo Electrónico
                  const Text(
                    'Correo',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: azulMarino,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: widget.emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: _buildInputDecoration(
                      hintText: 'nombre@chetumal.tecnm.mx',
                      prefixIcon: Icons.email_outlined,
                      azulBoton: azulBoton,
                      grisBorde: grisBorde,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Por favor, ingresa un correo.';
                      }
                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                        return 'Ingresa un formato de correo válido.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 18),

                  // Campo de Contraseña
                  const Text(
                    'Contraseña',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: widget.passwordController,
                    obscureText: !_isPasswordVisible,
                    decoration: _buildInputDecoration(
                      hintText: 'Ej. MiClave1!',
                      prefixIcon: Icons.shield_outlined,
                      azulBoton: azulBoton,
                      grisBorde: grisBorde,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: Colors.grey,
                          size: 20,
                        ),
                        onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                      ),
                    ),
                    validator: widget.passwordValidator,
                  ),
                  const SizedBox(height: 18),

                  // Campo de Confirmar contraseña
                  const Text(
                    'Confirmar contraseña',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: azulMarino,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: widget.repeatPasswordController,
                    obscureText: !_isRepeatPasswordVisible,
                    decoration: _buildInputDecoration(
                      hintText: 'Repite tu contraseña',
                      prefixIcon: Icons.lock_reset_outlined,
                      azulBoton: azulBoton,
                      grisBorde: grisBorde,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isRepeatPasswordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: Colors.grey,
                          size: 20,
                        ),
                        onPressed: () => setState(() => _isRepeatPasswordVisible = !_isRepeatPasswordVisible),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, repite la contraseña.';
                      }
                      if (value != widget.passwordController.text) {
                        return 'Las contraseñas no coinciden.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),

                  // Botón de Registrar / Spinner
                  widget.isLoading
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(azulBoton),
                            ),
                          ),
                        )
                      : ElevatedButton(
                          onPressed: widget.onSubmit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: azulBoton,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.how_to_reg_outlined, size: 18),
                              SizedBox(width: 8),
                              Text(
                                'Crear cuenta',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                  const SizedBox(height: 18),

                  // Enlace inferior para regresar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        '¿Ya tienes cuenta? ',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                      GestureDetector(
                        onTap: widget.isLoading ? null : () => Navigator.of(context).pop(),
                        child: const Text(
                          'Inicia sesión aquí',
                          style: TextStyle(
                            color: azulBoton,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    String? hintText,
    required IconData prefixIcon,
    Widget? suffixIcon,
    required Color azulBoton,
    required Color grisBorde,
  }) {
    return InputDecoration(
      hintText: hintText,
      prefixIcon: Icon(prefixIcon, color: Colors.grey, size: 20),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: grisBorde),
        borderRadius: const BorderRadius.all(Radius.circular(8)),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: azulBoton, width: 1.5),
        borderRadius: const BorderRadius.all(Radius.circular(8)),
      ),
      errorBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.redAccent),
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
      focusedErrorBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.red, width: 1.5),
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
    );
  }
}