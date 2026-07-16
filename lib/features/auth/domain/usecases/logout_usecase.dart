import '../repositories/auth_repository.dart';

/// Caso de uso: cerrar sesión del usuario.
class LogoutUseCase {
  final AuthRepository _repository;

  const LogoutUseCase(this._repository);

  Future<void> call() => _repository.logout();
}
