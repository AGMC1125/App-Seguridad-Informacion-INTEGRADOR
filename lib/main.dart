import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/providers/session_provider.dart';
import 'core/services/notification_service.dart';
import 'features/home/screens/home_screen.dart';
import 'screens/security_check_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await NotificationService().initialize();

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
      title: 'VirtualSign LSM',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,   // sigue el modo claro/oscuro del dispositivo
      home: const _AppRoot(),
    );
  }
}

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

    // Mostrar banner cuando el borrado remoto se ejecutó en foreground
    if (!session.isLoggedIn && session.wasRemoteWiped) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.delete_forever, color: Colors.white),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Borrado remoto ejecutado. Todos los datos sensibles han sido eliminados.',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFFB71C1C),
            duration: const Duration(seconds: 6),
          ),
        );
        session.clearWipeFlag();
      });
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
