/// Estados posibles para cada operación de perfil.
enum ProfileOperationStatus { idle, loading, success, error }

/// Estado inmutable de la pantalla de perfil.
///
/// Cada operación (guardar perfil, cambiar contraseña, eliminar cuenta)
/// tiene su propio [ProfileOperationStatus] y mensaje de error independiente,
/// lo que permite que las secciones de la pantalla reaccionen por separado.
class ProfileState {
  final ProfileOperationStatus saveProfileStatus;
  final ProfileOperationStatus changePasswordStatus;
  final ProfileOperationStatus deleteAccountStatus;
  final String? saveProfileError;
  final String? changePasswordError;
  final String? deleteAccountError;

  const ProfileState({
    this.saveProfileStatus = ProfileOperationStatus.idle,
    this.changePasswordStatus = ProfileOperationStatus.idle,
    this.deleteAccountStatus = ProfileOperationStatus.idle,
    this.saveProfileError,
    this.changePasswordError,
    this.deleteAccountError,
  });

  static const empty = ProfileState();

  // Shortcuts de conveniencia
  bool get isSavingProfile => saveProfileStatus == ProfileOperationStatus.loading;
  bool get isChangingPassword => changePasswordStatus == ProfileOperationStatus.loading;
  bool get isDeletingAccount => deleteAccountStatus == ProfileOperationStatus.loading;

  ProfileState copyWith({
    ProfileOperationStatus? saveProfileStatus,
    ProfileOperationStatus? changePasswordStatus,
    ProfileOperationStatus? deleteAccountStatus,
    String? saveProfileError,
    bool clearSaveProfileError = false,
    String? changePasswordError,
    bool clearChangePasswordError = false,
    String? deleteAccountError,
    bool clearDeleteAccountError = false,
  }) {
    return ProfileState(
      saveProfileStatus: saveProfileStatus ?? this.saveProfileStatus,
      changePasswordStatus: changePasswordStatus ?? this.changePasswordStatus,
      deleteAccountStatus: deleteAccountStatus ?? this.deleteAccountStatus,
      saveProfileError:
          clearSaveProfileError ? null : saveProfileError ?? this.saveProfileError,
      changePasswordError:
          clearChangePasswordError ? null : changePasswordError ?? this.changePasswordError,
      deleteAccountError:
          clearDeleteAccountError ? null : deleteAccountError ?? this.deleteAccountError,
    );
  }
}
