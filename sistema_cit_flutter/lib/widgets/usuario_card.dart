import 'package:flutter/material.dart';
import '../models/usuario.dart';

class UsuarioCard extends StatelessWidget {
  final Usuario usuario;
  final bool esUsuarioActual;
  final VoidCallback onVincular;
  final VoidCallback onCambiarRol;
  final VoidCallback onEliminar;

  const UsuarioCard({
    super.key,
    required this.usuario,
    required this.esUsuarioActual,
    required this.onVincular,
    required this.onCambiarRol,
    required this.onEliminar,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.05),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person, color: Colors.grey),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(usuario.email, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B))),
                      if (esUsuarioActual)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1B396A).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text('Tu cuenta', style: TextStyle(fontSize: 10, color: Color(0xFF1B396A), fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: usuario.rol == 'ADMINISTRADOR' ? const Color(0xFF1B396A) : Colors.green.shade700,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(usuario.rol == 'ADMINISTRADOR' ? Icons.shield : Icons.school, color: Colors.white, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        usuario.rol == 'ADMINISTRADOR' ? 'Administrador' : 'Alumno',
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1, color: Color(0xFFE2E8F0))),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: usuario.alumnoId != null
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(usuario.alumno ?? 'Desconocido', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF1E293B))),
                            Text(usuario.numeroControl ?? '', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                          ],
                        )
                      : Align(
                          alignment: Alignment.centerLeft,
                          child: ElevatedButton.icon(
                            onPressed: onVincular,
                            icon: const Icon(Icons.link, size: 16),
                            label: const Text('Vincular Alumno'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade600,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              elevation: 0,
                            ),
                          ),
                        ),
                ),
                if (!esUsuarioActual)
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: onCambiarRol,
                        icon: const Icon(Icons.sync, size: 16),
                        label: const Text('Rol'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF1B396A),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: onEliminar,
                        icon: const Icon(Icons.delete_outline, size: 16),
                        label: const Text('Eliminar'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red.shade700,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          side: BorderSide(color: Colors.red.shade200),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}