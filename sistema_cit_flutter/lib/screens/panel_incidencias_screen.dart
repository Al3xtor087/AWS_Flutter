import 'package:flutter/material.dart';
import '../models/incidencia.dart';
import '../services/incidencia_service.dart';
import '../widgets/common_state_views.dart';
import '../widgets/confirmation_dialog.dart';
import '../widgets/incidencia_detalle_dialog.dart';
import '../widgets/tarjeta_incidencia.dart';
import '../widgets/incidencias_panel_header.dart';

/// Pantalla principal para la gestión de incidencias de asistencia.
///
/// Permite a los administradores visualizar, filtrar por fecha y texto,
/// y realizar acciones sobre las incidencias, como justificar o eliminar.
class PanelIncidenciasScreen extends StatefulWidget {
  const PanelIncidenciasScreen({super.key});

  @override
  State<PanelIncidenciasScreen> createState() => _PanelIncidenciasScreenState();
}
/// Lógica y estado para [PanelIncidenciasScreen].
class _PanelIncidenciasScreenState extends State<PanelIncidenciasScreen> {
  // --- SERVICIOS Y CONTROLADORES ---
  final IncidenciaService _incidenciaService = IncidenciaService();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  // --- ESTADO DE LA UI ---
  /// Lista de incidencias que se muestra en la pantalla.
  List<Incidencia> _incidencias = [];
  /// Controla la visibilidad del indicador de carga.
  bool _isLoading = false;
  /// Almacena un mensaje de error si la carga de datos falla.
  String? _errorMessage;
  /// La fecha actualmente seleccionada para filtrar las incidencias.
  /// Por defecto, se inicializa con el día de ayer.
  DateTime _selectedDate = DateTime.now().subtract(const Duration(days: 1));

  @override
  void initState() {
    super.initState();
    // Carga los datos iniciales al entrar a la pantalla.
    _cargarIncidencias();
  }

