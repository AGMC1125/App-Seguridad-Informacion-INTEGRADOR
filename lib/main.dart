import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/services/notification_service.dart';

/// Punto de entrada de la aplicación.
///
/// Responsabilidad única: inicializar servicios de plataforma y arrancar Flutter.
/// Toda la lógica de UI, rutas y sesión vive en [AprendIAApp] y sus descendientes.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await NotificationService().initialize();

  runApp(
    const ProviderScope(
      child: AprendIAApp(),
    ),
  );
}
