import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vibetreck/core/theme/theme_controller.dart';

class AppTheme {
  static const Color backgroundDark = Color(0xFF0A0A0D);
  static const Color surfaceDark = Color(0xFF15171C);
  static const Color backgroundLight = Color(0xFFF6F4EF);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color borderDark = Color(0xFF2B3038);
  static const Color borderLight = Color(0xFFD7D2C6);

  // Compatibility aliases for existing widgets that still read the old theme API.
  static const Color background = backgroundDark;
  static const Color surface = surfaceDark;
  static const Color border = borderDark;
  static const Color primary = Color(0xFFD6FF3F);
  static const Color secondary = Color(0xFF38E0C4);

  static Color accentFor(AppAccentColor accent) {
    switch (accent) {
      case AppAccentColor.lime:
        return const Color(0xFFD6FF3F);
      case AppAccentColor.teal:
        return const Color(0xFF38E0C4);
      case AppAccentColor.coral:
        return const Color(0xFFFF7A59);
      case AppAccentColor.sky:
        return const Color(0xFF52B6FF);
    }
  }

  static ThemeData lightTheme({
    required AppAccentColor accent,
    ColorScheme? dynamicScheme,
  }) {
    return _buildTheme(
      brightness: Brightness.light,
      accent: accentFor(accent),
      dynamicScheme: dynamicScheme,
    );
  }

  static ThemeData darkTheme({
    required AppAccentColor accent,
    ColorScheme? dynamicScheme,
  }) {
    return _buildTheme(
      brightness: Brightness.dark,
      accent: accentFor(accent),
      dynamicScheme: dynamicScheme,
    );
  }

  static ThemeData _buildTheme({
    required Brightness brightness,
    required Color accent,
    ColorScheme? dynamicScheme,
  }) {
    final isDark = brightness == Brightness.dark;
    final scheme = dynamicScheme ??
        ColorScheme.fromSeed(
          seedColor: accent,
          brightness: brightness,
          surface: isDark ? surfaceDark : surfaceLight,
        );

    final base = ThemeData(
      brightness: brightness,
      scaffoldBackgroundColor: isDark ? backgroundDark : backgroundLight,
      colorScheme: scheme,
      useMaterial3: true,
    );

    final bodyText = GoogleFonts.plusJakartaSansTextTheme(base.textTheme);
    final displayFont = GoogleFonts.spaceGroteskTextTheme(bodyText);

    return base.copyWith(
      textTheme: displayFont.copyWith(
        headlineSmall: displayFont.headlineSmall?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.8,
        ),
        titleMedium: displayFont.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ),
        bodyMedium: displayFont.bodyMedium?.copyWith(height: 1.35),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.spaceGrotesk(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: scheme.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        color: isDark ? surfaceDark : surfaceLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: isDark ? 0 : 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: isDark ? surfaceDark : surfaceLight,
        selectedColor: scheme.primary.withValues(alpha: 0.18),
        side: BorderSide(
          color: isDark ? borderDark : borderLight,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? surfaceDark : surfaceLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: isDark ? borderDark : borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: isDark ? borderDark : borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: scheme.primary, width: 1.4),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          side: BorderSide(color: isDark ? borderDark : borderLight),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isDark ? surfaceDark : surfaceLight,
        indicatorColor: scheme.primary.withValues(alpha: 0.18),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return GoogleFonts.plusJakartaSans(
            color: selected ? scheme.primary : scheme.onSurface.withValues(alpha: 0.72),
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          );
        }),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? surfaceDark : surfaceLight,
        contentTextStyle: GoogleFonts.plusJakartaSans(
          color: scheme.onSurface,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        behavior: SnackBarBehavior.floating,
      ),
      dividerColor: isDark ? borderDark : borderLight,
    );
  }
}
