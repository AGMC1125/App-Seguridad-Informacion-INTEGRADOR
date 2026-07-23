/// Validadores de formulario compartidos.
///
/// Un solo lugar para las reglas de correo, contraseña y nombre, para que
/// login y registro (y cualquier pantalla futura) validen IGUAL. Antes, el
/// login solo comprobaba que hubiera un '@' y el registro usaba un regex
/// estricto: la misma entrada se aceptaba en una pantalla y se rechazaba en
/// otra. Centralizar evita esa inconsistencia y la duplicación de reglas.
class Validators {
  Validators._();

  // Regex de correo razonable: usuario@dominio.tld (TLD de 2+ caracteres).
  static final RegExp _emailRegex =
      RegExp(r'^[\w.\-]+@([\w\-]+\.)+[\w\-]{2,}$');

  /// Correo: obligatorio y con formato válido.
  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Por favor ingresa tu correo';
    if (!_emailRegex.hasMatch(v)) return 'Ingresa un correo válido';
    return null;
  }

  /// Contraseña para el LOGIN: solo se exige que no esté vacía y tenga la
  /// longitud mínima. NO se aplica la política de complejidad aquí a propósito:
  /// la contraseña ya existe, y validar complejidad al iniciar sesión dejaría
  /// fuera a usuarios cuya contraseña se creó con una política anterior. El
  /// servidor es quien decide si la contraseña es correcta.
  static String? password(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Por favor ingresa tu contraseña';
    if (v.length < 8) return 'La contraseña debe tener al menos 8 caracteres';
    return null;
  }

  // Política de contraseña para el REGISTRO (cuando se CREA la contraseña).
  static final RegExp _upper = RegExp(r'[A-Z]');
  static final RegExp _lower = RegExp(r'[a-z]');
  static final RegExp _digit = RegExp(r'\d');

  /// Contraseña para el REGISTRO: mínimo 8, con mayúscula, minúscula y número.
  /// Debe coincidir con la validación `@Pattern` del backend (RegisterRequest).
  static String? passwordStrength(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Por favor ingresa una contraseña';
    if (v.length < 8) return 'La contraseña debe tener al menos 8 caracteres';
    if (!_upper.hasMatch(v)) return 'Debe incluir al menos una mayúscula';
    if (!_lower.hasMatch(v)) return 'Debe incluir al menos una minúscula';
    if (!_digit.hasMatch(v)) return 'Debe incluir al menos un número';
    return null;
  }

  /// Nombre: obligatorio, mínimo 3 caracteres.
  static String? name(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Por favor ingresa tu nombre';
    if (v.length < 3) return 'Ingresa tu nombre completo';
    return null;
  }

  /// Confirmación de contraseña: obligatoria y debe coincidir con [original].
  static String? confirmPassword(String? value, String original) {
    final v = value ?? '';
    if (v.isEmpty) return 'Por favor confirma tu contraseña';
    if (v != original) return 'Las contraseñas no coinciden';
    return null;
  }
}
