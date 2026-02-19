import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vibetreck/core/network/network_status_provider.dart';

class AppScaffold extends ConsumerWidget {
  const AppScaffold({
    super.key,
    required this.child,
    required this.location,
    required this.onTapTab,
  });

  final Widget child;
  final String location;
  final ValueChanged<int> onTapTab;

  static const _tabs = <String>[
    '/home',
    '/feed',
    '/zones',
    '/profile',
    '/settings',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(isOnlineProvider);
    final selected = _tabs.indexWhere((path) => location.startsWith(path));
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            if (!isOnline)
              Container(
                width: double.infinity,
                color: Colors.redAccent.withValues(alpha: 0.22),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                child: const Text(
                  'Offline mode: some features may not sync.',
                  textAlign: TextAlign.center,
                ),
              ),
            Expanded(child: child),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selected < 0 ? 0 : selected,
        onDestinationSelected: onTapTab,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.dynamic_feed_rounded),
            label: 'Feed',
          ),
          NavigationDestination(icon: Icon(Icons.map_rounded), label: 'Zones'),
          NavigationDestination(
            icon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
