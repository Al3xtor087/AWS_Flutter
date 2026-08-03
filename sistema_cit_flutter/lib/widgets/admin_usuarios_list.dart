import 'package:flutter/material.dart';

import '../models/usuario.dart';
import 'usuario_card.dart';

class AdminUsuariosList extends StatelessWidget {
  final List<Usuario> usuarios;
  final String? currentUserEmail;
  final Future<void> Function() onRefresh;
  final void Function(Usuario usuario) onVincular;
  final void Function(Usuario usuario) onCambiarRol;
  final void Function(Usuario usuario) onEliminar;

  const AdminUsuariosList({
    super.key,
    required this.usuarios,
    required this.currentUserEmail,
    required this.onRefresh,
    required this.onVincular,
    required this.onCambiarRol,
    required this.onEliminar,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: const Color(0xFF1B396A),
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: usuarios.length,
        itemBuilder: (context, index) {
          final usuario = usuarios[index];
          final esUsuarioActual = usuario.email == currentUserEmail;

          return UsuarioCard(
            usuario: usuario,
            esUsuarioActual: esUsuarioActual,
            onVincular: () => onVincular(usuario),
            onCambiarRol: () => onCambiarRol(usuario),
            onEliminar: () => onEliminar(usuario),
          );
        },
      ),
    );
  }
}
