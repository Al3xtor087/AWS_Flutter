import 'package:flutter/material.dart';

class LoginCard extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onLogin;
  final VoidCallback onGoToRegister;

  const LoginCard({
    super.key,
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.isLoading,
    this.errorMessage,
    required this.onLogin,
    required this.onGoToRegister,
  });

  @override
  State<LoginCard> createState() => _LoginCardState();
}

class _LoginCardState extends State<LoginCard> {
  bool _isPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    const azulMarino = Color(0xFF1B2F55);
    const azulBoton = Color(0xFF5084D1);
    const grisTextoBorde = Color(0xFFCBD5E1);

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
            // Encabezado
            Container(
              color: azulMarino,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              child: const Row(
                children: [
                  Icon(Icons.lock_outline, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Acceso al sistema',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),

            // Cuerpo
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Sistema de Control de Asistencia',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: azulMarino,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Bienvenido, por favor inicie sesión',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Email
                  const Text(
                    'Correo Institucional',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
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
                      grisTextoBorde: grisTextoBorde,
                    ),
                    validator: (value) => (value?.isEmpty ?? true) ? 'Ingrese su correo' : null,
                  ),
                  const SizedBox(height: 20),

                  // Password
                  const Text(
                    'Contraseña',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: widget.passwordController,
                    obscureText: !_isPasswordVisible,
                    decoration: _buildInputDecoration(
                      hintText: '••••••••',
                      prefixIcon: Icons.shield_outlined,
                      azulBoton: azulBoton,
                      grisTextoBorde: grisTextoBorde,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: Colors.grey,
                          size: 20,
                        ),
                        onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                      ),
                    ),
                    validator: (value) => (value?.isEmpty ?? true) ? 'Ingrese su contraseña' : null,
                  ),
                  const SizedBox(height: 24),

                  // Error
                  if (widget.errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, color: Colors.red.shade700, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                widget.errorMessage!,
                                style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Botón / Spinner
                  widget.isLoading
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 8.0),
                            child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(azulBoton)),
                          ),
                        )
                      : ElevatedButton(
                          onPressed: widget.onLogin,
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
                              Icon(Icons.login_rounded, size: 18),
                              SizedBox(width: 8),
                              Text('Iniciar sesión', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                  const SizedBox(height: 20),

                  // Link a registro
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        '¿No tienes cuenta? ',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                      GestureDetector(
                        onTap: widget.isLoading ? null : widget.onGoToRegister,
                        child: const Text(
                          'Regístrate aquí',
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
    required Color grisTextoBorde,
  }) {
    return InputDecoration(
      hintText: hintText,
      prefixIcon: Icon(prefixIcon, color: Colors.grey, size: 20),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: grisTextoBorde),
        borderRadius: const BorderRadius.all(Radius.circular(8)),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: azulBoton, width: 1.5),
        borderRadius: const BorderRadius.all(Radius.circular(8)),
      ),
      errorBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.redAccent),
        borderRadius: const BorderRadius.all(Radius.circular(8)),
      ),
      focusedErrorBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.red, width: 1.5),
        borderRadius: const BorderRadius.all(Radius.circular(8)),
      ),
    );
  }
}