import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/auth/presentation/widgets/session_guard.dart';
import 'theme/app_theme.dart';

/// Raíz de la aplicación Flutter.
///
/// Responsabilidad única: configurar [MaterialApp] con tema, modo oscuro
/// y delegar la decisión de qué pantalla mostrar a [SessionGuard].
///
/// Toda la lógica de sesión, seguridad y bootstrap ya ocurre antes de
/// que este widget sea construido — en [main.dart].
class AprendIAApp extends ConsumerWidget {
  const AprendIAApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'VirtualSign LSM',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const SessionGuard(),
    );
  }
}
