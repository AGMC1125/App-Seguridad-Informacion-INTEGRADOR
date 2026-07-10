import '../constants/app_constants.dart';
import 'encrypted_storage_service.dart';

/// Gestiona los 4 campos sensibles del usuario almacenados con AES-256.
///
/// Campos protegidos (clasificación: Secreta/Ultra-confidencial):
///   1. correo electrónico
///   2. nombre completo
///   3. token FCM del dispositivo
///   4. región geográfica
///
/// La acción de borrado remoto vía FCM elimina todos estos campos
/// junto con el token de sesión, dejando el dispositivo sin datos del usuario.
class SensitiveDataService {
  SensitiveDataService._();

  /// Persiste los 4 campos sensibles cifrados tras un login exitoso.
  static Future<void> populate({
    required String email,
    required String name,
    required String? fcmToken,
    String region = 'Chiapas, México',
  }) async {
    await EncryptedStorageService.write(
      key: AppConstants.storageKeySensitiveEmail,
      value: email,
    );
    await EncryptedStorageService.write(
      key: AppConstants.storageKeySensitiveName,
      value: name,
    );
    await EncryptedStorageService.write(
      key: AppConstants.storageKeySensitiveRegion,
      value: region,
    );
    if (fcmToken != null && fcmToken.isNotEmpty) {
      await EncryptedStorageService.write(
        key: AppConstants.storageKeySensitiveFcmToken,
        value: fcmToken,
      );
    }
  }

  /// Elimina TODOS los datos sensibles y de sesión del dispositivo.
  /// Se invoca al recibir la notificación FCM de borrado remoto.
  static Future<void> wipeAll() async {
    await EncryptedStorageService.deleteAll();
  }

  /// Lee el correo del usuario almacenado para verificar si la notificación
  /// de borrado remoto está dirigida a este dispositivo.
  static Future<String?> getStoredEmail() async {
    return EncryptedStorageService.read(
      key: AppConstants.storageKeySensitiveEmail,
    );
  }

  /// Devuelve un mapa con los nombres de los 4 campos sensibles
  /// para mostrarlos en la UI (no sus valores).
  static List<SensitiveField> get fieldDescriptions => const [
        SensitiveField(
          key: 'correo electrónico',
          icon: 'email',
          classification: 'Ultra-confidencial',
        ),
        SensitiveField(
          key: 'nombre completo',
          icon: 'person',
          classification: 'Ultra-confidencial',
        ),
        SensitiveField(
          key: 'token FCM (dispositivo)',
          icon: 'notifications',
          classification: 'Ultra-confidencial',
        ),
        SensitiveField(
          key: 'región geográfica',
          icon: 'location',
          classification: 'Confidencial',
        ),
      ];
}

class SensitiveField {
  final String key;
  final String icon;
  final String classification;

  const SensitiveField({
    required this.key,
    required this.icon,
    required this.classification,
  });
}
