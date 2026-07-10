import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ── Paleta AprendIA — extraída del landing en producción ─────────────────────
//   Cyan principal : #00C2E0  (brand cyan del landing)
//   Cyan oscuro    : #0099B3  (hover/énfasis)
//   Cyan suave     : #E0F8FF  (containers light)
//   Navy dark      : #012E46  (surface dark del landing)
//   Bg dark        : #020F18  (fondo dark del landing)
//   Acento verde   : #06D6A0  (complementario, acciones exitosas)

class AppColors {
  AppColors._();

  // ── Brand (invariante) ────────────────────────────────────────────────────
  static const Color primary     = Color(0xFF00A8C8); // cyan equilibrado
  static const Color primaryDark = Color(0xFF0099B3); // cyan más profundo
  static const Color primaryBright = Color(0xFF00C2E0); // cyan del landing
  static const Color accent      = Color(0xFF06D6A0); // verde complementario
  static const Color error       = Color(0xFFEF4444);
  static const Color success     = Color(0xFF10B981);
  static const Color warning     = Color(0xFFF59E0B);

  // ── Tema claro ────────────────────────────────────────────────────────────
  static const Color lightBackground     = Color(0xFFF0FAFD); // muy suave cyan-blanco
  static const Color lightSurface        = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFE8F7FB);
  static const Color lightTextPrimary    = Color(0xFF0B2233); // navy oscuro del landing
  static const Color lightTextSecondary  = Color(0xFF546E7A);
  static const Color lightTextHint       = Color(0xFFB0BEC5);
  static const Color lightDivider        = Color(0xFFDEEFF4);
  static const Color lightPrimaryContainer = Color(0xFFCDF2FA); // cyan suave

  // ── Tema oscuro (basado EXACTAMENTE en el landing de producción) ──────────
  static const Color darkBackground     = Color(0xFF020F18); // --bg del landing
  static const Color darkSurface        = Color(0xFF012E46); // --navy del landing
  static const Color darkSurfaceVariant = Color(0xFF024466); // --navy-mid del landing
  static const Color darkTextPrimary    = Color(0xFFE8F4F8);
  static const Color darkTextSecondary  = Color(0xFF8A9AAA); // --gray del landing
  static const Color darkTextHint       = Color(0xFF4A6070);
  static const Color darkDivider        = Color(0xFF0D3A52); // border del landing
  static const Color darkPrimaryContainer = Color(0xFF013550);

  // ── Alias retrocompatibles ────────────────────────────────────────────────
  static const Color background    = lightBackground;
  static const Color surface       = lightSurface;
  static const Color primaryLight  = lightSurfaceVariant;
  static const Color secondary     = accent;
  static const Color secondaryLight= Color(0xFFE6FAF5);
  static const Color accentLight   = Color(0xFFE6FAF5);
  static const Color textPrimary   = lightTextPrimary;
  static const Color textSecondary = lightTextSecondary;
  static const Color textHint      = lightTextHint;
  static const Color divider       = lightDivider;
  static const Color darkBg            = darkBackground;
  static const Color darkBgSurface     = darkSurface;
  static const Color darkText          = darkTextPrimary;
  static const Color darkTextSecondaryAlias = darkTextSecondary;

  // ── Clay+Glass design colors ──────────────────────────────────────────────
  static const Color violet     = Color(0xFF7C3AED);
  static const Color violetDark = Color(0xFF5B21B6);
}

// ── Extension para acceso rápido desde BuildContext ───────────────────────────

extension AppThemeExtension on BuildContext {
  ColorScheme get cs      => Theme.of(this).colorScheme;
  bool         get isDark => Theme.of(this).brightness == Brightness.dark;

