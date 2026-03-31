import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final themeControllerProvider = NotifierProvider<ThemeController, ThemeSettings>(
  ThemeController.new,
);

enum AppThemeMode { system, light, dark }

enum AppAccentColor { lime, teal, coral, sky }

class ThemeSettings {
  const ThemeSettings({
    required this.mode,
    required this.accent,
    required this.useDynamicColor,
  });

  final AppThemeMode mode;
  final AppAccentColor accent;
  final bool useDynamicColor;

  ThemeMode get materialThemeMode {
    switch (mode) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }

  ThemeSettings copyWith({
    AppThemeMode? mode,
    AppAccentColor? accent,
    bool? useDynamicColor,
  }) {
    return ThemeSettings(
      mode: mode ?? this.mode,
      accent: accent ?? this.accent,
      useDynamicColor: useDynamicColor ?? this.useDynamicColor,
    );
  }

  static const fallback = ThemeSettings(
    mode: AppThemeMode.system,
    accent: AppAccentColor.lime,
    useDynamicColor: true,
  );
}

class ThemeController extends Notifier<ThemeSettings> {
  static const _modeKey = 'theme_mode';
  static const _accentKey = 'theme_accent';
  static const _dynamicKey = 'theme_dynamic_color';

  bool _loaded = false;

  @override
  ThemeSettings build() {
    if (!_loaded) {
      _loaded = true;
      Future<void>(() => _load());
    }
    return ThemeSettings.fallback;
  }

  Future<void> setMode(AppThemeMode mode) async {
    state = state.copyWith(mode: mode);
    await _persist();
  }

  Future<void> setAccent(AppAccentColor accent) async {
    state = state.copyWith(accent: accent);
    await _persist();
  }

  Future<void> setUseDynamicColor(bool enabled) async {
    state = state.copyWith(useDynamicColor: enabled);
    await _persist();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final modeName = prefs.getString(_modeKey);
    final accentName = prefs.getString(_accentKey);
    final useDynamicColor = prefs.getBool(_dynamicKey);

    state = ThemeSettings(
      mode: AppThemeMode.values.firstWhere(
        (value) => value.name == modeName,
        orElse: () => ThemeSettings.fallback.mode,
      ),
      accent: AppAccentColor.values.firstWhere(
        (value) => value.name == accentName,
        orElse: () => ThemeSettings.fallback.accent,
      ),
      useDynamicColor: useDynamicColor ?? ThemeSettings.fallback.useDynamicColor,
    );
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_modeKey, state.mode.name);
    await prefs.setString(_accentKey, state.accent.name);
    await prefs.setBool(_dynamicKey, state.useDynamicColor);
  }
}
