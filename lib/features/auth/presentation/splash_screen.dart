import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vibetreck/core/providers/repositories.dart';
import 'package:vibetreck/core/routing/app_routes.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 900), _routeNext);
  }

  void _routeNext() {
    if (!mounted) return;
    final authRepository = ref.read(authRepositoryProvider);
    final isLoggedIn = authRepository.currentUser() != null;
    context.go(isLoggedIn ? AppRoutes.home : AppRoutes.auth);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0B0B0B), Color(0xFF191919)],
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.pedal_bike_rounded, size: 56, color: Color(0xFFCCFF00)),
              SizedBox(height: 16),
              Text(
                'VibeTrack',
                style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900),
              ),
              SizedBox(height: 10),
              Text(
                'Ride. Share. Capture your city.',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
