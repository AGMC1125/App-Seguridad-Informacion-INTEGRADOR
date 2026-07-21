import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/widgets/activity_detector.dart';
import '../providers/session_notifier.dart';

/// Widget guardián de sesión — shell de rutas autenticadas.
///
/// Responsabilidad única: envolver todas las pantallas autenticadas con
/// [ActivityDetector] y reaccionar a eventos de sesión (advertencia de
/// inactividad y borrado remoto) mostrando los [SnackBar] correspondientes.
///
/// La decisión de QUÉ pantalla mostrar ya no vive aquí — el redirect de
/// [GoRouter] en [appRouterProvider] es el único responsable de esa lógica.
///
/// Este widget se inyecta automáticamente en todas las rutas protegidas
/// mediante el [ShellRoute] definido en [appRouterProvider].
class SessionGuard extends ConsumerStatefulWidget {
  /// Pantalla activa entregada por el ShellRoute de GoRouter.
  final Widget child;

  const SessionGuard({super.key, required this.child});

  @override
  ConsumerState<SessionGuard> createState() => _SessionGuardState();
}

class _SessionGuardState extends ConsumerState<SessionGuard> {
  ScaffoldFeatureController? _warningSnackBar;

  @override
  Widget build(BuildContext context) {
    // Reacciona a cambios puntuales de estado sin reconstruir el árbol completo
    ref.listen<SessionState>(sessionNotifierProvider, (previous, next) {
      _handleSessionWarning(next);
      _handleRemoteWipeNotification(next);
    });

    return ActivityDetector(
      onActivity: ref.read(sessionNotifierProvider.notifier).registerActivity,
      child: widget.child,
    );
  }

  // ── Manejo de advertencia de sesión por inactividad ───────────────────────

  void _handleSessionWarning(SessionState session) {
    if (session.isSessionWarning && _warningSnackBar == null) {
      _showWarningSnackBar(session.warningSecondsRemaining);
    }
    if (!session.isSessionWarning) {
      _warningSnackBar?.close();
      _warningSnackBar = null;
    }
  }

  void _showWarningSnackBar(int secondsRemaining) {
    _warningSnackBar = ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.timer_outlined, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Tu sesión cerrará en $secondsRemaining segundos por inactividad.',
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFE65100),
        duration: Duration(seconds: secondsRemaining),
        action: SnackBarAction(
          label: 'Continuar',
          textColor: Colors.white,
          onPressed: () =>
              ref.read(sessionNotifierProvider.notifier).registerActivity(),
        ),
      ),
    );
    _warningSnackBar?.closed.then((_) => _warningSnackBar = null);
  }

  // ── Manejo de borrado remoto vía FCM ─────────────────────────────────────

  void _handleRemoteWipeNotification(SessionState session) {
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
        ref.read(sessionNotifierProvider.notifier).clearWipeFlag();
      });
    }
  }
}
