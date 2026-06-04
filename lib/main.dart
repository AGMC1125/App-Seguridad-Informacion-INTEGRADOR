import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/providers/session_provider.dart';
import 'features/home/screens/home_screen.dart';
import 'screens/security_check_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(
    // ChangeNotifierProvider hace que SessionProvider esté disponible
    // en todo el árbol de widgets.
    ChangeNotifierProvider(
      create: (_) => SessionProvider(),
      child: const AprendIAApp(),
    ),
  );
}

class AprendIAApp extends StatelessWidget {
  const AprendIAApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AprendIA - LSM',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const _AppRoot(),
    );
  }
}

/// Raíz de la app: decide qué pantalla mostrar según el estado de sesión.
///
/// - Sin sesión activa → [SecurityCheckScreen] (que contiene el login)
/// - Con sesión activa → [_ActivityDetector] envolviendo [HomeScreen]
///
/// [Consumer] escucha cambios en [SessionProvider] y reconstruye
/// automáticamente cuando cambia [isLoggedIn] (login exitoso o logout).
class _AppRoot extends StatelessWidget {
  const _AppRoot();

  @override
  Widget build(BuildContext context) {
    return Consumer<SessionProvider>(
      builder: (context, session, _) {
        if (session.isLoggedIn) {
          // Envolver HomeScreen en el detector de actividad para
          // que cualquier toque reinicie el timer de inactividad.
          return _ActivityDetector(
            onActivity: session.registerActivity,
            child: const HomeScreen(),
          );
        }
        return const SecurityCheckScreen();
      },
    );
  }
}

/// Detector transparente de actividad del usuario.
///
/// Escucha cualquier evento de puntero (toque, arrastre, scroll) y
/// notifica al [SessionService] para reiniciar el countdown de inactividad.
class _ActivityDetector extends StatelessWidget {
  final Widget child;
  final VoidCallback onActivity;

  const _ActivityDetector({
    required this.child,
    required this.onActivity,
  });

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => onActivity(),
      onPointerMove: (_) => onActivity(),
      child: child,
    );
  }
}
