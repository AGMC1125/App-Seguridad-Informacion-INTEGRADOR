import '../repositories/auth_repository.dart';

/// Caso de uso: registrar un nuevo usuario.
class RegisterUseCase {
  final AuthRepository _repository;

  const RegisterUseCase(this._repository);

  /// Lanza [AuthException] si el correo ya está en uso.
  Future<void> call({
    required String name,
    required String email,
    required String password,
  }) {
    return _repository.register(name: name, email: email, password: password);
  }
}
