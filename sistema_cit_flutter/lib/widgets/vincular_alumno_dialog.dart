import 'package:flutter/material.dart';

import '../models/alumno_disponible.dart';
import '../models/usuario.dart';

class VincularAlumnoDialog extends StatelessWidget {
  final Usuario usuario;
  final List<AlumnoDisponible> alumnosDisponibles;
  final Future<Usuario?> Function(String alumnoId) onVincular;

  const VincularAlumnoDialog({
    super.key,
    required this.usuario,
    required this.alumnosDisponibles,
    required this.onVincular,
  });

  static Future<Usuario?> show({
    required BuildContext context,
    required Usuario usuario,
    required List<AlumnoDisponible> alumnosDisponibles,
    required Future<Usuario?> Function(String alumnoId) onVincular,
  }) {
    return showDialog<Usuario?>(
      context: context,
      builder: (context) => VincularAlumnoDialog(
        usuario: usuario,
        alumnosDisponibles: alumnosDisponibles,
        onVincular: onVincular,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _VincularAlumnoDialogContent(
      usuario: usuario,
      alumnosDisponibles: alumnosDisponibles,
      onVincular: onVincular,
    );
  }
}

class _VincularAlumnoDialogContent extends StatefulWidget {
  final Usuario usuario;
  final List<AlumnoDisponible> alumnosDisponibles;
  final Future<Usuario?> Function(String alumnoId) onVincular;

  const _VincularAlumnoDialogContent({
    required this.usuario,
    required this.alumnosDisponibles,
    required this.onVincular,
  });

  @override
  State<_VincularAlumnoDialogContent> createState() =>
      _VincularAlumnoDialogContentState();
}

class _VincularAlumnoDialogContentState
    extends State<_VincularAlumnoDialogContent> {
  String? _alumnoIdSeleccionado;
  bool _vinculando = false;

  Future<void> _vincular() async {
    if (_alumnoIdSeleccionado == null) return;

    setState(() => _vinculando = true);
    try {
      final resultado = await widget.onVincular(_alumnoIdSeleccionado!);
      if (!mounted) return;
      Navigator.pop(context, resultado);
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
      }
      rethrow;
    } finally {
      if (mounted) {
        setState(() => _vinculando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            color: const Color(0xFF0C63E4),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                const Icon(Icons.link, color: Colors.white, size: 24),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Vincular Estudiante',
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
                  onPressed: _vinculando ? null : () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Esta cuenta no está conectada a ningún registro escolar. Selecciona al estudiante correspondiente.',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 16),
                const Text(
                  'CORREO DE LA CUENTA',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  initialValue: widget.usuario.email,
                  readOnly: true,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'SELECCIONAR ALUMNO',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: _alumnoIdSeleccionado,
                  hint: const Text(
                    'Busca un alumno sin cuenta',
                    style: TextStyle(fontSize: 14),
                  ),
                  isExpanded: true,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                  ),
                  items: widget.alumnosDisponibles
                      .map(
                        (a) => DropdownMenuItem(
                          value: a.id,
                          child: Text(
                            '${a.numeroControl} - ${a.nombreCompleto}',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: _vinculando
                      ? null
                      : (value) {
                          if (value != null) {
                            setState(() => _alumnoIdSeleccionado = value);
                          }
                        },
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _vinculando ? null : () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey.shade700,
                  ),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _alumnoIdSeleccionado == null || _vinculando
                      ? null
                      : _vincular,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _vinculando
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Vincular Cuenta',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
