import 'package:flutter/material.dart';
import 'package:jwt_decode/jwt_decode.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'panel_admin_usuarios_screen.dart';
import 'panel_incidencias_screen.dart';
import 'registro_asistencia_screen.dart';

/// Pantalla principal de la aplicación que actúa como un contenedor de navegación.
///
/// Muestra diferentes vistas y opciones de menú según el rol del usuario
/// (Administrador o Alumno) que ha iniciado sesión.
class HomeScreen extends StatefulWidget {
  final String token;
  final Map<String, dynamic>? userProfile; // Recibimos el perfil completo
  const HomeScreen({super.key, required this.token, this.userProfile});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

/// Lógica y estado para la [HomeScreen].
class _HomeScreenState extends State<HomeScreen> {
  /// Índice de la pantalla actualmente seleccionada en la barra de navegación.
  int _selectedIndex = 0;
  /// Rol del usuario ('ADMINISTRADOR', 'ALUMNO'), extraído del token JWT.
  String? _userRole;
  /// Nombre del usuario para mostrar en el AppBar.
  String? _userName;
  /// ID del alumno, necesario para registrar asistencias.
  String? _alumnoId;

  /// Lista de widgets (pantallas) que se mostrarán según el rol del usuario.
  late final List<Widget> _pages;
  /// Lista de ítems para la barra de navegación inferior.
  late final List<BottomNavigationBarItem> _navBarItems;
  /// Títulos correspondientes a cada página para mostrar en el AppBar.
  late final List<String> _pageTitles;

  @override
  void initState() {
    super.initState();
    _initializeUser();
  }

  /// Inicializa los datos del usuario y la UI correspondiente a su rol.
  ///
  /// Decodifica el token JWT para obtener el rol y el ID del alumno.
  /// Basado en el rol, configura las listas `_pages`, `_navBarItems` y
  /// `_pageTitles` para personalizar la experiencia del usuario, ya sea
  /// como Administrador (con acceso a paneles) o como Alumno (con acceso
  /// al registro de asistencia).
  void _initializeUser() {
    try {
      AuthService.currentToken = widget.token;
      final Map<String, dynamic> payload = Jwt.parseJwt(widget.token);
      _userRole = payload['custom:rol'];

      _userName = widget.userProfile?['alumno']?['nombreCompleto']?.toString() ??
          payload['name'] ??
          'Usuario';

      // El ID del alumno lo podemos obtener del perfil o del token.
      _alumnoId = widget.userProfile?['alumnoId']?.toString() ?? 
          payload['custom:alumnoId'] ?? 
          payload['custom:id'];

      // Construimos la UI basada en el rol
      if (_userRole == 'ADMINISTRADOR') {
        _pages = const [
          PanelIncidenciasScreen(),
          PanelAdminUsuariosScreen(),
        ];
        _navBarItems = const [
          BottomNavigationBarItem(
            icon: Icon(Icons.warning_amber_rounded),
            activeIcon: Icon(Icons.warning_rounded),
            label: 'Incidencias',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.manage_accounts_outlined),
            activeIcon: Icon(Icons.manage_accounts),
            label: 'Admin Usuarios',
          ),
        ];
        _pageTitles = ['Control de Incidencias', 'Administrar Usuarios'];
      } else if (_userRole == 'ALUMNO') {
        // Solo mostramos la pantalla de asistencia si tenemos el ID del alumno.
        if (_alumnoId != null) {
          _pages = [
            RegistroAsistenciaScreen(
              alumnoId: _alumnoId!,
              alumnoNombre: _userName,
            ),
          ];
          _navBarItems = const [
            BottomNavigationBarItem(
              icon: Icon(Icons.check_circle_outline),
              label: 'Asistencia',
            ),
          ];
          _pageTitles = ['Registro de Asistencia'];
        } else {
          // Caso de error si el alumno no tiene un ID asociado
          _pages = [
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red),
                  SizedBox(height: 16),
                  Text('Error: No se encontró un ID de alumno\nasociado a esta cuenta.', textAlign: TextAlign.center),
                ],
              ),
            )
          ];
          _navBarItems = [const BottomNavigationBarItem(icon: Icon(Icons.error), label: 'Error')];
          _pageTitles = ['Error de Cuenta'];
        }
      } else {
        // Caso de error o rol no reconocido
        _pages = [const Center(child: Text('Rol no válido.'))];
        _navBarItems = [const BottomNavigationBarItem(icon: Icon(Icons.error), label: 'Error')];
        _pageTitles = ['Error'];
      }
    } catch (e) {
      // Si el token es inválido, regresamos al login.
      _logout();
    }
  }

  /// Cambia la pantalla visible al tocar un ítem de la barra de navegación.
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  /// Cierra la sesión del usuario.
  ///
  /// Limpia el token de autenticación y redirige al usuario a la [LoginScreen].
  void _logout() {
    AuthService.clearToken();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Muestra un indicador de carga mientras se procesa el rol del usuario.
    if (_userRole == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF1B396A))),
      );
    }

    // Colores institucionales
    const azulMarino = Color(0xFF1B396A);
    const grisFondo = Color(0xFFF8FAFC);

    return Scaffold(
      backgroundColor: grisFondo,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: azulMarino,
        foregroundColor: Colors.white,
        centerTitle: false,
        title: Text(
          _pageTitles[_selectedIndex],
          style: const TextStyle(
            fontWeight: FontWeight.bold, 
            fontSize: 18,
            letterSpacing: 0.5,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: PopupMenuButton<String>(
              offset: const Offset(0, 50), // Desplaza el menú ligeramente hacia abajo
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onSelected: (value) {
                if (value == 'logout') {
                  _logout();
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                PopupMenuItem<String>(
                  value: 'user_info',
                  enabled: false, 
                  child: Container(
                    padding: const EdgeInsets.only(bottom: 8),
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: const Color(0xFF1B396A).withOpacity(0.1),
                          foregroundColor: const Color(0xFF1B396A),
                          radius: 16,
                          child: Text(
                            _userName != null && _userName!.isNotEmpty ? _userName![0].toUpperCase() : 'U',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _userName ?? 'Usuario', 
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                _userRole == 'ADMINISTRADOR' ? 'Administrador' : 'Alumno',
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout, color: Colors.redAccent, size: 20),
                      SizedBox(width: 12),
                      Text('Cerrar Sesión', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
              // Icono principal del AppBar
              icon: CircleAvatar(
                backgroundColor: Colors.white24,
                radius: 18,
                child: Text(
                  _userName != null && _userName!.isNotEmpty ? _userName![0].toUpperCase() : 'U',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          ),
        ],
      ),
      body: _pages[_selectedIndex],
      // Menú de navegación inferior estilizado
      bottomNavigationBar: _navBarItems.length >= 2
          ? Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: BottomNavigationBar(
                backgroundColor: Colors.white,
                items: _navBarItems,
                currentIndex: _selectedIndex,
                onTap: _onItemTapped,
                selectedItemColor: azulMarino,
                unselectedItemColor: Colors.grey.shade500,
                selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
                elevation: 0,
                type: BottomNavigationBarType.fixed,
              ),
            )
          : null,
    );
  }
}