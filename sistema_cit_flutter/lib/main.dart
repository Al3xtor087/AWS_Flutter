import 'dart:io';
import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

void main() {
  // ADVERTENCIA: Esto es inseguro para producción. Solo para desarrollo.

  HttpOverrides.global = MiAnuladorDeCertificados();

  runApp(const PanelIncidencias());
}

class PanelIncidencias extends StatelessWidget {
  const PanelIncidencias({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Sistema CIT Incidencias",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1B396A)),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}

class MiAnuladorDeCertificados extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) {
        return true;
      };
  }
}
