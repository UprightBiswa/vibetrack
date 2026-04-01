import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vibetreck/core/theme/theme_controller.dart';

class AppTheme {
  static const Color backgroundDark = Color(0xFF07090C);
  static const Color surfaceDark = Color(0xFF10141A);
  static const Color backgroundLight = Color(0xFFF6F4EF);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color borderDark = Color(0xFF29313A);
  static const Color borderLight = Color(0xFFD7D2C6);
  static const Color panelDark = Color(0xFF151B22);
  static const Color panelLight = Color(0xFFF0ECE3);
  static const Color glowLime = Color(0xFFD6FF3F);
  static const Color glowTeal = Color(0xFF38E0C4);
  static const Color glowCoral = Color(0xFFFF6B6B);
  static const Color glowSky = Color(0xFF52B6FF);

  static const Color background = backgroundDark;
  static const Color surface = surfaceDark;
  static const Color border = borderDark;
  static const Color primary = glowLime;
  static const Color secondary = glowTeal;

  static const LinearGradient cyberBackground = LinearGradient(
    colors: [Color(0xFF07090C), Color(0xFF0D1117), Color(0xFF11191B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient zoneHeroGradient = LinearGradient(
    colors: [Color(0xFF101714), Color(0xFF1A2608), Color(0xFF0A0E0D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static Color accentFor(AppAccentColor accent) {
    switch (accent) {
      case AppAccentColor.lime:
        return glowLime;
      case AppAccentColor.teal:
        return glowTeal;
      case AppAccentColor.coral:
        return glowCoral;
      case AppAccentColor.sky:
        return glowSky;
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
    final scheme =
        dynamicScheme ??
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
        displaySmall: displayFont.displaySmall?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -1.3,
        ),
        headlineMedium: displayFont.headlineMedium?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -1,
        ),
        headlineSmall: displayFont.headlineSmall?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.8,
        ),
        titleLarge: displayFont.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
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
        color: isDark ? panelDark : surfaceLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: isDark ? 0 : 1,
        margin: EdgeInsets.zero,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: isDark ? panelDark : surfaceLight,
        selectedColor: scheme.primary.withValues(alpha: 0.18),
        side: BorderSide(color: isDark ? borderDark : borderLight),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? panelDark : surfaceLight,
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
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          side: BorderSide(color: isDark ? borderDark : borderLight),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isDark ? panelDark : surfaceLight,
        indicatorColor: scheme.primary.withValues(alpha: 0.16),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return GoogleFonts.plusJakartaSans(
            color: selected
                ? scheme.primary
                : scheme.onSurface.withValues(alpha: 0.72),
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          );
        }),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? panelDark : surfaceLight,
        contentTextStyle: GoogleFonts.plusJakartaSans(color: scheme.onSurface),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        behavior: SnackBarBehavior.floating,
      ),
      dividerColor: isDark ? borderDark : borderLight,
    );
  }
}
