import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/session_service.dart';

/// Estado global de la sesión del usuario.
class SessionProvider extends ChangeNotifier {
  bool _isLoggedIn = false;
  String _userEmail = '';
  String _sessionToken = '';
  bool _isSessionWarning = false;
  int _warningSecondsRemaining = 0;

  bool get isLoggedIn => _isLoggedIn;
  String get userEmail => _userEmail;
  String get sessionToken => _sessionToken;

  /// True cuando la sesión está a punto de expirar (muestra advertencia en UI).
  bool get isSessionWarning => _isSessionWarning;

  /// Segundos restantes mostrados en la advertencia.
  int get warningSecondsRemaining => _warningSecondsRemaining;

  // Login
  Future<String?> login(String email, String password) async {
    final result = await AuthService.login(email, password);

    if (result.success) {
      _isLoggedIn = true;
      _userEmail = email;
      _sessionToken = result.token!;

      SessionService.instance.start(
        onExpired: _onSessionExpired, 
        onWarning: _onSessionWarning,
      );

      notifyListeners();
      return null;
    }

    return result.errorMessage;
  }


  Future<void> logout() async {
    SessionService.instance.stop();
    await AuthService.logout();
    _clearState();
    notifyListeners();
  }

  // Actividad

  /// Registra un toque/interacción del usuario.
  /// Reinicia el timer y oculta la advertencia si estaba visible.
  void registerActivity() {
    SessionService.instance.registerActivity();
    if (_isSessionWarning) {
      _isSessionWarning = false;
      notifyListeners();
    }
  }

  // Callbacks internos

  void _onSessionWarning(int secondsRemaining) {
    _isSessionWarning = true;
    _warningSecondsRemaining = secondsRemaining;
    notifyListeners();
  }

  Future<void> _onSessionExpired() async {
    await AuthService.logout();
    _clearState();
    notifyListeners();
  }

  void _clearState() {
    _isLoggedIn = false;
    _userEmail = '';
    _sessionToken = '';
    _isSessionWarning = false;
    _warningSecondsRemaining = 0;
  }
}
