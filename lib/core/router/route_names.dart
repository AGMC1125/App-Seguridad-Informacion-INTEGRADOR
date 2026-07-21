/// Nombres y paths de todas las rutas de la aplicación.
///
/// Centralizar las rutas aquí garantiza que ninguna pantalla
/// acople su navegación al nombre de otra clase concreta.
abstract class RouteNames {
  RouteNames._();

  // ── Rutas públicas (sin autenticación requerida) ──────────────────────────

  /// Pantalla de verificación RASP + login.
  static const login = '/login';

  /// Formulario de registro de nueva cuenta.
  static const register = '/register';

  /// Política de privacidad (accesible antes del login).
  static const privacy = '/privacy';

  /// Términos y condiciones (accesible antes del login).
  static const terms = '/terms';

  // ── Rutas protegidas (requieren sesión activa) ────────────────────────────

  /// Pantalla principal / hub de navegación.
  static const home = '/home';

  /// Generador de señas LSM a partir de texto.
  static const generator = '/generator';

  /// Historial de videos generados.
  static const history = '/history';

  /// Buscador semántico BM25.
  static const search = '/search';

  /// Perfil de usuario y configuración de cuenta.
  static const profile = '/profile';

  /// Diccionario de familia LSM.
  static const family = '/family';

  // ── Subruta de family ─────────────────────────────────────────────────────

  /// Detalle de una palabra del diccionario.
  /// El path completo es /family/word/:word
  /// Usa [wordDetailPath] para construir la URL con el parámetro.
  static const wordDetail = 'word/:word';

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Construye el path completo para el detalle de una palabra.
  ///
  /// Ejemplo: `RouteNames.wordDetailPath('mama')` → `/family/word/mama`
  static String wordDetailPath(String word) => '/family/word/$word';
}
