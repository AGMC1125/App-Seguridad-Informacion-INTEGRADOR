/// Constantes globales de la aplicación AprendIA.
class AppConstants {
  AppConstants._();

  // Sesión e inactividad

  /// Tiempo de inactividad antes de cerrar sesión automáticamente.
  static const sessionTimeout = Duration(minutes: 5);

  /// Tiempo antes del cierre en el que se muestra la advertencia al usuario.
  static const sessionWarningBefore = Duration(seconds: 30);

  // API – Spring Boot desplegada en producción
  static const apiBaseUrl = 'https://aprendia.angeldev.fun';

  // --> Claves para almacén encriptado (datos de sesión)

  static const storageKeyToken = 'session_token';
  static const storageKeyLastActivity = 'last_activity_timestamp';
  static const storageKeyLoginTime = 'login_timestamp';

  // --> Claves para almacén encriptado (datos sensibles del usuario)

  /// Correo electrónico del usuario autenticado.
  static const storageKeySensitiveEmail = 'sensitive_user_email';

  /// Nombre completo del usuario autenticado.
  static const storageKeySensitiveName = 'sensitive_user_name';   

  /// Token FCM del dispositivo (canal de notificaciones push y borrado remoto).
  static const storageKeySensitiveFcmToken = 'sensitive_fcm_token';

  /// Región geográfica del usuario (determina avatar LSM por zona).
  static const storageKeySensitiveRegion = 'sensitive_user_region';
}
