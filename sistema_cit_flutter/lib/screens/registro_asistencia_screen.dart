import 'package:flutter/material.dart';
import 'package:jwt_decode/jwt_decode.dart';
import '../services/auth_service.dart';
import '../services/incidencia_service.dart';
import '../widgets/asistencia_card.dart';
import '../widgets/feedback_card.dart';

/// Pantalla principal para que los alumnos registren su asistencia.
///
/// Muestra una interfaz sencilla con un botón principal para enviar el registro.
/// Tras la acción, presenta una tarjeta con el resultado (éxito o error)
/// de la operación.
class RegistroAsistenciaScreen extends StatefulWidget {
  final String alumnoId;
  final String? alumnoNombre;

  const RegistroAsistenciaScreen({
    super.key,
    required this.alumnoId,
    this.alumnoNombre,
  });

  @override
  State<RegistroAsistenciaScreen> createState() =>
      _RegistroAsistenciaScreenState();
}
/// Lógica y estado para la pantalla [RegistroAsistenciaScreen].
class _RegistroAsistenciaScreenState extends State<RegistroAsistenciaScreen> {
  // --- SERVICIOS ---
  final _incidenciaService = IncidenciaService();

  // --- ESTADO DE LA UI ---
  /// Nombre del alumno que se muestra en la pantalla.
  String _nombreAlumno = 'Cargando...';
  /// Controla la visibilidad del indicador de carga.
  bool _isLoading = false;
  /// Mensaje de retroalimentación (éxito o error) tras registrar.
  String? _feedbackMessage;
  /// Define el tipo de feedback para estilizar la tarjeta de resultado.
  String? _feedbackType; // 'exito', 'error'
  /// Información detallada del registro exitoso (tipo y hora).
  Map<String, String>? _registroInfo;

  @override
  void initState() {
    super.initState();
    // Inicializa el nombre del alumno. Primero intenta usar el que viene
    // del perfil, y si no, lo extrae como fallback desde el token JWT.
    if (widget.alumnoNombre != null && widget.alumnoNombre!.trim().isNotEmpty) {
      _nombreAlumno = widget.alumnoNombre!;
    } else {
      _nombreAlumno = _obtenerNombreDesdeToken() ?? 'Alumno';
    }
  }

  /// Obtiene el nombre completo del alumno desde el token JWT.
  ///
  /// Es un método de respaldo en caso de que el perfil del usuario no se
  /// haya cargado correctamente al iniciar sesión.
  String? _obtenerNombreDesdeToken() {
    final token = AuthService.currentToken;
    if (token == null || token.isEmpty) return null;

    try {
      final payload = Jwt.parseJwt(token);
      return payload['custom:nombreCompleto'] ?? payload['name'] ?? null;
    } catch (_) {
      return null;
    }
  }

