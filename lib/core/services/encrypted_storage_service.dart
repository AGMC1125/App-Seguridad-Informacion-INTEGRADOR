import 'package:encrypt/encrypt.dart' as enc;
import 'package:shared_preferences/shared_preferences.dart';

/// Servicio de almacenamiento encriptado usando AES-256.
///
/// Combina [SharedPreferences] para persistencia con el paquete [encrypt]
/// para cifrar los valores con AES-256 en modo CBC antes de guardarlos.
///
/// Cumple el requerimiento de "almacén encriptado" de la práctica:
/// los datos en disco nunca se guardan en texto plano.
class EncryptedStorageService {
  EncryptedStorageService._();

  // Clave AES-256 (32 bytes) y IV (16 bytes).
  // En producción se derivaría del Keystore del dispositivo;
  // para esta práctica se usa una clave fija embebida en la app.
  static final _key = enc.Key.fromUtf8('AprendIA_SecKey_32BytesExactly!!');
  static final _iv  = enc.IV.fromUtf8('AprendIA_IV16By!');
  static final _encrypter = enc.Encrypter(enc.AES(_key, mode: enc.AESMode.cbc));

  // -------------------------------------------------------------------------
  // API pública
  // -------------------------------------------------------------------------

  /// Guarda [value] encriptado bajo [key].
  static Future<void> write({
    required String key,
    required String value,
  }) async {
    final encrypted = _encrypter.encrypt(value, iv: _iv);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, encrypted.base64);
  }

  /// Lee y desencripta el valor almacenado bajo [key].
  /// Retorna `null` si la clave no existe.
  static Future<String?> read({required String key}) async {
    final prefs = await SharedPreferences.getInstance();
    final base64 = prefs.getString(key);
    if (base64 == null) return null;

    try {
      return _encrypter.decrypt64(base64, iv: _iv);
    } catch (_) {
      // Dato corrupto o clave inválida
      return null;
    }
  }

  /// Elimina el valor bajo [key].
  static Future<void> delete({required String key}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }

  /// Elimina todos los valores del almacén.
  static Future<void> deleteAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