  Color get bgColor        => cs.surface;
  Color get cardColor      => isDark ? AppColors.darkSurface       : AppColors.lightSurface;
  Color get cardVariant    => isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant;
  Color get textPrimary    => isDark ? AppColors.darkTextPrimary    : AppColors.lightTextPrimary;
  Color get textSecondary  => isDark ? AppColors.darkTextSecondary  : AppColors.lightTextSecondary;
  Color get dividerColor   => isDark ? AppColors.darkDivider        : AppColors.lightDivider;
  Color get primaryContainerColor => isDark ? AppColors.darkPrimaryContainer : AppColors.lightPrimaryContainer;
}

// ── Temas ─────────────────────────────────────────────────────────────────────

class AppTheme {
  AppTheme._();

  // ── Tema CLARO ────────────────────────────────────────────────────────────
  static ThemeData get lightTheme {
    const cs = ColorScheme(
      brightness: Brightness.light,
      primary:            AppColors.primary,
      onPrimary:          Colors.white,
      primaryContainer:   AppColors.lightPrimaryContainer,
      onPrimaryContainer: AppColors.primaryDark,
      secondary:          AppColors.accent,
      onSecondary:        Colors.white,
      secondaryContainer: Color(0xFFCCF5EB),
      onSecondaryContainer: Color(0xFF004D38),
      tertiary:           Color(0xFF0077A0),
      onTertiary:         Colors.white,
      tertiaryContainer:  Color(0xFFCBEEF8),
      onTertiaryContainer: Color(0xFF003D55),
      error:              AppColors.error,
      onError:            Colors.white,
      errorContainer:     Color(0xFFFFE4E6),
      onErrorContainer:   Color(0xFF9B1C1C),
      surface:            AppColors.lightSurface,
      onSurface:          AppColors.lightTextPrimary,
      surfaceVariant:     AppColors.lightSurfaceVariant,
      onSurfaceVariant:   AppColors.lightTextSecondary,
      outline:            AppColors.lightDivider,
      outlineVariant:     Color(0xFFCDE8F0),
      shadow:             Colors.black,
      scrim:              Colors.black,
      inverseSurface:     AppColors.darkSurface,
      onInverseSurface:   AppColors.darkTextPrimary,
      inversePrimary:     AppColors.primaryBright,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      scaffoldBackgroundColor: AppColors.lightBackground,
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.lightDivider),
        ),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.lightDivider),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.lightDivider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.lightDivider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        hintStyle: const TextStyle(color: AppColors.lightTextHint),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.3),
          elevation: 0,
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge:  TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.lightTextPrimary, letterSpacing: -0.5),
        headlineMedium: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.lightTextPrimary, letterSpacing: -0.3),
        titleLarge:     TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.lightTextPrimary),
        titleMedium:    TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.lightTextPrimary),
        bodyLarge:      TextStyle(fontSize: 16, color: AppColors.lightTextPrimary, height: 1.6),
        bodyMedium:     TextStyle(fontSize: 14, color: AppColors.lightTextSecondary, height: 1.5),
        labelLarge:     TextStyle(fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0.3),
      ),
    );
  }

  // ── Tema OSCURO (idéntico al landing de producción) ───────────────────────
  static ThemeData get darkTheme {
    const cs = ColorScheme(
      brightness: Brightness.dark,
      primary:            AppColors.primaryBright,
      onPrimary:          Color(0xFF020F18),
      primaryContainer:   AppColors.darkPrimaryContainer,
      onPrimaryContainer: AppColors.primaryBright,
      secondary:          AppColors.accent,
      onSecondary:        Color(0xFF003828),
      secondaryContainer: Color(0xFF00523A),
      onSecondaryContainer: Color(0xFF9DFAD8),
      tertiary:           Color(0xFF00C2E0),
      onTertiary:         Color(0xFF003344),
      tertiaryContainer:  Color(0xFF013550),
      onTertiaryContainer: Color(0xFF80E8FF),
      error:              Color(0xFFFF6B6B),
      onError:            Color(0xFF690005),
      errorContainer:     Color(0xFF93000A),
      onErrorContainer:   Color(0xFFFFDAD6),
      surface:            AppColors.darkSurface,
      onSurface:          AppColors.darkTextPrimary,
      surfaceVariant:     AppColors.darkSurfaceVariant,
      onSurfaceVariant:   AppColors.darkTextSecondary,
      outline:            AppColors.darkDivider,
      outlineVariant:     Color(0xFF0A2A3E),
      shadow:             Colors.black,
      scrim:              Colors.black,
      inverseSurface:     AppColors.lightSurface,
      onInverseSurface:   AppColors.lightTextPrimary,
      inversePrimary:     AppColors.primaryDark,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: cs,
      scaffoldBackgroundColor: AppColors.darkBackground,
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.darkDivider),
        ),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.darkDivider),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurfaceVariant,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.darkDivider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.darkDivider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryBright, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFFF6B6B)),
        ),
        hintStyle: const TextStyle(color: AppColors.darkTextHint),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBright,
          foregroundColor: const Color(0xFF020F18),
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.3),
          elevation: 0,
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge:  TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.darkTextPrimary, letterSpacing: -0.5),
        headlineMedium: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.darkTextPrimary, letterSpacing: -0.3),
        titleLarge:     TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.darkTextPrimary),
        titleMedium:    TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.darkTextPrimary),
        bodyLarge:      TextStyle(fontSize: 16, color: AppColors.darkTextPrimary, height: 1.6),
        bodyMedium:     TextStyle(fontSize: 14, color: AppColors.darkTextSecondary, height: 1.5),
        labelLarge:     TextStyle(fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0.3),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Gradientes globales
