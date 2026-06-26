import '../constants/app_constants.dart';
import 'api_client.dart';
import 'encrypted_storage_service.dart';
import 'notification_service.dart';
import 'sensitive_data_service.dart';

class LoginResult {
  final bool success;
  final String? token;
  final String? userName;
  final String? errorMessage;

  const LoginResult._({
    required this.success,
    this.token,
    this.userName,
    this.errorMessage,
  });

  factory LoginResult.success({required String token, required String userName}) =>
      LoginResult._(success: true, token: token, userName: userName);

  factory LoginResult.failure(String message) =>
      LoginResult._(success: false, errorMessage: message);
}

class AuthService {
  AuthService._();

  static Future<LoginResult> login(String email, String password) async {
    try {
      final data = await ApiClient.post('/auth/login', {
        'email': email,
        'password': password,
      });

      // Spring Boot devuelve accessToken (camelCase)
      final token = data['accessToken'] as String;
      final userName = (data['user'] as Map<String, dynamic>)['name'] as String;
      final loginTime = DateTime.now().toIso8601String();

      // Guardar datos de sesión cifrados
      await EncryptedStorageService.write(
          key: AppConstants.storageKeyToken, value: token);
      await EncryptedStorageService.write(
          key: AppConstants.storageKeyLoginTime, value: loginTime);
      await EncryptedStorageService.write(
          key: AppConstants.storageKeyLastActivity, value: loginTime);

      // Guardar los 4 campos sensibles cifrados con AES-256
      String? fcmToken;
      try {
        fcmToken = await NotificationService().getToken();
      } catch (_) {
        // FCM no disponible en emuladores sin Google Play Services
      }
      await SensitiveDataService.populate(
        email: email,
        name: userName,
        fcmToken: fcmToken,
      );

      return LoginResult.success(token: token, userName: userName);
    } on ApiException catch (e) {
      return LoginResult.failure(e.message);
    }
  }

  static Future<String?> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      await ApiClient.post('/auth/register', {
        'name': name,
        'email': email,
        'password': password,
      });
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  static Future<void> logout() async {
    await EncryptedStorageService.delete(key: AppConstants.storageKeyToken);
    await EncryptedStorageService.delete(key: AppConstants.storageKeyLoginTime);
    await EncryptedStorageService.delete(key: AppConstants.storageKeyLastActivity);
    await EncryptedStorageService.delete(key: AppConstants.storageKeySensitiveEmail);
    await EncryptedStorageService.delete(key: AppConstants.storageKeySensitiveName);
    await EncryptedStorageService.delete(key: AppConstants.storageKeySensitiveFcmToken);
    await EncryptedStorageService.delete(key: AppConstants.storageKeySensitiveRegion);
  }

  static Future<bool> hasActiveSession() async {
    final token =
        await EncryptedStorageService.read(key: AppConstants.storageKeyToken);
    return token != null && token.isNotEmpty;
  }

  static Future<String?> getToken() async {
    return EncryptedStorageService.read(key: AppConstants.storageKeyToken);
  }
}
