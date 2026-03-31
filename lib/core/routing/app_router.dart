import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vibetreck/core/providers/repositories.dart';
import 'package:vibetreck/core/routing/app_routes.dart';
import 'package:vibetreck/core/routing/app_scaffold.dart';
import 'package:vibetreck/features/auth/presentation/auth_screen.dart';
import 'package:vibetreck/features/auth/presentation/splash_screen.dart';
import 'package:vibetreck/features/feed/presentation/feed_screen.dart';
import 'package:vibetreck/features/home/presentation/home_screen.dart';
import 'package:vibetreck/features/profile/presentation/edit_profile_screen.dart';
import 'package:vibetreck/features/profile/presentation/profile_screen.dart';
import 'package:vibetreck/features/profile/presentation/public_profile_screen.dart';
import 'package:vibetreck/features/settings/presentation/settings_screen.dart';
import 'package:vibetreck/features/tracking/presentation/session_summary_screen.dart';
import 'package:vibetreck/features/tracking/presentation/tracking_screen.dart';
import 'package:vibetreck/features/zones/presentation/zones_screen.dart';
import 'package:vibetreck/shared/widgets/app_error_state.dart';

final navigatorKeyProvider = Provider<GlobalKey<NavigatorState>>(
  (ref) => GlobalKey<NavigatorState>(),
);

final appRouterProvider = Provider<GoRouter>((ref) {
  final navKey = ref.watch(navigatorKeyProvider);
  final authRepository = ref.watch(authRepositoryProvider);
  final refreshListenable = GoRouterRefreshStream(
    authRepository.authStateChanges(),
  );

  ref.onDispose(refreshListenable.dispose);

  return GoRouter(
    navigatorKey: navKey,
    initialLocation: AppRoutes.splash,
    refreshListenable: refreshListenable,
    errorBuilder: (context, state) => AppErrorState(
      message: state.error.toString(),
      onRetry: () => context.go(AppRoutes.home),
    ),
    redirect: (_, state) {
      final isLoggedIn = authRepository.currentUser() != null;
      final path = state.uri.path;
      final isAuthPath = path == AppRoutes.auth;
      final isSplashPath = path == AppRoutes.splash;

      if (isSplashPath) {
        return null;
      }
      if (!isLoggedIn && !isAuthPath) {
        return AppRoutes.auth;
      }
      if (isLoggedIn && isAuthPath) {
        return AppRoutes.home;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.auth,
        builder: (context, state) => const AuthScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) {
          return AppScaffold(
            location: state.uri.path,
            onTapTab: (index) => context.go(AppRoutes.shellTabs[index]),
            child: child,
          );
        },
        routes: [
          GoRoute(
            path: AppRoutes.home,
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: AppRoutes.feed,
            builder: (context, state) => const FeedScreen(),
          ),
          GoRoute(
            path: AppRoutes.zones,
            builder: (context, state) => const ZonesScreen(),
          ),
          GoRoute(
            path: AppRoutes.profile,
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: AppRoutes.settings,
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.editProfile,
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/profile/view/:profileId',
        builder: (context, state) => PublicProfileScreen(
          profileId: state.pathParameters['profileId'] ?? '',
        ),
      ),
      GoRoute(
        path: AppRoutes.tracking,
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

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
