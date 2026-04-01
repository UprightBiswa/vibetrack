import 'dart:async';

import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vibetreck/core/di/app_services.dart';
import 'package:vibetreck/core/network/network_status_provider.dart';
import 'package:vibetreck/core/notifications/push_notifications_service.dart';
import 'package:vibetreck/core/routing/app_router.dart';
import 'package:vibetreck/core/theme/app_theme.dart';
import 'package:vibetreck/core/theme/theme_controller.dart';
import 'package:vibetreck/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:vibetreck/features/feed/application/feed_controller.dart';
import 'package:vibetreck/features/notifications/application/notification_controller.dart';
import 'package:vibetreck/features/profile/presentation/bloc/current_profile_cubit.dart';
import 'package:vibetreck/features/tracking/application/tracking_controller.dart';
import 'package:vibetreck/features/zones/application/zone_controller.dart';

class VibeTrackApp extends StatefulWidget {
  const VibeTrackApp({super.key, required this.services});

  final AppServices services;

  @override
  State<VibeTrackApp> createState() => _VibeTrackAppState();
}

class _VibeTrackAppState extends State<VibeTrackApp> {
  late final GlobalKey<NavigatorState> _navigatorKey;
  late final GoRouter _router;
  late final ThemeController _themeController;
  late final ConnectivityCubit _connectivityCubit;
  late final AuthCubit _authCubit;
  late final CurrentProfileCubit _currentProfileCubit;
  late final NotificationsCubit _notificationsCubit;
  late final FeedCubit _feedCubit;
  late final ZonesCubit _zonesCubit;
  late final TrackingCubit _trackingCubit;
  late final PushNotificationsService _pushNotificationsService;
  StreamSubscription? _authSubscription;

  @override
  void initState() {
    super.initState();
    _navigatorKey = GlobalKey<NavigatorState>();
    _router = createAppRouter(
      authRepository: widget.services.authRepository,
      navigatorKey: _navigatorKey,
    );
    _themeController = ThemeController();
    _connectivityCubit = ConnectivityCubit();
    _authCubit = AuthCubit(widget.services.authRepository);
    _currentProfileCubit = CurrentProfileCubit(
      profileRepository: widget.services.profileRepository,
      authCubit: _authCubit,
    );
    _notificationsCubit = NotificationsCubit(widget.services.notificationRepository);
    _feedCubit = FeedCubit(
      repository: widget.services.feedRepository,
      connectivityCubit: _connectivityCubit,
      authCubit: _authCubit,
    )..load();
    _zonesCubit = ZonesCubit(widget.services.zoneRepository)..load();
    _trackingCubit = TrackingCubit(
      sessionRepository: widget.services.sessionRepository,
      profileRepository: widget.services.profileRepository,
      authCubit: _authCubit,
    );
    _pushNotificationsService = PushNotificationsService(
      apiClient: widget.services.apiClient,
      authCubit: _authCubit,
      notificationsCubit: _notificationsCubit,
      navigatorKey: _navigatorKey,
    );
    _authSubscription = _authCubit.stream.listen((state) {
      if (state.user != null) {
        _notificationsCubit.load();
      }
    });
    Future<void>(() async {
      await _pushNotificationsService.initialize();
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _pushNotificationsService.dispose();
    _trackingCubit.close();
    _zonesCubit.close();
    _feedCubit.close();
    _notificationsCubit.close();
    _currentProfileCubit.close();
    _authCubit.close();
    _connectivityCubit.close();
    _themeController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AppServices>.value(value: widget.services),
        RepositoryProvider<PushNotificationsService>.value(
          value: _pushNotificationsService,
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<ThemeController>.value(value: _themeController),
          BlocProvider<ConnectivityCubit>.value(value: _connectivityCubit),
          BlocProvider<AuthCubit>.value(value: _authCubit),
          BlocProvider<CurrentProfileCubit>.value(value: _currentProfileCubit),
          BlocProvider<NotificationsCubit>.value(value: _notificationsCubit),
          BlocProvider<FeedCubit>.value(value: _feedCubit),
          BlocProvider<ZonesCubit>.value(value: _zonesCubit),
          BlocProvider<TrackingCubit>.value(value: _trackingCubit),
        ],
        child: DynamicColorBuilder(
          builder: (lightDynamic, darkDynamic) {
            return BlocBuilder<ThemeController, ThemeSettings>(
              builder: (context, themeSettings) {
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
                  routerConfig: _router,
                );
              },
            );
          },
        ),
      ),
    );
  }
}
