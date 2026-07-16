import '../../domain/entities/user_session.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

/// Implementación concreta del [AuthRepository].
///
/// Coordina entre el datasource remoto y la entidad de dominio.
/// Es el único lugar que conoce tanto el contrato de dominio como
/// los detalles de la fuente de datos.
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;

  const AuthRepositoryImpl(this._remoteDataSource);

  @override
  Future<UserSession> login(String email, String password) async {
    final model = await _remoteDataSource.login(email, password);
    return model.toEntity();
  }

  @override
  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) {
    return _remoteDataSource.register(
      name: name,
      email: email,
      password: password,
    );
  }

  @override
  Future<void> logout() => _remoteDataSource.clearLocalSession();

  @override
  Future<UserSession> updateProfile({
    required String currentToken,
    String? name,
    String? email,
  }) async {
    final data = await _remoteDataSource.updateProfile(
      token: currentToken,
      name: name,
      email: email,
    );
    // La API devuelve los campos actualizados; reconstruimos la sesión
    return UserSession(
      token: currentToken,
      userName: data['name'] as String? ?? name ?? '',
      userEmail: data['email'] as String? ?? email ?? '',
    );
  }

  @override
  Future<void> changePassword({
    required String token,
    required String currentPassword,
    required String newPassword,
  }) {
    return _remoteDataSource.changePassword(
      token: token,
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }

  @override
  Future<void> deleteAccount({required String token}) {
    return _remoteDataSource.deleteAccount(token: token);
  }
}
