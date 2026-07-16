/// Constantes globales de la aplicación AprendIA.
class AppConstants {
  AppConstants._();

  // Sesión e inactividad

  /// Tiempo de inactividad antes de cerrar sesión automáticamente.
  static const sessionTimeout = Duration(minutes: 5);

  /// Tiempo antes del cierre en el que se muestra la advertencia al usuario.
  static const sessionWarningBefore = Duration(seconds: 30);

  // API – URL de producción.
  // Para desarrollo local, sobreescribe en un archivo local no commiteado
  // o usa --dart-define=API_BASE_URL=http://10.252.238.227:8080 al compilar.
  //   Dispositivo físico → http://192.168.1.X:8080
  //   Emulador Android  → http://10.0.2.2:8080
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://aprendia.angeldev.fun',
  );

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
