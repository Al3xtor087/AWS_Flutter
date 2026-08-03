import 'package:flutter/material.dart';

import '../models/usuario.dart';

class CambiarRolDialog extends StatelessWidget {
  final Usuario usuario;
  final Future<void> Function(String nuevoRol) onGuardarRol;

  const CambiarRolDialog({
    super.key,
    required this.usuario,
    required this.onGuardarRol,
  });

  static Future<String?> show({
    required BuildContext context,
    required Usuario usuario,
    required Future<void> Function(String nuevoRol) onGuardarRol,
  }) {
    return showDialog<String>(
      context: context,
      builder: (context) => CambiarRolDialog(
        usuario: usuario,
        onGuardarRol: onGuardarRol,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _CambiarRolDialogContent(
      usuario: usuario,
      onGuardarRol: onGuardarRol,
    );
  }
}

class _CambiarRolDialogContent extends StatefulWidget {
  final Usuario usuario;
  final Future<void> Function(String nuevoRol) onGuardarRol;

  const _CambiarRolDialogContent({
    required this.usuario,
    required this.onGuardarRol,
  });

  @override
  State<_CambiarRolDialogContent> createState() =>
      _CambiarRolDialogContentState();
}

class _CambiarRolDialogContentState extends State<_CambiarRolDialogContent> {
  late String _rolSeleccionado;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _rolSeleccionado = widget.usuario.rol;
  }

  Future<void> _guardar() async {
    setState(() => _guardando = true);
    try {
      await widget.onGuardarRol(_rolSeleccionado);
      if (!mounted) return;
      Navigator.pop(context, _rolSeleccionado);
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
      }
      rethrow;
    } finally {
      if (mounted) {
        setState(() => _guardando = false);
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
            color: const Color(0xFF1B396A),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                const Icon(
                  Icons.admin_panel_settings,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Cambiar Rol de Usuario',
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
                  onPressed: _guardando ? null : () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B396A).withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFF1B396A).withOpacity(0.1),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.person,
                        color: Color(0xFF1B396A),
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'USUARIO SELECCIONADO',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              widget.usuario.email,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'NUEVO ROL',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: _rolSeleccionado,
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
                  items: ['ADMINISTRADOR', 'ALUMNO']
                      .map((rol) => DropdownMenuItem(value: rol, child: Text(rol)))
                      .toList(),
                  onChanged: _guardando
                      ? null
                      : (value) {
                          if (value != null) {
                            setState(() => _rolSeleccionado = value);
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
                  onPressed: _guardando ? null : () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey.shade700,
                  ),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _guardando ? null : _guardar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B396A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _guardando
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Guardar Cambios',
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
