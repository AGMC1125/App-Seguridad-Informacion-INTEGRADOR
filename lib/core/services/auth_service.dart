import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';
import '../constants/app_constants.dart';

/// Resultado de un intento de inicio de sesión.
class LoginResult {
  final bool success;
  final String? token;
  final String? errorMessage;

  const LoginResult._({
    required this.success,
    this.token,
    this.errorMessage,
  });

  factory LoginResult.success(String token) =>
      LoginResult._(success: true, token: token);

  factory LoginResult.failure(String message) =>
      LoginResult._(success: false, errorMessage: message);
}

/// Servicio de autenticación.
///
/// Actualmente usa credenciales mock (cualquier correo/contraseña válidos
/// conceden acceso). Preparado para reemplazar [_validateCredentials] con
/// una llamada real a backend sin tocar el resto de la app.
class AuthService {
  AuthService._();

  static const _storage = FlutterSecureStorage();
  static const _uuid = Uuid();

  // -------------------------------------------------------------------------
  // Login / Logout
  // -------------------------------------------------------------------------

  /// Intenta iniciar sesión con [email] y [password].
  ///
  /// Genera un token UUID mock y lo persiste junto con el timestamp de login
  /// en el almacén encriptado del dispositivo.
  static Future<LoginResult> login(String email, String password) async {
    // Validación básica de formato
    if (!_validateCredentials(email, password)) {
      return LoginResult.failure('Credenciales inválidas.');
    }

    // Generar token mock (en producción vendría del backend)
    final token = _uuid.v4();
    final loginTime = DateTime.now().toIso8601String();

    // Persistir en almacén encriptado
    await _storage.write(key: AppConstants.storageKeyToken, value: token);
    await _storage.write(key: AppConstants.storageKeyLoginTime, value: loginTime);
    await _storage.write(
      key: AppConstants.storageKeyLastActivity,
      value: loginTime,
    );

    return LoginResult.success(token);
  }

  /// Cierra la sesión del usuario y elimina los datos encriptados.
  static Future<void> logout() async {
    await _storage.delete(key: AppConstants.storageKeyToken);
    await _storage.delete(key: AppConstants.storageKeyLoginTime);
    await _storage.delete(key: AppConstants.storageKeyLastActivity);
  }

  /// Verifica si existe una sesión activa guardada.
  static Future<bool> hasActiveSession() async {
    final token = await _storage.read(key: AppConstants.storageKeyToken);
    return token != null && token.isNotEmpty;
  }

  /// Retorna el token de sesión almacenado, o null si no hay sesión.
  static Future<String?> getToken() async {
    return _storage.read(key: AppConstants.storageKeyToken);
  }

  // -------------------------------------------------------------------------
  // Privado
  // -------------------------------------------------------------------------

  /// Validación mock: acepta cualquier correo con '@' y contraseña >= 8 chars.
  /// Reemplazar con llamada a API cuando haya backend.
  static bool _validateCredentials(String email, String password) {
    return email.contains('@') && password.length >= 8;
  }
}
