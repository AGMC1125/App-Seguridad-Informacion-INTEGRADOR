import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/sensitive_data_service.dart';
import '../../../../core/services/session_service.dart';
import '../../../../core/di/providers.dart';
import '../../domain/entities/auth_status.dart';
import '../../domain/repositories/auth_repository.dart';

// ── Estado de sesión ──────────────────────────────────────────────────────────

/// Representa el estado completo de la sesión del usuario.
///
/// Inmutable: cualquier cambio produce una nueva instancia vía [copyWith].
class SessionState {
  final bool isLoggedIn;
  final String token;
  final String userName;
  final String userEmail;
  final bool isSessionWarning;
  final int warningSecondsRemaining;
  final bool wasRemoteWiped;

  // ── Auth operation status ─────────────────────────────────────────────────
  /// Estado de la última operación de autenticación (login / register).
  final AuthStatus authStatus;

  /// Mensaje de error cuando [authStatus] == [AuthStatus.error]. Null en otros casos.
  final String? authError;

  const SessionState({
    this.isLoggedIn = false,
    this.token = '',
    this.userName = '',
    this.userEmail = '',
    this.isSessionWarning = false,
    this.warningSecondsRemaining = 0,
    this.wasRemoteWiped = false,
    this.authStatus = AuthStatus.idle,
    this.authError,
  });

  SessionState copyWith({
    bool? isLoggedIn,
    String? token,
    String? userName,
    String? userEmail,
    bool? isSessionWarning,
    int? warningSecondsRemaining,
    bool? wasRemoteWiped,
    AuthStatus? authStatus,
    // Usar clearAuthError: true para forzar null explícitamente en copyWith.
    String? authError,
    bool clearAuthError = false,
  }) {
    return SessionState(
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      token: token ?? this.token,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      isSessionWarning: isSessionWarning ?? this.isSessionWarning,
      warningSecondsRemaining:
          warningSecondsRemaining ?? this.warningSecondsRemaining,
      wasRemoteWiped: wasRemoteWiped ?? this.wasRemoteWiped,
      authStatus: authStatus ?? this.authStatus,
      authError: clearAuthError ? null : (authError ?? this.authError),
    );
  }

  /// Estado limpio (sin sesión activa).
  static const empty = SessionState();
}

// ── Notifier ──────────────────────────────────────────────────────────────────

/// Gestor de estado de sesión usando Riverpod.
///
/// Responsabilidad única: coordinar el ciclo de vida de la sesión del usuario.
/// - Delega operaciones de datos a los use cases correspondientes.
/// - Gestiona el timer de inactividad vía [SessionService].
/// - Registra el callback de borrado remoto en [NotificationService].
/// - Emite [AuthStatus] en [SessionState.authStatus] para que la UI reaccione
///   sin lógica propia (idle → loading → success | error).
///
/// NO contiene lógica HTTP ni de almacenamiento — eso vive en la capa de datos.
class SessionNotifier extends Notifier<SessionState> {
  AuthRepository get _authRepository => ref.read(authRepositoryProvider);

  @override
  SessionState build() => SessionState.empty;

  // ── Autenticación ─────────────────────────────────────────────────────────

  /// Autentica al usuario.
  ///
  /// Emite [AuthStatus.loading] → [AuthStatus.success] | [AuthStatus.error].
  /// La UI observa [SessionState.authStatus] y [SessionState.authError];
  /// no necesita lógica de manejo de resultado en el widget.
  Future<void> login(String email, String password) async {
    state = state.copyWith(
      authStatus: AuthStatus.loading,
      clearAuthError: true,
    );

    try {
      final session =
          await ref.read(loginUseCaseProvider).call(email, password);

      state = state.copyWith(
        isLoggedIn: true,
        token: session.token,
        userName: session.userName,
        userEmail: session.userEmail,
        wasRemoteWiped: false,
        authStatus: AuthStatus.success,
        clearAuthError: true,
      );

      // Iniciar timer de inactividad
      SessionService.instance.start(
        onExpired: _onSessionExpired,
        onWarning: _onSessionWarning,
      );

      // Registrar callback de borrado remoto (FCM foreground)
      NotificationService.onRemoteWipe = _handleRemoteWipe;
    } on AuthException catch (e) {
      state = state.copyWith(
        authStatus: AuthStatus.error,
        authError: e.message,
      );
    }
  }

