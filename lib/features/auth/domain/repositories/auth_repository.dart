import '../entities/user_session.dart';

/// Contrato (interfaz) del repositorio de autenticación.
///
/// La capa de dominio solo conoce este contrato — nunca la implementación
/// concreta que vive en la capa de datos.
abstract class AuthRepository {
  /// Autentica al usuario y devuelve su sesión.
  /// Lanza [AuthException] si las credenciales son inválidas.
  Future<UserSession> login(String email, String password);

  /// Registra un nuevo usuario.
  /// Lanza [AuthException] si el correo ya existe u ocurre otro error.
  Future<void> register({
    required String name,
    required String email,
    required String password,
  });

  /// Cierra sesión y limpia todos los datos locales.
  Future<void> logout();

  /// Actualiza el perfil del usuario autenticado.
  /// Devuelve la sesión actualizada con el nuevo nombre/correo.
  Future<UserSession> updateProfile({
    required String currentToken,
    String? name,
    String? email,
  });

  /// Cambia la contraseña del usuario autenticado.
  /// Lanza [AuthException] si la contraseña actual es incorrecta.
  Future<void> changePassword({
    required String token,
    required String currentPassword,
    required String newPassword,
  });

  /// Elimina la cuenta del usuario (soft-delete) y cierra sesión local.
  Future<void> deleteAccount({required String token});
}

/// Excepción de dominio para errores de autenticación.
///
/// Desacopla la capa de presentación de los errores HTTP concretos:
/// la pantalla solo ve un mensaje de error entendible, no un código de estado.
class AuthException implements Exception {
  final String message;
  const AuthException(this.message);

  @override
  String toString() => message;
}
