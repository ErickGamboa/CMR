import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Tema Material 3 de CMR. Se usa igual en Android e iOS: los widgets
/// Material se adaptan al gesto/scroll nativo de cada plataforma.
abstract final class AppTheme {
  static ThemeData get light => _build(_lightScheme);
  static ThemeData get dark => _build(_darkScheme);

  static const _lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.azulAbisal,
    onPrimary: Colors.white,
    primaryContainer: AppColors.azulVital,
    onPrimaryContainer: AppColors.azulAbisal,
    secondary: AppColors.turquesaBiocelular,
    onSecondary: Colors.white,
    secondaryContainer: Color(0xFFD5E8EA),
    onSecondaryContainer: Color(0xFF10393C),
    tertiary: AppColors.azulVital,
    onTertiary: AppColors.textoPrincipal,
    tertiaryContainer: Color(0xFFDFF3FE),
    onTertiaryContainer: AppColors.azulAbisal,
    error: AppColors.error,
    onError: Colors.white,
    surface: AppColors.superficie,
    onSurface: AppColors.textoPrincipal,
    surfaceContainerLowest: Colors.white,
    surfaceContainer: AppColors.superficieAlterna,
    onSurfaceVariant: AppColors.textoSecundario,
    outline: Color(0xFFBFC6D4),
    outlineVariant: Color(0xFFE1E6EE),
  );

  static const _darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: AppColors.azulVital,
    onPrimary: AppColors.azulAbisal,
    primaryContainer: AppColors.azulAbisal,
    onPrimaryContainer: AppColors.azulVital,
    secondary: AppColors.turquesaBiocelular,
    onSecondary: Color(0xFF06231F),
    secondaryContainer: Color(0xFF2A5457),
    onSecondaryContainer: Color(0xFFD5E8EA),
    tertiary: AppColors.azulVital,
    onTertiary: AppColors.azulAbisal,
    tertiaryContainer: Color(0xFF1B4E68),
    onTertiaryContainer: Color(0xFFDFF3FE),
    error: Color(0xFFF2B8B5),
    onError: Color(0xFF601410),
    surface: AppColors.superficieOscura,
    onSurface: Color(0xFFE6E8F2),
    surfaceContainerLowest: Color(0xFF07071F),
    surfaceContainer: AppColors.superficieOscuraAlterna,
    onSurfaceVariant: Color(0xFFB4B8CC),
    outline: Color(0xFF474B66),
    outlineVariant: Color(0xFF2A2E4A),
  );

  static ThemeData _build(ColorScheme scheme) {
    final base = ThemeData(colorScheme: scheme, useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: true,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainer,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: scheme.primaryContainer,
        elevation: 0,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          // Transición nativa por plataforma.
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
