import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/session_service.dart';

/// Estado global de la sesión del usuario.
///
/// Expone:
/// - [isLoggedIn]: si hay sesión activa
/// - [userEmail]: correo del usuario autenticado
/// - [sessionToken]: token guardado en storage encriptado
///
/// La UI escucha cambios vía [ChangeNotifier] (Provider).
class SessionProvider extends ChangeNotifier {
  bool _isLoggedIn = false;
  String _userEmail = '';
  String _sessionToken = '';

  bool get isLoggedIn => _isLoggedIn;
  String get userEmail => _userEmail;
  String get sessionToken => _sessionToken;

  // -------------------------------------------------------------------------
  // Login
  // -------------------------------------------------------------------------

  /// Intenta autenticar al usuario. Si es exitoso, inicia el timer de
  /// inactividad y notifica a los widgets que escuchan.
  Future<String?> login(String email, String password) async {
    final result = await AuthService.login(email, password);

    if (result.success) {
      _isLoggedIn = true;
      _userEmail = email;
      _sessionToken = result.token!;

      // Iniciar monitoreo de inactividad
      SessionService.instance.start(
        onExpired: () => _onSessionExpired(),
      );

      notifyListeners();
      return null; // null = sin error
    }

    return result.errorMessage;
  }

  // -------------------------------------------------------------------------
  // Logout
  // -------------------------------------------------------------------------

  /// Cierra sesión manualmente (botón de logout).
  Future<void> logout() async {
    SessionService.instance.stop();
    await AuthService.logout();
    _clearState();
    notifyListeners();
  }

  /// Registra actividad del usuario para reiniciar el timer de inactividad.
  void registerActivity() {
    SessionService.instance.registerActivity();
  }

  // -------------------------------------------------------------------------
  // Privado
  // -------------------------------------------------------------------------

  /// Llamado automáticamente cuando el timer de inactividad expira.
  Future<void> _onSessionExpired() async {
    await AuthService.logout();
    _clearState();
    notifyListeners(); // La UI reacciona y redirige al login
  }

  void _clearState() {
    _isLoggedIn = false;
    _userEmail = '';
    _sessionToken = '';
  }
}
