import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../services/sensitive_data_service.dart';
import '../services/session_service.dart';

class SessionProvider extends ChangeNotifier {
  bool _isLoggedIn = false;
  String _userEmail = '';
  String _userName = '';
  String _sessionToken = '';
  bool _isSessionWarning = false;
  int _warningSecondsRemaining = 0;

  // Estado de borrado remoto: true cuando se recibió una orden FCM de wipe
  bool _wasRemoteWiped = false;

  bool get isLoggedIn => _isLoggedIn;
  String get userEmail => _userEmail;
  String get userName => _userName;
  String get sessionToken => _sessionToken;
  bool get isSessionWarning => _isSessionWarning;
  int get warningSecondsRemaining => _warningSecondsRemaining;
  bool get wasRemoteWiped => _wasRemoteWiped;

  Future<String?> login(String email, String password) async {
    final result = await AuthService.login(email, password);

    if (result.success) {
      _isLoggedIn = true;
      _userEmail = email;
      _userName = result.userName!;
      _sessionToken = result.token!;
      _wasRemoteWiped = false;

      SessionService.instance.start(
        onExpired: _onSessionExpired,
        onWarning: _onSessionWarning,
      );

      // Registrar el callback de borrado remoto en el servicio de notificaciones.
      // Solo se ejecuta si la notificación llega con la app en foreground.
      NotificationService.onRemoteWipe = _handleRemoteWipe;

      notifyListeners();
      return null;
    }

    return result.errorMessage;
  }

  Future<String?> register({
    required String name,
    required String email,
    required String password,
  }) async {
    return AuthService.register(name: name, email: email, password: password);
  }

  Future<void> logout() async {
    SessionService.instance.stop();
    NotificationService.onRemoteWipe = null;
    await AuthService.logout();
    _clearState();
    notifyListeners();
  }

  void registerActivity() {
    SessionService.instance.registerActivity();
    if (_isSessionWarning) {
      _isSessionWarning = false;
      notifyListeners();
    }
  }

  void clearWipeFlag() {
    _wasRemoteWiped = false;
  }

  // Ejecuta el borrado remoto cuando la app está en FOREGROUND.
  // Verifica que el correo objetivo coincida con el usuario autenticado
  // antes de borrar, garantizando que la notificación es para este usuario.
  Future<void> _handleRemoteWipe(String targetEmail) async {
    final storedEmail = await SensitiveDataService.getStoredEmail();
    if (storedEmail == null || storedEmail != targetEmail) return;

    SessionService.instance.stop();
    NotificationService.onRemoteWipe = null;
    await SensitiveDataService.wipeAll();

    _wasRemoteWiped = true;
    _clearState();
    notifyListeners();
  }

  void _onSessionWarning(int secondsRemaining) {
    _isSessionWarning = true;
    _warningSecondsRemaining = secondsRemaining;
    notifyListeners();
  }

  Future<void> _onSessionExpired() async {
    NotificationService.onRemoteWipe = null;
    await AuthService.logout();
    _clearState();
    notifyListeners();
  }

  void _clearState() {
    _isLoggedIn = false;
    _userEmail = '';
    _userName = '';
    _sessionToken = '';
    _isSessionWarning = false;
    _warningSecondsRemaining = 0;
  }
}
