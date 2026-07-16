/// Entidad de dominio que representa la sesión activa de un usuario.
///
/// Pertenece exclusivamente a la capa de dominio:
/// no depende de Flutter, ni de HTTP, ni de ningún paquete externo.
class UserSession {
  final String token;
  final String userName;
  final String userEmail;

  const UserSession({
    required this.token,
    required this.userName,
    required this.userEmail,
  });

  UserSession copyWith({
    String? token,
    String? userName,
    String? userEmail,
  }) {
    return UserSession(
      token: token ?? this.token,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
    );
  }
}