  @override
  void dispose() {
    // Limpia los recursos para evitar fugas de memoria.
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  /// Carga la lista de incidencias desde el [IncidenciaService].
  ///
  /// Utiliza la [_selectedDate] y el texto de [_searchController] para
  /// aplicar los filtros en la petición al backend. Actualiza el estado
  /// de la UI para mostrar un indicador de carga y manejar errores.
  Future<void> _cargarIncidencias() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final fecha = _selectedDate.toIso8601String().split('T').first;
      final resultado = await _incidenciaService.getFiltrado(
        buscar: _searchController.text.trim().isEmpty
            ? null
            : _searchController.text.trim(),
        fecha: fecha,
      );

      if (!mounted) return;

      setState(() {
        _incidencias = resultado;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'No fue posible cargar las incidencias.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Muestra un [DatePicker] para que el usuario elija una nueva fecha.
  ///
  /// Si se selecciona una fecha, actualiza el estado [_selectedDate] y
  /// vuelve a llamar a [_cargarIncidencias] para refrescar la lista.
  Future<void> _seleccionarFecha() async {
    final fechaSeleccionada = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1B396A), // Azul institucional
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (fechaSeleccionada != null) {
      setState(() {
        _selectedDate = fechaSeleccionada;
      });
      await _cargarIncidencias();
    }
  }

  /// Muestra un diálogo con los detalles completos de una [Incidencia].
  ///
  /// Busca la incidencia en la lista local por su [id] y, si la encuentra,
  /// presenta el widget [IncidenciaDetalleDialog].
  Future<void> _mostrarDetalle(String id) async {
    final incidencia = _incidencias.where((item) => item.id == id).firstOrNull;
    if (incidencia == null) return;
    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (context) => IncidenciaDetalleDialog(incidencia: incidencia),
    );
  }

  /// Muestra un diálogo de confirmación para eliminar una incidencia.
  ///
  /// Si el usuario confirma, llama al [IncidenciaService] para eliminarla
  /// del backend. Si la operación es exitosa, recarga la lista de incidencias
  /// y muestra un mensaje de confirmación.
  Future<void> _confirmarEliminar(String id, String nombre) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: 'Eliminar incidencia',
        content: Text('¿Deseas eliminar la incidencia de $nombre? Esta acción no se puede deshacer.'),
        confirmText: 'Eliminar',
        confirmButtonColor: Colors.red.shade600,
        icon: Icons.warning_amber_rounded,
        iconColor: Colors.red.shade700,
      ),
    );

    if (confirmar != true) return;

    final exito = await _incidenciaService.eliminarIncidencia(id);
    if (!mounted) return;

    if (exito) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Incidencia eliminada correctamente.'),
          backgroundColor: Colors.green,
        ),
      );
      // Esto asegura que la UI refleje el estado real de la base de datos (incidencia anulada).
      await _cargarIncidencias();
    } else {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: const Text('No se pudo eliminar la incidencia.'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  /// Muestra un diálogo de confirmación para justificar una incidencia.
  ///
  /// Si el usuario confirma, llama al [IncidenciaService] para cambiar su estado
  /// a "Justificado". Si la operación es exitosa, recarga la lista para
  /// reflejar el cambio y muestra un mensaje de confirmación.
  Future<void> _justificarIncidencia(String id, String nombre) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: 'Justificar incidencia',
        content: Text('¿Deseas justificar la incidencia de $nombre? El estado pasará a ser "Justificado".'),
        confirmText: 'Justificar',
        confirmButtonColor: Colors.green.shade600,
        icon: Icons.gpp_good,
        iconColor: Colors.green.shade700,
      ),
    );

    if (confirmar != true) return;

    final exito = await _incidenciaService.justificarIncidencia(id);
    if (!mounted) return;

    if (exito) {
      await _cargarIncidencias();
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Incidencia justificada correctamente.'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: const Text('No se pudo justificar la incidencia.'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            IncidenciasPanelHeader(
              selectedDate: _selectedDate,
              searchController: _searchController,
              searchFocusNode: _searchFocusNode,
              onDateChange: _seleccionarFecha,
              onRefresh: _cargarIncidencias,
              onSearchSubmitted: (_) => _cargarIncidencias(),
            ),
            Expanded(child: _buildContenido()),
          ],
        ),
      ),
    );
  }

  /// Construye el cuerpo principal de la pantalla según el estado actual.
  ///
  /// - Muestra [LoadingView] si los datos están cargando.
  /// - Muestra [ErrorView] si ocurrió un error.
  /// - Muestra [EmptyView] si no hay incidencias para los filtros seleccionados.
  /// - Muestra un [ListView] con las [TarjetaIncidencia] correspondientes.
  Widget _buildContenido() {
    if (_isLoading) {
      return const LoadingView(message: 'Cargando incidencias...');
    }

    if (_errorMessage != null) {
      return ErrorView(
        message: _errorMessage!,
        onRetry: _cargarIncidencias,
        icon: Icons.wifi_off_rounded,
      );
    }

    if (_incidencias.isEmpty) {
      return const EmptyView(
        title: 'No se encontraron registros',
        subtitle: 'Intenta seleccionando otra fecha de búsqueda.',
      );
    }

    return RefreshIndicator(
      color: const Color(0xFF1B396A),
      onRefresh: _cargarIncidencias,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: _incidencias.length,
        itemBuilder: (context, index) {
          final incidencia = _incidencias[index];
          return TarjetaIncidencia(
            incidencia: incidencia,
            // Convertimos el int que arroja la tarjeta a String para que encaje con tus métodos
            onMostrarDetalle: _mostrarDetalle,
            onConfirmarEliminar: _confirmarEliminar,
            onEjecutarJustificar: _justificarIncidencia,
          );
        },
      ),
    );
  }
}

/// Extensión para obtener el primer elemento de un iterable o `null` si está vacío.
extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
