import 'package:flutter/material.dart';

class IncidenciasPanelHeader extends StatelessWidget {
  final DateTime selectedDate;
  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final VoidCallback onDateChange;
  final VoidCallback onRefresh;
  final Function(String) onSearchSubmitted;

  const IncidenciasPanelHeader({
    super.key,
    required this.selectedDate,
    required this.searchController,
    required this.searchFocusNode,
    required this.onDateChange,
    required this.onRefresh,
    required this.onSearchSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    const azulMarino = Color(0xFF1B396A);

    return Column(
      children: [
        // Cabecera Institucional
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Control de Incidencias',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Gestión y monitoreo de asistencias institucionales',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2)),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.calendar_month_outlined, size: 16, color: azulMarino),
                    const SizedBox(width: 6),
                    Text(
                      _formatearFecha(selectedDate),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: azulMarino),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Tarjeta de Filtros (Card Institucional)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Card(
            elevation: 2,
            shadowColor: Colors.black.withOpacity(0.1),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Filtros Rápidos',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: azulMarino),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: searchController,
                          focusNode: searchFocusNode,
                          textInputAction: TextInputAction.search,
                          onSubmitted: onSearchSubmitted,
                          decoration: InputDecoration(
                            hintText: 'Buscar por nombre o número...',
                            hintStyle: const TextStyle(fontSize: 14),
                            prefixIcon: const Icon(Icons.search, size: 20),
                            suffixIcon: searchController.text.isEmpty
                                ? null
                                : IconButton(
                                    onPressed: () {
                                      searchController.clear();
                                      onRefresh();
                                    },
                                    icon: const Icon(Icons.clear, size: 18),
                                  ),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: azulMarino),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: OutlinedButton.icon(
                          onPressed: onDateChange,
                          icon: const Icon(Icons.calendar_today_outlined, size: 16),
                          label: const Text('Fecha', style: TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: azulMarino,
                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: onRefresh,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: azulMarino,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                        child: const Icon(Icons.refresh, size: 20),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  String _formatearFecha(DateTime fecha) {
    return '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
  }
}