import 'package:flutter/material.dart';
import '../models/alumno_disponible.dart';
import '../models/usuario.dart';
import '../services/admin_service.dart';
import '../services/auth_service.dart';
import '../widgets/admin_usuarios_list.dart';
import '../widgets/admin_usuarios_header.dart';
import '../widgets/cambiar_rol_dialog.dart';
import '../widgets/common_state_views.dart';
import '../widgets/eliminar_usuario_dialog.dart';
import '../widgets/usuario_card.dart';
import '../widgets/vincular_alumno_dialog.dart';

/// Pantalla principal para la administración de usuarios.
///
/// Permite a los administradores visualizar, filtrar y gestionar todas las
/// cuentas de usuario del sistema. Ofrece funcionalidades para cambiar roles,
/// vincular cuentas de alumnos y eliminar usuarios.
class PanelAdminUsuariosScreen extends StatefulWidget {
  const PanelAdminUsuariosScreen({super.key});

  @override
  State<PanelAdminUsuariosScreen> createState() => _PanelAdminUsuariosScreenState();
}
/// Lógica y estado para [PanelAdminUsuariosScreen].
class _PanelAdminUsuariosScreenState extends State<PanelAdminUsuariosScreen> {
  // --- SERVICIOS Y CONTROLADORES ---
  final AdminService _adminService = AdminService();
  final TextEditingController _searchController = TextEditingController();

  // --- ESTADO DE LA UI ---
  /// Lista completa de usuarios obtenida del backend.
  List<Usuario> _usuarios = [];
  /// Lista de usuarios que se muestra en la UI, después de aplicar filtros.
  List<Usuario> _usuariosFiltrados = [];
  /// Controla la visibilidad del indicador de carga.
  bool _isLoading = true;
  /// Almacena un mensaje de error si la carga de datos falla.
  String? _errorMessage;
  /// Valor actual del filtro de rol ('TODOS', 'ADMINISTRADOR', 'ALUMNO').
  String _filtroRol = 'TODOS';
  /// Email del usuario que está usando la app, para evitar auto-eliminación.
  String? _currentUserEmail;
  /// Lista de alumnos sin cuenta, para el diálogo de vinculación.
  List<AlumnoDisponible> _alumnosDisponibles = [];

  @override
  void initState() {
    super.initState();
    // Agrega un listener para que los filtros se apliquen en tiempo real al escribir.
    _searchController.addListener(_aplicarFiltros);
    _currentUserEmail = AuthService.getCurrentUserEmail();
    // Carga los datos iniciales al entrar a la pantalla.
    _cargarUsuarios();
    _cargarAlumnosDisponibles();
  }

  @override
  void dispose() {
    // Limpia los recursos para evitar fugas de memoria.
    _searchController.removeListener(_aplicarFiltros);
    _searchController.dispose();
    super.dispose();
  }

  /// Carga la lista de usuarios desde el [AdminService].
  ///
  /// Actualiza el estado de la UI para mostrar un indicador de carga,
  /// maneja los errores de conexión y finalmente actualiza la lista
  /// de usuarios si la operación es exitosa.
  Future<void> _cargarUsuarios() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final usuarios = await _adminService.getUsuarios();
      if (!mounted) return;

      setState(() {
        _usuarios = usuarios;
        _aplicarFiltros();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'No fue posible cargar los usuarios.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Carga la lista de alumnos que aún no tienen una cuenta de usuario.
  ///
  /// Esta lista se utiliza en el diálogo de vinculación para que el
  /// administrador pueda asociar una cuenta a un registro de alumno existente.
  Future<void> _cargarAlumnosDisponibles() async {
    try {
      _alumnosDisponibles = await _adminService.getAlumnosSinCuenta();
    } catch (e) {
      debugPrint('No se pudieron cargar los alumnos disponibles: $e');
      if (mounted) setState(() => _alumnosDisponibles = []);
    }
  }

  /// Filtra la lista de [_usuarios] según el texto de búsqueda y el rol seleccionado.
  ///
  /// El resultado se almacena en [_usuariosFiltrados], que es la lista
  /// que se renderiza en la pantalla. Se ejecuta cada vez que el texto de
  /// búsqueda o el filtro de rol cambian.
  void _aplicarFiltros() {
    final busqueda = _searchController.text.toLowerCase();
    setState(() {
      _usuariosFiltrados = _usuarios.where((u) {
        final coincideBusqueda = busqueda.isEmpty ||
            u.email.toLowerCase().contains(busqueda) ||
            (u.alumno?.toLowerCase().contains(busqueda) ?? false) ||
            (u.numeroControl?.toLowerCase().contains(busqueda) ?? false);

        final coincideRol = _filtroRol == 'TODOS' || u.rol == _filtroRol;

        return coincideBusqueda && coincideRol;
      }).toList();
    });
  }

  // --- DIÁLOGOS DE ACCIONES ---

  /// Muestra un diálogo para cambiar el rol de un [usuario].
  ///
  /// Invoca a [CambiarRolDialog] y, si la operación es exitosa,
  /// actualiza el rol del usuario en la lista local y muestra un
  /// mensaje de confirmación.
  Future<void> _mostrarDialogoCambiarRol(Usuario usuario) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final rolFinal = await CambiarRolDialog.show(
      context: context,
      usuario: usuario,
      onGuardarRol: (nuevoRol) => _adminService.cambiarRol(usuario.email, nuevoRol),
    ).catchError((e) {
      scaffoldMessenger.showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red.shade700));
      return null;
    });

