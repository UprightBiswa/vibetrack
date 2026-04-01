import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vibetreck/core/notifications/push_notifications_service.dart';
import 'package:vibetreck/core/routing/app_router.dart';
import 'package:vibetreck/core/theme/app_theme.dart';
import 'package:vibetreck/core/theme/theme_controller.dart';

class VibeTrackApp extends ConsumerStatefulWidget {
  const VibeTrackApp({super.key});

  @override
  ConsumerState<VibeTrackApp> createState() => _VibeTrackAppState();
}

class _VibeTrackAppState extends ConsumerState<VibeTrackApp> {
  @override
  void initState() {
    super.initState();
    Future<void>(() async {
      await ref.read(pushNotificationsServiceProvider).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
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
