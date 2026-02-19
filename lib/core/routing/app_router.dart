import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vibetreck/core/routing/app_scaffold.dart';
import 'package:vibetreck/features/auth/presentation/auth_screen.dart';
import 'package:vibetreck/features/auth/presentation/splash_screen.dart';
import 'package:vibetreck/features/feed/presentation/feed_screen.dart';
import 'package:vibetreck/features/home/presentation/home_screen.dart';
import 'package:vibetreck/features/profile/presentation/profile_screen.dart';
import 'package:vibetreck/features/settings/presentation/settings_screen.dart';
import 'package:vibetreck/features/tracking/presentation/session_summary_screen.dart';
import 'package:vibetreck/features/tracking/presentation/tracking_screen.dart';
import 'package:vibetreck/features/zones/presentation/zones_screen.dart';

final navigatorKeyProvider = Provider<GlobalKey<NavigatorState>>(
  (ref) => GlobalKey<NavigatorState>(),
);

final appRouterProvider = Provider<GoRouter>((ref) {
  final navKey = ref.watch(navigatorKeyProvider);
  return GoRouter(
    navigatorKey: navKey,
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/auth', builder: (context, state) => const AuthScreen()),
      ShellRoute(
        builder: (context, state, child) {
          return AppScaffold(
            location: state.uri.path,
            onTapTab: (index) {
              const paths = [
                '/home',
                '/feed',
                '/zones',
                '/profile',
                '/settings',
              ];
              context.go(paths[index]);
            },
            child: child,
          );
        },
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/feed',
            builder: (context, state) => const FeedScreen(),
          ),
          GoRoute(
            path: '/zones',
            builder: (context, state) => const ZonesScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/tracking',
        builder: (context, state) => const TrackingScreen(),
      ),
      GoRoute(
        path: '/summary/:sessionId',
        builder: (context, state) => SessionSummaryScreen(
          sessionId: state.pathParameters['sessionId'] ?? '',
        ),
      ),
    ],
  );
});
