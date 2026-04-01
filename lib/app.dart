import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vibetreck/core/notifications/push_notifications_service.dart';
import 'package:vibetreck/core/providers/repositories.dart';
import 'package:vibetreck/core/routing/app_router.dart';
import 'package:vibetreck/core/theme/app_theme.dart';
import 'package:vibetreck/core/theme/theme_controller.dart';
import 'package:vibetreck/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:vibetreck/features/profile/presentation/bloc/current_profile_cubit.dart';

class VibeTrackApp extends ConsumerStatefulWidget {
  const VibeTrackApp({super.key});

  @override
  ConsumerState<VibeTrackApp> createState() => _VibeTrackAppState();
}

class _VibeTrackAppState extends ConsumerState<VibeTrackApp> {
  late final AuthCubit _authCubit;
  late final CurrentProfileCubit _currentProfileCubit;

  @override
  void initState() {
    super.initState();
    _authCubit = AuthCubit(ref.read(authRepositoryProvider));
    _currentProfileCubit = CurrentProfileCubit(
      profileRepository: ref.read(profileRepositoryProvider),
      authCubit: _authCubit,
    );
    Future<void>(() async {
      await ref.read(pushNotificationsServiceProvider).initialize();
    });
  }

  @override
  void dispose() {
    _currentProfileCubit.close();
    _authCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    final themeSettings = ref.watch(themeControllerProvider);

    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        final useDynamic = themeSettings.useDynamicColor;
        return MultiBlocProvider(
          providers: [
            BlocProvider<AuthCubit>.value(value: _authCubit),
            BlocProvider<CurrentProfileCubit>.value(value: _currentProfileCubit),
          ],
          child: MaterialApp.router(
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
          ),
        );
      },
    );
  }
}
