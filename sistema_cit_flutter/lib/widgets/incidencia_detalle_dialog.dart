import 'package:flutter/material.dart';
import '../models/incidencia.dart';

class IncidenciaDetalleDialog extends StatelessWidget {
  final Incidencia incidencia;

  const IncidenciaDetalleDialog({super.key, required this.incidencia});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Cabecera azul institucional
          Container(
            color: const Color(0xFF1B396A),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.white, size: 22),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Detalles de Incidencia',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.close, color: Colors.white70),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          // Cuerpo del Modal
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tarjeta principal del alumno
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B396A).withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: const Color(0xFF1B396A),
                          foregroundColor: Colors.white,
                          radius: 24,
                          child: Text(
                            incidencia.alumnoNombre.isNotEmpty
                                ? incidencia.alumnoNombre[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                incidencia.alumnoNombre,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${incidencia.numeroControl} • ${incidencia.carreraNombre}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Detalles grid
                  const Text(
                    'PROYECTO Y DOCENTE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _buildDetalleFila(
                    Icons.book_outlined,
                    incidencia.proyectoNombre ?? 'Sin proyecto asignado',
                    incidencia.docenteResponsable ?? 'No especificado',
                  ),
                  const Divider(
                    height: 24,
                    thickness: 1,
                    color: Color(0xFFE2E8F0),
                  ),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'TIPO DE INCIDENCIA',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _obtenerColorIncidencia(
                                  incidencia.tipoIncidencia,
                                ).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _obtenerColorIncidencia(
                                    incidencia.tipoIncidencia,
                                  ).withOpacity(0.5),
                                ),
                              ),
                              child: Text(
                                incidencia.tipoIncidencia,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _obtenerColorIncidencia(
                                    incidencia.tipoIncidencia,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'FECHA',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              incidencia.fecha,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(
                    height: 24,
                    thickness: 1,
                    color: Color(0xFFE2E8F0),
                  ),

                  const Text(
                    'HORARIO REGISTRADO',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _buildTimeBlock(
                      'Asistencia',
                      incidencia.horaAsistencia,
                      Icons.fingerprint,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'HORARIO ESPERADO',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildTimeBlock(
                        'Entrada esperada',
                        incidencia.horaEntradaEsperada ?? '--:--',
                        Icons.login,
                      ),
                      _buildTimeBlock(
                        'Salida esperada',
                        incidencia.horaSalidaEsperada ?? '--:--',
                        Icons.logout,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Footer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF1B396A),
                elevation: 0,
                side: const BorderSide(color: Color(0xFFCBD5E1)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
          ),
        ],
      ),
    );
  }

  Color _obtenerColorIncidencia(String tipo) {
    switch (tipo) {
      case 'Retardo':
        return Colors.orange.shade700;
      case 'Falta':
        return Colors.red.shade700;
      case 'Salida Anticipada':
        return Colors.blue.shade700;
      case 'Fuera de Horario':
        return Colors.cyan.shade700;
      case 'Justificado':
        return Colors.green.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  Widget _buildDetalleFila(IconData icon, String principal, String secundario) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF64748B), size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                principal,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              Text(
                secundario,
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimeBlock(String label, String time, IconData icon) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: Colors.grey.shade600),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          time,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }
}