// ─────────────────────────────────────────────────────────────────────────────

class AppGradients {
  static const LinearGradient dark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF06091A), Color(0xFF03080F), Color(0xFF080518)],
    stops: [0.0, 0.55, 1.0],
  );
  static const LinearGradient light = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFEBF7FF), Color(0xFFF6F2FF), Color(0xFFEAFDF5)],
    stops: [0.0, 0.5, 1.0],
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Glassmorphism helper
// ─────────────────────────────────────────────────────────────────────────────

class AppGlass {
  static BoxDecoration decoration({
    double opacity = 0.08,
    double borderOpacity = 0.14,
    double radius = 20,
    Color tint = Colors.white,
  }) {
    return BoxDecoration(
      color: tint.withOpacity(opacity),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: tint.withOpacity(borderOpacity), width: 1.5),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 20,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  static BackdropFilter blur({
    double sigmaX = 16,
    double sigmaY = 16,
    required Widget child,
  }) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: sigmaX, sigmaY: sigmaY),
      child: child,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Claymorphism shadows helper
// ─────────────────────────────────────────────────────────────────────────────

class AppClay {
  static List<BoxShadow> shadows(Color color, {required bool isDark}) {
    if (isDark) {
      return [
        BoxShadow(
          color: color.withOpacity(0.30),
          blurRadius: 16,
          offset: const Offset(0, 6),
          spreadRadius: -2,
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.35),
          blurRadius: 24,
          offset: const Offset(0, 10),
        ),
      ];
    } else {
      return [
        BoxShadow(
          color: color.withOpacity(0.25),
          blurRadius: 14,
          offset: const Offset(0, 5),
          spreadRadius: -2,
        ),
        const BoxShadow(
          color: Color(0x33FFFFFF),
          blurRadius: 4,
          offset: Offset(-2, -2),
        ),
      ];
    }
  }

  static BoxDecoration light(Color color) => BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
        boxShadow: shadows(color, isDark: false),
      );

  static BoxDecoration dark(Color color) => BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
        boxShadow: shadows(color, isDark: true),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Decorative background blob (blurred circle for depth)
// ─────────────────────────────────────────────────────────────────────────────

class AppBlob extends StatelessWidget {
  final double size;
  final Color color;
  final double opacity;

  const AppBlob({
    super.key,
    required this.size,
    required this.color,
    this.opacity = 0.15,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(opacity),
            blurRadius: size * 0.8,
            spreadRadius: size * 0.1,
          ),
        ],
      ),
    );
  }
}
