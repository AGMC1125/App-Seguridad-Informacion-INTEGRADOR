import '../../domain/entities/user_session.dart';

/// Modelo de respuesta de la API para el endpoint POST /auth/login.
///
/// Responsabilidad única: deserializar JSON → objeto Dart y convertir
/// al entity de dominio [UserSession]. No contiene lógica de negocio.
class LoginResponseModel {
  final String accessToken;
  final String userName;
  final String userEmail;

  const LoginResponseModel({
    required this.accessToken,
    required this.userName,
    required this.userEmail,
  });

  factory LoginResponseModel.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>;
    return LoginResponseModel(
      accessToken: json['accessToken'] as String,
      userName: user['name'] as String,
      userEmail: user['email'] as String? ?? '',
    );
  }

  /// Convierte este modelo a la entidad de dominio.
  UserSession toEntity() => UserSession(
        token: accessToken,
        userName: userName,
        userEmail: userEmail,
      );
}
