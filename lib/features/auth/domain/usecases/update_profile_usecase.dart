import '../entities/user_session.dart';
import '../repositories/auth_repository.dart';

/// Caso de uso: actualizar nombre y/o correo del perfil de usuario.
class UpdateProfileUseCase {
  final AuthRepository _repository;

  const UpdateProfileUseCase(this._repository);

  /// Lanza [AuthException] si el token expiró o los datos son inválidos.
  Future<UserSession> call({
    required String token,
    String? name,
    String? email,
  }) {
    return _repository.updateProfile(
      currentToken: token,
      name: name,
      email: email,
    );
  }
}
