import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vibetreck/core/logging/app_logger.dart';
import 'package:vibetreck/core/providers/repositories.dart';
import 'package:vibetreck/core/routing/app_router.dart';
import 'package:vibetreck/core/theme/app_theme.dart';
import 'package:vibetreck/features/auth/application/auth_controller.dart';

class VibeTrackApp extends ConsumerStatefulWidget {
  const VibeTrackApp({super.key});

  @override
  ConsumerState<VibeTrackApp> createState() => _VibeTrackAppState();
}

class _VibeTrackAppState extends ConsumerState<VibeTrackApp> {
  String? _bootstrappedUserId;

  @override
  Widget build(BuildContext context) {
    ref.listen(authUserProvider, (_, next) async {
      final user = next.asData?.value;
      if (user == null || user.id == _bootstrappedUserId) {
        return;
      }
      _bootstrappedUserId = user.id;
      try {
        await ref
            .read(profileRepositoryProvider)
            .getOrCreateProfile(userId: user.id, email: user.email);
      } catch (error, stackTrace) {
        AppLogger.error(
          'Profile bootstrap failed for ${user.id}',
          error: error,
          stackTrace: stackTrace,
        );
      }
    });

    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'VibeTrack',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: router,
    );
  }
}
