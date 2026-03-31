import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vibetreck/core/routing/app_router.dart';
import 'package:vibetreck/core/theme/app_theme.dart';
import 'package:vibetreck/core/theme/theme_controller.dart';

class VibeTrackApp extends ConsumerWidget {
  const VibeTrackApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeSettings = ref.watch(themeControllerProvider);

    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        final useDynamic = themeSettings.useDynamicColor;
        return MaterialApp.router(
          title: 'VibeTrack',
          debugShowCheckedModeBanner: false,
          themeMode: themeSettings.materialThemeMode,
          theme: AppTheme.lightTheme(
            accent: themeSettings.accent,
            dynamicScheme: useDynamic ? lightDynamic : null,
          ),
          darkTheme: AppTheme.darkTheme(
            accent: themeSettings.accent,
            dynamicScheme: useDynamic ? darkDynamic : null,
          ),
          routerConfig: router,
        );
      },
    );
  }
}
