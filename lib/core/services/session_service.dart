import 'dart:async';
import '../constants/app_constants.dart';
import 'encrypted_storage_service.dart';

/// Callback cuando la sesión expira por inactividad.
typedef OnSessionExpired = void Function();

/// Callback cuando la sesión está a punto de expirar.
/// Recibe los segundos restantes para que la UI pueda mostrarlos.
typedef OnSessionWarning = void Function(int secondsRemaining);

/// Servicio de sesión: controla el timer de inactividad.
///
/// Dispara [OnSessionWarning] cuando faltan [AppConstants.sessionWarningBefore]
/// segundos para el cierre, y [OnSessionExpired] cuando el tiempo se agota.
class SessionService {
  SessionService._();
  static final SessionService instance = SessionService._();

  Timer? _inactivityTimer;
  Timer? _warningTimer;
  OnSessionExpired? _onExpired;
  OnSessionWarning? _onWarning;
  bool _isRunning = false;

  // Control del servicio

  /// Inicia el monitoreo de inactividad.
  void start({
    required OnSessionExpired onExpired,
    OnSessionWarning? onWarning,
  }) {
    _onExpired = onExpired;
    _onWarning = onWarning;
    _isRunning = true;
    _resetTimers();
  }

  /// Detiene el monitoreo.
  void stop() {
    _inactivityTimer?.cancel();
    _warningTimer?.cancel();
    _inactivityTimer = null;
    _warningTimer = null;
    _isRunning = false;
    _onExpired = null;
    _onWarning = null;
  }

  /// Registra actividad del usuario y reinicia el countdown.
  void registerActivity() {
    if (!_isRunning) return;
    _resetTimers();
    _persistLastActivity();
  }

  bool get isRunning => _isRunning;

  // Privado

  void _resetTimers() {
    _inactivityTimer?.cancel();
    _warningTimer?.cancel();

    final warningDelay =
        AppConstants.sessionTimeout - AppConstants.sessionWarningBefore;

    // Timer de advertencia: se dispara antes del cierre
    if (warningDelay > Duration.zero && _onWarning != null) {
      _warningTimer = Timer(warningDelay, () {
        _onWarning!(AppConstants.sessionWarningBefore.inSeconds);
      });
    }

    // Timer de cierre de sesión
    _inactivityTimer = Timer(AppConstants.sessionTimeout, _onTimeout);
  }

  void _onTimeout() {
    _isRunning = false;
    _warningTimer?.cancel();
    _persistSessionExpiry();
    _onExpired?.call();
  }

  Future<void> _persistLastActivity() async {
    await EncryptedStorageService.write(
      key: AppConstants.storageKeyLastActivity,
      value: DateTime.now().toIso8601String(),
    );
  }

  Future<void> _persistSessionExpiry() async {
    await EncryptedStorageService.write(
      key: AppConstants.storageKeyLastActivity,
      value: DateTime.now().toIso8601String(),
    );
  }
}
