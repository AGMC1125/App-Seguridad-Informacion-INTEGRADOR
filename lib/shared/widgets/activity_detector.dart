import 'package:flutter/material.dart';

/// Widget que detecta cualquier interacción del usuario en la pantalla.
///
/// Responsabilidad única: escuchar eventos de puntero (toques y movimientos)
/// y notificarlos al callback [onActivity].
///
/// Se usa para reiniciar el timer de inactividad de sesión cada vez que
/// el usuario interactúa con la app.
class ActivityDetector extends StatelessWidget {
  final Widget child;
  final VoidCallback onActivity;

  const ActivityDetector({
    super.key,
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
