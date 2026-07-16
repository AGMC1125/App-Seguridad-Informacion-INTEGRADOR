import '../repositories/auth_repository.dart';

/// Caso de uso: cambiar la contraseña del usuario autenticado.
class ChangePasswordUseCase {
  final AuthRepository _repository;

  const ChangePasswordUseCase(this._repository);

  /// Lanza [AuthException] si la contraseña actual es incorrecta.
  Future<void> call({
    required String token,
    required String currentPassword,
    required String newPassword,
  }) {
    return _repository.changePassword(
      token: token,
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }
}
