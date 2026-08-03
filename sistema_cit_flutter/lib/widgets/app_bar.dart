import 'package:flutter/material.dart';

// Componente reutilizable que expone la barra de navegación superior adaptada a los estándares de la institución.
class AppBarInstitucional extends StatelessWidget implements PreferredSizeWidget {
  // Propiedades básicas de configuración de la barra.
  final String titulo;
  final VoidCallback? onRefresh;
  
  // Parámetros obligatorios encargados de inyectar el control de la fecha y los eventos asíncronos.
  final DateTime fechaSeleccionada;
  final ValueChanged<DateTime> onFechaCambiada;
  final VoidCallback onGenerar;

  const AppBarInstitucional({
    super.key,
    required this.titulo,
    required this.fechaSeleccionada, 
    required this.onFechaCambiada,
    required this.onGenerar,   
    this.onRefresh,
  });

  @override
  // Método que define la altura por defecto que ocupará la AppBar dentro del Scaffold.
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  // Método de maquetación encargado de estructurar las acciones y la estética de la barra superior.
  Widget build(BuildContext context) {
    // Método que formatea de manera abreviada el día y mes para optimizar el espacio del botón.
    String fechaTexto = "${fechaSeleccionada.day}/${fechaSeleccionada.month}";

    return AppBar(
      backgroundColor: const Color(0xFF1B396A),
      foregroundColor: Colors.white,
      elevation: 0,
      title: Text(
        titulo,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 18,
          letterSpacing: 0.5,
        ),
      ),
      
      // Colección de botones de control interactivos alineados en el extremo derecho.
      actions: [
        // Disparador directo del proceso asíncrono para calcular e insertar las incidencias del día.
        IconButton(
          icon: const Icon(Icons.bolt_rounded, color: Colors.amber), 
          tooltip: 'Generar Incidencias del Día',
          onPressed: onGenerar,
        ),
        
        // Botón interactivo que despliega el selector modal del calendario de Material Design.
        TextButton.icon(
          onPressed: () => _abrirCalendario(context), 
          icon: const Icon(Icons.calendar_month_rounded, color: Colors.white, size: 20),
          label: Text(
            fechaTexto,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
          ),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12),
          ),
        ),
        
        // Estructura de renderizado condicional para el botón de sincronización manual de la lista.
        if (onRefresh != null)
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Sincronizar',
            onPressed: onRefresh,
          ),
      ],
    );
  }

  /// Método asíncrono interno encargado de invocar el DatePicker nativo del sistema operativo.
  Future<void> _abrirCalendario(BuildContext context) async {
    // Invoca la ventana modal flotante configurando los límites temporales permitidos.
    final DateTime? fechaEscogida = await showDatePicker(
      context: context,
      initialDate: fechaSeleccionada,
      firstDate: DateTime(2025),
      lastDate: DateTime.now(), 
      
      // Aplica la personalización de estilos institucionales sobre el lienzo del calendario.
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1B396A), 
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );

    // Valida la selección del usuario y despacha la nueva fecha al componente padre emitiendo el evento.
    if (fechaEscogida != null && fechaEscogida != fechaSeleccionada) {
      onFechaCambiada(fechaEscogida); 
    }
  }
}