    if (rolFinal != null) {
      setState(() {
        final index = _usuarios.indexWhere((u) => u.id == usuario.id);
        if (index != -1) {
          _usuarios[index] = _usuarios[index].copyWith(rol: rolFinal);
          _aplicarFiltros();
        }
      });
      scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Rol actualizado correctamente.'), backgroundColor: Colors.green));
    }
  }

  /// Muestra un diálogo para vincular una cuenta de [usuario] a un alumno.
  ///
  /// Utiliza la lista precargada de [_alumnosDisponibles]. Si la vinculación
  /// es exitosa, el backend devuelve el usuario actualizado, que se usa para
  /// refrescar la UI localmente. También recarga la lista de alumnos
  /// disponibles, ya que uno de ellos ha sido vinculado.
  Future<void> _mostrarDialogoVincular(Usuario usuario) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    if (_alumnosDisponibles.isEmpty) {
      scaffoldMessenger.showSnackBar(const SnackBar(content: Text('No hay alumnos disponibles para vincular.')));
      return;
    }

    final usuarioActualizado = await VincularAlumnoDialog.show(
      context: context,
      usuario: usuario,
      alumnosDisponibles: _alumnosDisponibles,
      onVincular: (alumnoId) => _adminService.vincularAlumno(usuario.email, alumnoId),
    ).catchError((e) {
      scaffoldMessenger.showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red.shade700));
      return null;
    });

    if (usuarioActualizado != null) {
      setState(() {
        final index = _usuarios.indexWhere((u) => u.id == usuario.id);
        if (index != -1) {
          _usuarios[index] = usuarioActualizado;
          _aplicarFiltros();
          _cargarAlumnosDisponibles();
        }
      });
      scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Cuenta vinculada correctamente.'), backgroundColor: Colors.green));
    }
  }

  /// Muestra un diálogo de confirmación para eliminar un [usuario].
  ///
  /// Si el administrador confirma la acción, se llama al servicio para
  /// eliminar el usuario del backend y se actualiza la lista en la UI
  /// para reflejar el cambio.
  Future<void> _confirmarEliminar(Usuario usuario) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final confirmar = await EliminarUsuarioDialog.show(
      context: context,
      email: usuario.email,
    );

    if (confirmar != true) return;

    try {
      await _adminService.eliminarUsuario(usuario.id);
      if (!mounted) return;

      setState(() {
        _usuarios.removeWhere((u) => u.id == usuario.id);
        _aplicarFiltros();
      });
      scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Usuario eliminado correctamente.'), backgroundColor: Colors.orange));
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red.shade700));
      }
    }
  }

  // --- WIDGETS DE UI ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            AdminUsuariosHeader(
              searchController: _searchController,
              filtroRol: _filtroRol,
              onActualizar: _cargarUsuarios,
              onFiltroRolChanged: (value) {
                if (value != null) {
                  setState(() => _filtroRol = value);
                  _aplicarFiltros();
                }
              },
            ),
            Expanded(child: _buildBodyContent()),
          ],
        ),
      ),
    );
  }

  /// Construye el cuerpo principal de la pantalla según el estado actual.
  ///
  /// - Muestra [LoadingView] si los datos están cargando.
  /// - Muestra [ErrorView] si ocurrió un error.
  /// - Muestra [EmptyView] si no hay usuarios que coincidan con los filtros.
  /// - Muestra [AdminUsuariosList] con la lista de usuarios filtrados.
  Widget _buildBodyContent() {
    if (_isLoading) {
      return const LoadingView(message: 'Cargando usuarios...');
    }

    if (_errorMessage != null) {
      return ErrorView(
        message: _errorMessage!,
        onRetry: _cargarUsuarios,
      );
    }

    if (_usuariosFiltrados.isEmpty) {
      return const EmptyView();
    }

    return AdminUsuariosList(
      usuarios: _usuariosFiltrados,
      currentUserEmail: _currentUserEmail,
      onRefresh: _cargarUsuarios,
      onVincular: _mostrarDialogoVincular,
      onCambiarRol: _mostrarDialogoCambiarRol,
      onEliminar: _confirmarEliminar,
    );
  }
}