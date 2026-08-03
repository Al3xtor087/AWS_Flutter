import 'package:flutter/material.dart';

/// Un widget para mostrar un indicador de carga centrado con un mensaje.
class LoadingView extends StatelessWidget {
  final String message;
  const LoadingView({super.key, this.message = 'Cargando...'});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: Color(0xFF1B396A)),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

/// Un widget para mostrar un mensaje de error con un botón para reintentar la acción.
class ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final IconData icon;

  const ErrorView({
    super.key,
    required this.message,
    required this.onRetry,
    this.icon = Icons.warning_amber_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle),
              child: Icon(icon, size: 48, color: Colors.red.shade400),
            ),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF1B396A)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Un widget para indicar que no se encontraron resultados o que una lista está vacía.
class EmptyView extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const EmptyView({
    super.key,
    this.title = 'No se encontraron resultados',
    this.subtitle = 'Intenta cambiando los filtros de búsqueda.',
    this.icon = Icons.inbox_outlined,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey.shade600)),
            const SizedBox(height: 4),
            Text(subtitle, style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}