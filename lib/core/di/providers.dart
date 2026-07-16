import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/change_password_usecase.dart';
import '../../features/auth/domain/usecases/delete_account_usecase.dart';
import '../../features/auth/domain/usecases/login_usecase.dart';
import '../../features/auth/domain/usecases/logout_usecase.dart';
import '../../features/auth/domain/usecases/register_usecase.dart';
import '../../features/auth/domain/usecases/update_profile_usecase.dart';

// ── Capa de datos ─────────────────────────────────────────────────────────────

/// Fuente de datos remota de autenticación.
/// Se declara como [Provider] porque [AuthRemoteDataSource] no tiene estado.
final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>(
  (ref) => const AuthRemoteDataSource(),
);

// ── Repositorio ───────────────────────────────────────────────────────────────

/// Implementación del contrato de dominio [AuthRepository].
/// Depende de [authRemoteDataSourceProvider] — Riverpod inyecta la dependencia.
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(ref.read(authRemoteDataSourceProvider)),
);

// ── Casos de uso ──────────────────────────────────────────────────────────────

/// Caso de uso: iniciar sesión.
final loginUseCaseProvider = Provider<LoginUseCase>(
  (ref) => LoginUseCase(ref.read(authRepositoryProvider)),
);

/// Caso de uso: cerrar sesión.
final logoutUseCaseProvider = Provider<LogoutUseCase>(
  (ref) => LogoutUseCase(ref.read(authRepositoryProvider)),
);

/// Caso de uso: registrar nuevo usuario.
final registerUseCaseProvider = Provider<RegisterUseCase>(
  (ref) => RegisterUseCase(ref.read(authRepositoryProvider)),
);

/// Caso de uso: actualizar perfil (nombre / correo).
final updateProfileUseCaseProvider = Provider<UpdateProfileUseCase>(
  (ref) => UpdateProfileUseCase(ref.read(authRepositoryProvider)),
);

/// Caso de uso: cambiar contraseña.
final changePasswordUseCaseProvider = Provider<ChangePasswordUseCase>(
  (ref) => ChangePasswordUseCase(ref.read(authRepositoryProvider)),
);

/// Caso de uso: eliminar cuenta.
final deleteAccountUseCaseProvider = Provider<DeleteAccountUseCase>(
  (ref) => DeleteAccountUseCase(ref.read(authRepositoryProvider)),
);
