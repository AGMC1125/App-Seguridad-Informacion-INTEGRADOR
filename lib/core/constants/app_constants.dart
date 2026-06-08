/// Constantes globales de la aplicación AprendIA.
class AppConstants {
  AppConstants._();

  // Sesión e inactividad

  /// Tiempo de inactividad antes de cerrar sesión automáticamente.
  /// Cambiar a Duration(minutes: 1) o Duration(minutes: 5).
  static const sessionTimeout = Duration(seconds: 15);

  /// Tiempo antes del cierre en el que se muestra la advertencia al usuario.
  /// Debe ser menor que [sessionTimeout].
  static const sessionWarningBefore = Duration(seconds: 5);

  // --> Claves para almacén encriptado

  /// Llave del token de sesión en el almacén encriptado.
  static const storageKeyToken = 'session_token';

  /// Llave del timestamp de última actividad del usuario.
  static const storageKeyLastActivity = 'last_activity_timestamp';

  /// Llave del timestamp de inicio de sesión.
  static const storageKeyLoginTime = 'login_timestamp';
}
