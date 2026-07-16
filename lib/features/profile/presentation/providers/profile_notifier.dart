import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/session_notifier.dart';
import 'profile_state.dart';

/// Gestiona el estado de carga/error de las operaciones de perfil.
///
/// Las operaciones de negocio (updateProfile, changePassword, deleteAccount)
/// siguen viviendo en [SessionNotifier] porque modifican el estado de sesión.
/// Este notifier solo coordina el estado UI de cada operación (idle → loading
/// → success | error) sin duplicar la lógica de negocio.
class ProfileNotifier extends Notifier<ProfileState> {
  @override
  ProfileState build() => ProfileState.empty;

  // ── Guardar perfil ────────────────────────────────────────────────────────

  Future<void> saveProfile({required String name, required String email}) async {
    state = state.copyWith(
      saveProfileStatus: ProfileOperationStatus.loading,
      clearSaveProfileError: true,
    );

    final error = await ref
        .read(sessionNotifierProvider.notifier)
        .updateProfile(name: name, email: email);

    if (error == null) {
      state = state.copyWith(
        saveProfileStatus: ProfileOperationStatus.success,
      );
    } else {
      state = state.copyWith(
        saveProfileStatus: ProfileOperationStatus.error,
        saveProfileError: error,
      );
    }
  }

  // ── Cambiar contraseña ────────────────────────────────────────────────────

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    state = state.copyWith(
      changePasswordStatus: ProfileOperationStatus.loading,
      clearChangePasswordError: true,
    );

    final error = await ref
        .read(sessionNotifierProvider.notifier)
        .changePassword(currentPassword: currentPassword, newPassword: newPassword);

    if (error == null) {
      state = state.copyWith(
        changePasswordStatus: ProfileOperationStatus.success,
      );
    } else {
      state = state.copyWith(
        changePasswordStatus: ProfileOperationStatus.error,
        changePasswordError: error,
      );
    }
  }

  // ── Eliminar cuenta ───────────────────────────────────────────────────────

  Future<void> deleteAccount() async {
    state = state.copyWith(
      deleteAccountStatus: ProfileOperationStatus.loading,
      clearDeleteAccountError: true,
    );

    final error = await ref
        .read(sessionNotifierProvider.notifier)
        .deleteAccount();

    if (error != null) {
      state = state.copyWith(
        deleteAccountStatus: ProfileOperationStatus.error,
        deleteAccountError: error,
      );
    }
    // Si tuvo éxito, SessionNotifier llama _clearState() → SessionGuard redirige
    // al login automáticamente. No cambiamos estado aquí porque el widget ya
    // no estará montado cuando regrese.
  }

  // ── Reset ─────────────────────────────────────────────────────────────────

  /// Resetea todos los estados a idle. Llamar en dispose() del widget.
  void reset() => state = ProfileState.empty;
}

final profileNotifierProvider =
    NotifierProvider<ProfileNotifier, ProfileState>(ProfileNotifier.new);
