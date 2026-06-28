import 'package:flutter/material.dart';

// ── Paleta de colores ─────────────────────────────────────────────────────────

class AppColors {
  AppColors._();

  // Brand (invariante en ambos temas)
  static const Color primary     = Color(0xFF4F8EF7);
  static const Color primaryDark = Color(0xFF2563EB);
  static const Color accent      = Color(0xFF06D6A0);
  static const Color error       = Color(0xFFEF4444);
  static const Color success     = Color(0xFF10B981);
  static const Color warning     = Color(0xFFF59E0B);

  // ── Tema claro ────────────────────────────────────────────────────────────
  static const Color lightBackground      = Color(0xFFF0F4FF);
  static const Color lightSurface         = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant  = Color(0xFFEEF3FF);
  static const Color lightTextPrimary     = Color(0xFF0F172A);
  static const Color lightTextSecondary   = Color(0xFF64748B);
  static const Color lightTextHint        = Color(0xFFB0B7C3);
  static const Color lightDivider         = Color(0xFFE2E8F0);
  static const Color lightPrimaryContainer= Color(0xFFDCEAFF);

  // ── Tema oscuro ───────────────────────────────────────────────────────────
  static const Color darkBackground      = Color(0xFF080E1A);
  static const Color darkSurface         = Color(0xFF0D1B3E);
  static const Color darkSurfaceVariant  = Color(0xFF121F40);
  static const Color darkTextPrimary     = Color(0xFFE2E8F0);
  static const Color darkTextSecondary   = Color(0xFF94A3B8);
  static const Color darkTextHint        = Color(0xFF475569);
  static const Color darkDivider         = Color(0xFF1E2D55);
  static const Color darkPrimaryContainer= Color(0xFF1A2E60);

  // ── Alias retrocompatibles (apuntan al tema claro) ────────────────────────
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
  // Dark aliases (login / register siempre oscuro)
  static const Color darkBg            = darkBackground;
  static const Color darkBgSurface     = darkSurface;
  static const Color darkText          = darkTextPrimary;
  static const Color darkTextSecondaryAlias = darkTextSecondary;
}

// ── Extension para acceso rápido desde BuildContext ───────────────────────────

extension AppThemeExtension on BuildContext {
  ColorScheme get cs      => Theme.of(this).colorScheme;
  bool         get isDark => Theme.of(this).brightness == Brightness.dark;

  // Atajos semánticos
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
      tertiary:           Color(0xFF7C3AED),
      onTertiary:         Colors.white,
      tertiaryContainer:  Color(0xFFEDE9FE),
      onTertiaryContainer: Color(0xFF4C1D95),
      error:              AppColors.error,
      onError:            Colors.white,
      errorContainer:     Color(0xFFFFE4E6),
      onErrorContainer:   Color(0xFF9B1C1C),
      surface:            AppColors.lightSurface,
      onSurface:          AppColors.lightTextPrimary,
      surfaceVariant:     AppColors.lightSurfaceVariant,
      onSurfaceVariant:   AppColors.lightTextSecondary,
      outline:            AppColors.lightDivider,
      outlineVariant:     Color(0xFFCDD5E0),
      shadow:             Colors.black,
      scrim:              Colors.black,
      inverseSurface:     AppColors.darkSurface,
      onInverseSurface:   AppColors.darkTextPrimary,
      inversePrimary:     Color(0xFF93BBFF),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      scaffoldBackgroundColor: AppColors.lightBackground,
      fontFamily: 'Roboto',
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
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.5),
          elevation: 0,
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge:  TextStyle(fontSize: 28, fontWeight: FontWeight.bold,  color: AppColors.lightTextPrimary, letterSpacing: -0.5),
        headlineMedium: TextStyle(fontSize: 22, fontWeight: FontWeight.bold,  color: AppColors.lightTextPrimary),
        titleLarge:     TextStyle(fontSize: 18, fontWeight: FontWeight.w700,  color: AppColors.lightTextPrimary),
        titleMedium:    TextStyle(fontSize: 16, fontWeight: FontWeight.w600,  color: AppColors.lightTextPrimary),
        bodyLarge:      TextStyle(fontSize: 16, color: AppColors.lightTextPrimary),
        bodyMedium:     TextStyle(fontSize: 14, color: AppColors.lightTextSecondary),
        labelLarge:     TextStyle(fontSize: 16, fontWeight: FontWeight.w600,  letterSpacing: 0.5),
      ),
    );
  }

  // ── Tema OSCURO ───────────────────────────────────────────────────────────
  static ThemeData get darkTheme {
    const cs = ColorScheme(
      brightness: Brightness.dark,
      primary:            AppColors.primary,
      onPrimary:          Colors.white,
      primaryContainer:   AppColors.darkPrimaryContainer,
      onPrimaryContainer: Color(0xFF93BBFF),
      secondary:          AppColors.accent,
      onSecondary:        Color(0xFF003828),
      secondaryContainer: Color(0xFF00523A),
      onSecondaryContainer: Color(0xFF9DFAD8),
      tertiary:           Color(0xFFA78BFA),
      onTertiary:         Color(0xFF2E1065),
      tertiaryContainer:  Color(0xFF3B0D8F),
      onTertiaryContainer: Color(0xFFEDE9FE),
      error:              Color(0xFFFF6B6B),
      onError:            Color(0xFF690005),
      errorContainer:     Color(0xFF93000A),
      onErrorContainer:   Color(0xFFFFDAD6),
      surface:            AppColors.darkSurface,
      onSurface:          AppColors.darkTextPrimary,
      surfaceVariant:     AppColors.darkSurfaceVariant,
      onSurfaceVariant:   AppColors.darkTextSecondary,
      outline:            AppColors.darkDivider,
      outlineVariant:     Color(0xFF1A2A50),
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
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFFF6B6B)),
        ),
        hintStyle: const TextStyle(color: AppColors.darkTextHint),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.5),
          elevation: 0,
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge:  TextStyle(fontSize: 28, fontWeight: FontWeight.bold,  color: AppColors.darkTextPrimary, letterSpacing: -0.5),
        headlineMedium: TextStyle(fontSize: 22, fontWeight: FontWeight.bold,  color: AppColors.darkTextPrimary),
        titleLarge:     TextStyle(fontSize: 18, fontWeight: FontWeight.w700,  color: AppColors.darkTextPrimary),
        titleMedium:    TextStyle(fontSize: 16, fontWeight: FontWeight.w600,  color: AppColors.darkTextPrimary),
        bodyLarge:      TextStyle(fontSize: 16, color: AppColors.darkTextPrimary),
        bodyMedium:     TextStyle(fontSize: 14, color: AppColors.darkTextSecondary),
        labelLarge:     TextStyle(fontSize: 16, fontWeight: FontWeight.w600,  letterSpacing: 0.5),
      ),
    );
  }
}
