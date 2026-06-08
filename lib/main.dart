import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/providers/session_provider.dart';
import 'features/home/screens/home_screen.dart';
import 'screens/security_check_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(
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

/// Raíz de la app: decide qué pantalla mostrar según el estado de sesión
/// y gestiona el SnackBar de advertencia de inactividad.
class _AppRoot extends StatefulWidget {
  const _AppRoot();

  @override
  State<_AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<_AppRoot> {
  ScaffoldFeatureController? _warningSnackBar;

  @override
  void initState() {
    super.initState();
    // Escuchar cambios del SessionProvider para reaccionar
    // al estado de advertencia sin reconstruir todo el árbol.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SessionProvider>().addListener(_onSessionChanged);
    });
  }

  @override
  void dispose() {
    context.read<SessionProvider>().removeListener(_onSessionChanged);
    super.dispose();
  }

  void _onSessionChanged() {
    final session = context.read<SessionProvider>();

    if (session.isSessionWarning && _warningSnackBar == null) {
      _showWarningSnackBar(session);
    }

    if (!session.isSessionWarning) {
      _warningSnackBar?.close();
      _warningSnackBar = null;
    }
  }

  void _showWarningSnackBar(SessionProvider session) {
    _warningSnackBar = ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.timer_outlined, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Tu sesión cerrará en ${session.warningSecondsRemaining} segundos por inactividad.',
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFE65100),
        duration: Duration(seconds: session.warningSecondsRemaining),
        action: SnackBarAction(
          label: 'Continuar',
          textColor: Colors.white,
          onPressed: () {
            session.registerActivity();
          },
        ),
      ),
    );

    // Limpiar la referencia cuando el SnackBar se cierre solo
    _warningSnackBar?.closed.then((_) => _warningSnackBar = null);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SessionProvider>(
      builder: (context, session, _) {
        if (session.isLoggedIn) {
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
/// Cualquier toque o arrastre reinicia el timer de inactividad.
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
