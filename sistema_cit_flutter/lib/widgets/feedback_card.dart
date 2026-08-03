import 'package:flutter/material.dart';

class FeedbackCard extends StatelessWidget {
  final String? message;
  final String? type; // 'exito', 'error'
  final Map<String, String>? registroInfo;

  const FeedbackCard({
    super.key,
    this.message,
    this.type,
    this.registroInfo,
  });

  @override
  Widget build(BuildContext context) {
    if (message == null) return const SizedBox.shrink();

    final isSuccess = type == 'exito';
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
                    message!,
                    style: TextStyle(
                      color: isSuccess ? const Color(0xFF1E293B) : mainColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
            if (registroInfo != null) ...[
              const Divider(height: 24, thickness: 1, color: Color(0xFFE2E8F0)),
              ...registroInfo!.entries.map(
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
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                        decoration: e.key == 'Tipo de Registro'
                            ? BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFCBD5E1)),
                              )
                            : null,
                        child: Text(
                          e.value,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: e.key == 'Tipo de Registro' ? Colors.black87 : const Color(0xFF475569),
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