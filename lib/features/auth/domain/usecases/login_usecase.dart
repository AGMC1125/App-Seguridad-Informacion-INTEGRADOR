import '../entities/user_session.dart';
import '../repositories/auth_repository.dart';

/// Caso de uso: autenticar usuario con email y contraseña.
///
/// Responsabilidad única: delegar la operación de login al repositorio.
/// No sabe cómo se hace la petición HTTP ni cómo se guarda el token.
class LoginUseCase {
  final AuthRepository _repository;

  const LoginUseCase(this._repository);

  /// Lanza [AuthException] si las credenciales son inválidas.
  Future<UserSession> call(String email, String password) {
    return _repository.login(email, password);
  }
}
