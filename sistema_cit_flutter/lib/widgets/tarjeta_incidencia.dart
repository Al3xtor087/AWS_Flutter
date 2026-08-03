import 'package:flutter/material.dart';
import '../models/incidencia.dart';

class TarjetaIncidencia extends StatefulWidget {
  final Incidencia incidencia;
  final Function(String) onMostrarDetalle;
  final Function(String, String) onConfirmarEliminar;
  final Function(String, String) onEjecutarJustificar;

  const TarjetaIncidencia({
    super.key,
    required this.incidencia,
    required this.onMostrarDetalle,
    required this.onConfirmarEliminar,
    required this.onEjecutarJustificar,
  });

  @override
  State<TarjetaIncidencia> createState() => _TarjetaIncidenciaState();
}

class _TarjetaIncidenciaState extends State<TarjetaIncidencia> {
  bool _expandida = false;

  static final Map<String, Color> _coloresTipo = {
    'Retardo': Colors.amber[700]!,
    'Falta': Colors.red[600]!,
    'Salida Anticipada': const Color(0xFF1B396A),
    'Fuera de Horario': const Color.fromARGB(255, 54, 148, 202),
    'Justificado': const Color.fromARGB(255, 27, 106, 63),
  };

  @override
  Widget build(BuildContext context) {
    final colorIndicador =
        _coloresTipo[widget.incidencia.tipoIncidencia] ?? Colors.grey;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => setState(() => _expandida = !_expandida),
          child: Container(
            decoration: BoxDecoration(
              border: Border(left: BorderSide(color: colorIndicador, width: 5)),
              color: Colors.white,
            ),
            padding: const EdgeInsets.all(20),
            child: AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: const Color(
                          0xFF1B396A,
                        ).withValues(alpha: 0.1),
                        child: Text(
                          widget.incidencia.alumnoNombre[0],
                          style: const TextStyle(
                            color: Color(0xFF1B396A),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.incidencia.alumnoNombre,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${widget.incidencia.numeroControl} • ${widget.incidencia.horaAsistencia}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: colorIndicador.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          widget.incidencia.tipoIncidencia,
                          style: TextStyle(
                            color: colorIndicador,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_expandida) ...[
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _buildBotonAccion(
                          Icons.info_outline,
                          'Detalles',
                          Colors.blueGrey,
                          () => widget.onMostrarDetalle(widget.incidencia.id),
                        ),
                        const SizedBox(width: 8),
                        _buildBotonAccion(
                          Icons.delete_outline,
                          'Eliminar',
                          Colors.red,
                          () => widget.onConfirmarEliminar(
                            widget.incidencia.id,
                            widget.incidencia.alumnoNombre,
                          ),
                        ),
                        if (widget.incidencia.tipoIncidencia !=
                            "Justificado") ...[
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: () => widget.onEjecutarJustificar(
                              widget.incidencia.id,
                              widget.incidencia.alumnoNombre,
                            ),
                            icon: const Icon(Icons.shield_outlined, size: 16),
                            label: const Text(
                              'Justificar',
                              style: TextStyle(fontSize: 12),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              elevation: 0,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBotonAccion(
    IconData icono,
    String texto,
    Color color,
    VoidCallback accion,
  ) {
    return OutlinedButton.icon(
      onPressed: accion,
      icon: Icon(icono, size: 16),
      label: Text(texto, style: const TextStyle(fontSize: 12)),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color),
        padding: const EdgeInsets.symmetric(horizontal: 12),
      ),
    );
  }
}
