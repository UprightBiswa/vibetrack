import 'package:flutter/material.dart';

class AppScaffold extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final selected = _tabs.indexWhere((path) => location.startsWith(path));
    return Scaffold(
      body: SafeArea(child: child),
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
