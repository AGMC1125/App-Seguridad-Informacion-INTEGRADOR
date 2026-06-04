import 'dart:async';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';

/// Callback que se ejecuta cuando la sesión expira por inactividad.
typedef OnSessionExpired = void Function();

/// Servicio de sesión: controla el timer de inactividad.
///
/// Cada vez que el usuario interactúa con la app se llama [registerActivity],
/// lo que reinicia el countdown. Si pasa [AppConstants.sessionTimeout] sin
/// actividad, se invoca [onExpired] y el estado se persiste en almacén
/// encriptado.
///
/// Uso:
/// ```dart
/// SessionService.instance.start(onExpired: () => _logout());
/// SessionService.instance.registerActivity();
/// SessionService.instance.stop();
/// ```
class SessionService {
  SessionService._();
  static final SessionService instance = SessionService._();

  static const _storage = FlutterSecureStorage();

  Timer? _inactivityTimer;
  OnSessionExpired? _onExpired;
  bool _isRunning = false;

  // -------------------------------------------------------------------------
  // Control del servicio
  // -------------------------------------------------------------------------

  /// Inicia el monitoreo de inactividad.
  /// [onExpired] se llama cuando el usuario supera el timeout sin interactuar.
  void start({required OnSessionExpired onExpired}) {
    _onExpired = onExpired;
    _isRunning = true;
    _resetTimer();
  }

  /// Detiene el monitoreo. Llamar al hacer logout manual o al cerrar la app.
  void stop() {
    _inactivityTimer?.cancel();
    _inactivityTimer = null;
    _isRunning = false;
    _onExpired = null;
  }

  /// Registra que el usuario realizó una acción (tap, scroll, tecleo, etc.).
  /// Reinicia el countdown de inactividad y actualiza el timestamp encriptado.
  void registerActivity() {
    if (!_isRunning) return;
    _resetTimer();
    _persistLastActivity();
  }

  bool get isRunning => _isRunning;

  // -------------------------------------------------------------------------
  // Privado
  // -------------------------------------------------------------------------

  void _resetTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(AppConstants.sessionTimeout, _onTimeout);
  }

  void _onTimeout() {
    _isRunning = false;
    _persistSessionExpiry();
    _onExpired?.call();
  }

  Future<void> _persistLastActivity() async {
    await _storage.write(
      key: AppConstants.storageKeyLastActivity,
      value: DateTime.now().toIso8601String(),
    );
  }

  Future<void> _persistSessionExpiry() async {
    await _storage.write(
      key: AppConstants.storageKeyLastActivity,
      value: DateTime.now().toIso8601String(),
    );
  }
}
