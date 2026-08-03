import 'package:flutter/material.dart';

class AsistenciaCard extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onRegistrar;

  const AsistenciaCard({
    super.key,
    required this.isLoading,
    required this.onRegistrar,
  });

  @override
  Widget build(BuildContext context) {
    const azulMarino = Color(0xFF1B2F55);
    const azulBoton = Color(0xFF5084D1);

    return Card(
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
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
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
    );
  }

  Widget _buildAsistenciaButton(Color colorBoton) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            if (isLoading)
              SizedBox(
                width: 120,
                height: 120,
                child: CircularProgressIndicator(
                  strokeWidth: 4,
                  valueColor: AlwaysStoppedAnimation<Color>(colorBoton),
                ),
              ),
            Material(
              color: isLoading ? Colors.grey.shade300 : colorBoton,
              shape: const CircleBorder(),
              elevation: isLoading ? 0 : 4,
              shadowColor: colorBoton.withOpacity(0.4),
              child: InkWell(
                onTap: isLoading ? null : onRegistrar,
                customBorder: const CircleBorder(),
                child: Container(
                  padding: const EdgeInsets.all(24.0),
                  child: Icon(
                    Icons.fingerprint,
                    size: 64.0,
                    color: isLoading ? Colors.grey.shade500 : Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          isLoading ? 'Procesando...' : 'Registrar Ahora',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isLoading ? Colors.grey : const Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }
}