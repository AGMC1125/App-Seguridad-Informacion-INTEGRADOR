/// Estados posibles de una operación de autenticación (login / register).
///
/// Sigue el patrón idle → loading → success | error.
/// Vive en la capa de dominio porque describe un concepto de negocio,
/// no un detalle de presentación ni de datos.
enum AuthStatus {
  /// Estado inicial — ninguna operación ha sido lanzada aún.
  idle,

  /// Operación en vuelo (HTTP en curso).
  loading,

  /// Operación completada con éxito.
  success,

  /// Operación fallida. El mensaje vive en [SessionState.authError].
  error,
}
