/// Constantes globales de la aplicación AprendIA.
class AppConstants {
  AppConstants._();

  // -------------------------------------------------------------------------
  // Sesión e inactividad
  // -------------------------------------------------------------------------

  /// Tiempo de inactividad antes de cerrar sesión automáticamente.
  /// Cambiar a Duration(minutes: 1) o Duration(minutes: 5) en producción.
  static const sessionTimeout = Duration(seconds: 15);

  // -------------------------------------------------------------------------
  // Claves para flutter_secure_storage
  // -------------------------------------------------------------------------

  /// Llave del token de sesión en el almacén encriptado.
  static const storageKeyToken = 'session_token';

  /// Llave del timestamp de última actividad del usuario.
  static const storageKeyLastActivity = 'last_activity_timestamp';

  /// Llave del timestamp de inicio de sesión.
  static const storageKeyLoginTime = 'login_timestamp';
}
