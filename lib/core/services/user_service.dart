import 'api_client.dart';

class UserService {
  UserService._();

  /// Actualiza nombre y/o email del usuario autenticado.
  /// Solo envía los campos que no sean nulos/vacíos.
  static Future<Map<String, dynamic>> updateProfile({
    required String token,
    String? name,
    String? email,
  }) async {
    final body = <String, dynamic>{
      if (name != null && name.trim().isNotEmpty) 'name': name.trim(),
      if (email != null && email.trim().isNotEmpty) 'email': email.trim(),
    };
    return ApiClient.patch('/users/me', body, token: token);
  }

  /// Cambia la contraseña del usuario autenticado.
  static Future<void> changePassword({
    required String token,
    required String currentPassword,
    required String newPassword,
  }) async {
    await ApiClient.patch(
      '/users/me/password',
      {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      },
      token: token,
    );
  }

  /// Soft-delete de la cuenta del usuario autenticado.
  static Future<void> deleteAccount({required String token}) async {
    await ApiClient.delete('/users/me', token: token);
  }
}