  /// Ejecuta el proceso de registro de asistencia.
  ///
  /// Llama al [IncidenciaService] para enviar el ID del alumno al backend.
  /// Actualiza el estado de la UI para mostrar un indicador de carga y,
  /// al finalizar, muestra una tarjeta de feedback con el resultado
  /// (éxito o error) devuelto por el servidor.
  Future<void> _registrarAsistencia() async {
    setState(() {
      _isLoading = true;
      _feedbackMessage = null;
      _feedbackType = null;
      _registroInfo = null;
    });

    try {
      final result = await _incidenciaService.registrarAsistencia(
        widget.alumnoId,
      );

      if (!mounted) return;

      if (result['exito'] == true) {
        setState(() {
          _feedbackMessage = result['mensaje'];
          _feedbackType = 'exito';
          _registroInfo = {
            'Tipo de Registro': result['tipo'] ?? 'N/A',
            'Hora de Registro': result['hora'] ?? 'N/A',
          };
        });
      } else {
        setState(() {
          _feedbackMessage = result['mensaje'];
          _feedbackType = 'error';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _feedbackMessage = 'Ocurrió un error de conexión. Intente de nuevo.';
        _feedbackType = 'error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Colores basados en tu paleta institucional
    const azulMarino = Color(0xFF1B2F55);
    const azulBoton = Color(0xFF5084D1);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Fondo sutil y limpio
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 16.0,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 450,
                ), // Ancho máximo idéntico a web
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Tarjeta Principal (Estilo app-card-institucional)
                    Card(
                      elevation: 4,
                      shadowColor: Colors.black.withOpacity(0.15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: [
                          // Encabezado Institucional de la tarjeta
                          Container(
                            width: double.infinity,
                            color: azulMarino,
                            padding: const EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 20,
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.access_time_filled,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Control de Asistencia',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          // Cuerpo de la tarjeta
                          Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              children: [
                                // Círculo contenedor del ícono central
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: const Color(0xFFE2E8F0),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.person_pin_outlined,
                                    size: 40,
                                    color: azulMarino,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Registro de Horario',
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF1E293B),
                                      ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Hola.\nPresiona el botón inferior para registrar tu movimiento en el sistema.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 14,
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 32),
                                // Botón interactivo de Huella
                                _buildAsistenciaButton(azulBoton),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Tarjeta de feedback (Éxito / Error)
                    _buildFeedbackCard(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Construye el botón principal de registro con forma de huella.
  ///
  /// Cambia su apariencia y deshabilita la interacción si [_isLoading] es `true`,
  /// mostrando un [CircularProgressIndicator] en su lugar.
  Widget _buildAsistenciaButton(Color colorBoton) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            if (_isLoading)
              SizedBox(
                width: 120,
                height: 120,
                child: CircularProgressIndicator(
                  strokeWidth: 4,
                  valueColor: AlwaysStoppedAnimation<Color>(colorBoton),
                ),
              ),
            Material(
              color: _isLoading ? Colors.grey.shade300 : colorBoton,
              shape: const CircleBorder(),
              elevation: _isLoading ? 0 : 4,
              shadowColor: colorBoton.withOpacity(0.4),
              child: InkWell(
                onTap: _isLoading ? null : _registrarAsistencia,
                customBorder: const CircleBorder(),
                child: Container(
                  padding: const EdgeInsets.all(24.0),
                  child: Icon(
                    Icons.fingerprint, // Icono corregido aquí
                    size: 64.0,
                    color: _isLoading ? Colors.grey.shade500 : Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          _isLoading ? 'Procesando...' : 'Registrar Ahora',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: _isLoading ? Colors.grey : const Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  /// Construye la tarjeta de retroalimentación que aparece después de un registro.
  ///
  /// Es un widget condicional que solo se muestra si [_feedbackMessage] no es nulo.
  /// Se estiliza de color verde para éxito y rojo para error, basándose en
  /// el valor de [_feedbackType].
  Widget _buildFeedbackCard() {
    if (_feedbackMessage == null) return const SizedBox.shrink();

    final isSuccess = _feedbackType == 'exito';
    final mainColor = isSuccess ? const Color(0xFF198754) : Colors.red.shade700;
    final backgroundColor = isSuccess ? Colors.white : Colors.red.shade50;
    final icon = isSuccess ? Icons.check_circle : Icons.error_outline;

    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.05),
      color: backgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: mainColor, width: 6)),
        ),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(icon, color: mainColor, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _feedbackMessage!,
                    style: TextStyle(
                      color: isSuccess ? const Color(0xFF1E293B) : mainColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
            if (_registroInfo != null) ...[
              const Divider(height: 24, thickness: 1, color: Color(0xFFE2E8F0)),
              ..._registroInfo!.entries.map(
                (e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [ 
                      Text(
                        '${e.key}:',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 2,
                        ),
                        decoration: e.key == 'Tipo de Registro'
                            ? BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFCBD5E1),
                                ),
                              )
                            : null,
                        child: Text(
                          e.value,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: e.key == 'Tipo de Registro'
                                ? Colors.black87
                                : const Color(0xFF475569),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
