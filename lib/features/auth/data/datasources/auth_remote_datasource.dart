import '../../../../core/network/api_client.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/encrypted_storage_service.dart';
import '../../../../core/services/sensitive_data_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/login_response_model.dart';

/// Fuente de datos remota para autenticación.
///
/// Responsabilidad única: ejecutar llamadas HTTP al backend de auth
/// y serializar/deserializar los datos. No contiene lógica de negocio.
class AuthRemoteDataSource {
  const AuthRemoteDataSource();

  /// Autentica al usuario contra la API.
  /// Persiste token y datos sensibles en almacenamiento cifrado.
  /// Lanza [AuthException] si el servidor devuelve error.
  Future<LoginResponseModel> login(String email, String password) async {
    try {
      final data = await ApiClient.post('/auth/login', {
        'email': email,
        'password': password,
      });

      final model = LoginResponseModel.fromJson(data);
      final loginTime = DateTime.now().toIso8601String();

      // Persistir token y timestamps cifrados
      await EncryptedStorageService.write(
        key: AppConstants.storageKeyToken,
        value: model.accessToken,
      );
      await EncryptedStorageService.write(
        key: AppConstants.storageKeyLoginTime,
        value: loginTime,
      );
      await EncryptedStorageService.write(
        key: AppConstants.storageKeyLastActivity,
        value: loginTime,
      );

      // Persistir los 4 campos sensibles cifrados con AES-256
      String? fcmToken;
      try {
        fcmToken = await NotificationService().getToken();
      } catch (_) {
        // FCM no disponible en emuladores sin Google Play Services
      }
      await SensitiveDataService.populate(
        email: email,
        name: model.userName,
        fcmToken: fcmToken,
      );

      return model;
    } on ApiException catch (e) {
      throw AuthException(e.message);
    }
  }

  /// Registra un nuevo usuario en la API.
  /// Lanza [AuthException] si el correo ya existe u ocurre otro error.
  Future<void> register({
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
    } on ApiException catch (e) {
      throw AuthException(e.message);
    }
  }

  /// Elimina todos los datos de sesión del almacenamiento cifrado.
  Future<void> clearLocalSession() async {
    await EncryptedStorageService.delete(key: AppConstants.storageKeyToken);
    await EncryptedStorageService.delete(key: AppConstants.storageKeyLoginTime);
    await EncryptedStorageService.delete(
        key: AppConstants.storageKeyLastActivity);
    await EncryptedStorageService.delete(
        key: AppConstants.storageKeySensitiveEmail);
    await EncryptedStorageService.delete(
        key: AppConstants.storageKeySensitiveName);
    await EncryptedStorageService.delete(
        key: AppConstants.storageKeySensitiveFcmToken);
    await EncryptedStorageService.delete(
        key: AppConstants.storageKeySensitiveRegion);
  }

  /// Actualiza nombre y/o email del usuario en la API.
  /// Lanza [AuthException] si ocurre un error de servidor.
  Future<Map<String, dynamic>> updateProfile({
    required String token,
    String? name,
    String? email,
  }) async {
    try {
      final body = <String, dynamic>{
        if (name != null && name.trim().isNotEmpty) 'name': name.trim(),
        if (email != null && email.trim().isNotEmpty) 'email': email.trim(),
      };
      return await ApiClient.patch('/users/me', body, token: token);
    } on ApiException catch (e) {
      throw AuthException(e.message);
    }
  }

  /// Cambia la contraseña del usuario en la API.
  /// Lanza [AuthException] si la contraseña actual es incorrecta.
  Future<void> changePassword({
    required String token,
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await ApiClient.patch(
        '/users/me/password',
        {'currentPassword': currentPassword, 'newPassword': newPassword},
        token: token,
      );
    } on ApiException catch (e) {
      throw AuthException(e.message);
    }
  }

  /// Elimina la cuenta del usuario (soft-delete) en la API.
  Future<void> deleteAccount({required String token}) async {
    try {
      await ApiClient.delete('/users/me', token: token);
    } on ApiException catch (e) {
      throw AuthException(e.message);
    }
  }
}
