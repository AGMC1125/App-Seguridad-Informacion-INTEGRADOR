import '../repositories/auth_repository.dart';

/// Caso de uso: eliminar la cuenta del usuario (soft-delete).
class DeleteAccountUseCase {
  final AuthRepository _repository;

  const DeleteAccountUseCase(this._repository);

  Future<void> call({required String token}) {
    return _repository.deleteAccount(token: token);
  }
}
