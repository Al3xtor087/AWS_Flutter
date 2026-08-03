import 'package:flutter/material.dart';

class ConfirmationDialog extends StatelessWidget {
  final String title;
  final Widget content;
  final String confirmText;
  final String cancelText;
  final Color confirmButtonColor;
  final IconData icon;
  final Color iconColor;

  const ConfirmationDialog({
    super.key,
    required this.title,
    required this.content,
    this.confirmText = 'Confirmar',
    this.cancelText = 'Cancelar',
    required this.confirmButtonColor,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
      content: content,
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          style: TextButton.styleFrom(foregroundColor: Colors.grey.shade700),
          child: Text(cancelText),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          style: FilledButton.styleFrom(backgroundColor: confirmButtonColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
          child: Text(confirmText, style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}