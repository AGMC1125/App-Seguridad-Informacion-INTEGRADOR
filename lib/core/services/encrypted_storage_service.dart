import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:shared_preferences/shared_preferences.dart';

/// Servicio de almacenamiento encriptado usando AES-256-GCM.
///
/// Combina [SharedPreferences] para persistencia con el paquete [encrypt]
/// para cifrar los valores con AES-256 en modo GCM (cifrado autenticado)
/// antes de guardarlos.
///
/// GCM vs CBC:
/// - Incluye etiqueta de autenticación (AEAD) — detecta manipulación de datos.
/// - Usa un IV aleatorio de 12 bytes único por operación de escritura —
///   elimina la vulnerabilidad de IV fijo que tenía el modo CBC.
/// - Formato en disco: Base64( iv[12] || ciphertext+tag ).
///
/// Nota sobre migración: los datos previamente cifrados con AES-CBC no son
/// compatibles con este esquema. El bloque catch en [read] retorna null
/// silenciosamente, lo que hace que la sesión no se restaure y el usuario
/// deba volver a autenticarse — comportamiento seguro y aceptable.
class EncryptedStorageService {
  EncryptedStorageService._();

  // Clave AES-256 (32 bytes).
  // En producción se derivaría del Keystore del dispositivo;
  // para esta práctica se usa una clave fija embebida en la app.
  static final _key = enc.Key.fromUtf8('AprendIA_SecKey_32BytesExactly!!');

  // Generador seguro de números aleatorios para el IV por operación.
  static final _secureRandom = Random.secure();

  // -------------------------------------------------------------------------
  // API pública
  // -------------------------------------------------------------------------

  /// Guarda [value] encriptado bajo [key] usando AES-256-GCM.
  ///
  /// Genera un IV aleatorio de 12 bytes por cada llamada (nonce único),
  /// y almacena el resultado como Base64(iv || ciphertext_con_tag).
  static Future<void> write({
    required String key,
    required String value,
  }) async {
    // IV de 12 bytes (96 bits) — tamaño recomendado para GCM/NIST SP 800-38D
    final ivBytes = Uint8List.fromList(
      List<int>.generate(12, (_) => _secureRandom.nextInt(256)),
    );
    final iv = enc.IV(ivBytes);
    final encrypter = enc.Encrypter(enc.AES(_key, mode: enc.AESMode.gcm));

    final encrypted = encrypter.encrypt(value, iv: iv);

    // Combinar IV + ciphertext (el tag GCM ya está incluido en encrypted.bytes)
    final combined = Uint8List(12 + encrypted.bytes.length);
    combined.setRange(0, 12, ivBytes);
    combined.setRange(12, combined.length, encrypted.bytes);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, base64Encode(combined));
  }

  /// Lee y desencripta el valor almacenado bajo [key].
  ///
  /// Retorna `null` si la clave no existe, si el dato está corrupto,
  /// o si la autenticación GCM falla (posible manipulación del dato).
  static Future<String?> read({required String key}) async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(key);
    if (stored == null) return null;

    try {
      final combined = base64Decode(stored);
      // Mínimo 13 bytes: 12 (IV) + al menos 1 byte de ciphertext
      if (combined.length < 13) return null;

      final ivBytes = combined.sublist(0, 12);
      final ciphertextBytes = combined.sublist(12);

      final iv = enc.IV(Uint8List.fromList(ivBytes));
      final encrypter = enc.Encrypter(enc.AES(_key, mode: enc.AESMode.gcm));

      return encrypter.decrypt(
        enc.Encrypted(Uint8List.fromList(ciphertextBytes)),
        iv: iv,
      );
    } catch (_) {
      // Dato corrupto, manipulado, o en formato CBC legacy — fallo seguro.
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