  /// Registra un nuevo usuario.
  ///
  /// Emite [AuthStatus.loading] → [AuthStatus.success] | [AuthStatus.error].
  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    state = state.copyWith(
      authStatus: AuthStatus.loading,
      clearAuthError: true,
    );

    try {
      await ref
          .read(registerUseCaseProvider)
          .call(name: name, email: email, password: password);

      state = state.copyWith(
        authStatus: AuthStatus.success,
        clearAuthError: true,
      );
    } on AuthException catch (e) {
      state = state.copyWith(
        authStatus: AuthStatus.error,
        authError: e.message,
      );
    }
  }

  /// Cierra la sesión del usuario.
  Future<void> logout() async {
    SessionService.instance.stop();
    NotificationService.onRemoteWipe = null;
    await ref.read(logoutUseCaseProvider).call();
    state = SessionState.empty;
  }

  // ── Perfil ────────────────────────────────────────────────────────────────

  /// Actualiza nombre y/o correo del perfil. Devuelve error o null.
  Future<String?> updateProfile({String? name, String? email}) async {
    try {
      final updatedSession = await ref.read(updateProfileUseCaseProvider).call(
            token: state.token,
            name: name,
            email: email,
          );
      state = state.copyWith(
        userName: updatedSession.userName,
        userEmail: updatedSession.userEmail,
      );
      return null;
    } on AuthException catch (e) {
      return e.message;
    }
  }

  /// Cambia la contraseña. Devuelve error o null.
  Future<String?> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await ref.read(changePasswordUseCaseProvider).call(
            token: state.token,
            currentPassword: currentPassword,
            newPassword: newPassword,
          );
      return null;
    } on AuthException catch (e) {
      return e.message;
    }
  }

  /// Elimina la cuenta y cierra sesión. Devuelve error o null.
  Future<String?> deleteAccount() async {
    try {
      await ref.read(deleteAccountUseCaseProvider).call(token: state.token);
      SessionService.instance.stop();
      NotificationService.onRemoteWipe = null;
      state = SessionState.empty;
      return null;
    } on AuthException catch (e) {
      return e.message;
    }
  }

  // ── Actividad del usuario ─────────────────────────────────────────────────

  /// Registra actividad del usuario y reinicia el timer de inactividad.
  void registerActivity() {
    SessionService.instance.registerActivity();
    if (state.isSessionWarning) {
      state = state.copyWith(isSessionWarning: false);
    }
  }

  /// Limpia la bandera de borrado remoto tras mostrar el aviso en UI.
  void clearWipeFlag() {
    state = state.copyWith(wasRemoteWiped: false);
  }

  /// Resetea [authStatus] a [AuthStatus.idle] y limpia [authError].
  ///
  /// Llamar al salir de las pantallas de auth para evitar estados residuales.
  void clearAuthStatus() {
    state = state.copyWith(
      authStatus: AuthStatus.idle,
      clearAuthError: true,
    );
  }

  // ── Callbacks privados ────────────────────────────────────────────────────

  /// Ejecuta el borrado remoto cuando la app está en FOREGROUND.
  /// Verifica que el correo objetivo coincida con el usuario autenticado
  /// antes de borrar — garantiza que la notificación FCM es para este usuario.
  Future<void> _handleRemoteWipe(String targetEmail) async {
    final storedEmail = await SensitiveDataService.getStoredEmail();
    if (storedEmail == null || storedEmail != targetEmail) return;

    SessionService.instance.stop();
    NotificationService.onRemoteWipe = null;
    await SensitiveDataService.wipeAll();

    state = SessionState.empty.copyWith(wasRemoteWiped: true);
  }

  void _onSessionWarning(int secondsRemaining) {
    state = state.copyWith(
      isSessionWarning: true,
      warningSecondsRemaining: secondsRemaining,
    );
  }

  Future<void> _onSessionExpired() async {
    NotificationService.onRemoteWipe = null;
    await _authRepository.logout();
    state = SessionState.empty;
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

/// Provider global del estado de sesión.
///
/// Se declara aquí (cerca del Notifier) para mantener cohesión,
/// y se re-exporta desde [providers.dart] para acceso centralizado.
final sessionNotifierProvider =
    NotifierProvider<SessionNotifier, SessionState>(SessionNotifier.new);
