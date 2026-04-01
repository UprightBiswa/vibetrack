import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vibetreck/core/network/network_status_provider.dart';
import 'package:vibetreck/core/routing/app_routes.dart';
import 'package:vibetreck/core/theme/app_theme.dart';

class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.child,
    required this.currentIndex,
    required this.onSelectTab,
  });

  final Widget child;
  final int currentIndex;
  final ValueChanged<int> onSelectTab;

  @override
  Widget build(BuildContext context) {
    final isOnline = context.select((ConnectivityCubit cubit) => cubit.state);
    final currentLocation = GoRouterState.of(context).uri.path;
    final isOnHomeBranch = currentLocation == AppRoutes.home ||
        currentLocation.startsWith('${AppRoutes.home}/');

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        if (!isOnHomeBranch) {
          onSelectTab(0);
          return;
        }

        final shouldExit = await _confirmExit(context);
        if (shouldExit == true) {
          await SystemNavigator.pop();
        }
      },
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.cyberBackground,
          ),
          child: SafeArea(
            child: Column(
              children: [
                if (!isOnline)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.secondary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppTheme.secondary.withValues(alpha: 0.35),
                      ),
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
        ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: Container(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.82),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 30,
                  offset: const Offset(0, -6),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _NavItem(
                  icon: Icons.home_rounded,
                  label: 'Home',
                  selected: currentIndex == 0,
                  onTap: () => onSelectTab(0),
                ),
                _NavItem(
                  icon: Icons.map_rounded,
                  label: 'Zones',
                  selected: currentIndex == 1,
                  onTap: () => onSelectTab(1),
                ),
                _CenterNavAction(
                  selected: currentIndex == 2,
                  onTap: () => onSelectTab(2),
                ),
                _NavItem(
                  icon: Icons.dynamic_feed_rounded,
                  label: 'Feed',
                  selected: currentIndex == 3,
                  onTap: () => onSelectTab(3),
                ),
                _NavItem(
                  icon: Icons.person_rounded,
                  label: 'Profile',
                  selected: currentIndex == 4,
                  onTap: () => onSelectTab(4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<bool?> _confirmExit(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit app?'),
        content: const Text('Do you want to close VibeTrack now?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Exit'),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppTheme.primary : Colors.white54;
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CenterNavAction extends StatelessWidget {
  const _CenterNavAction({required this.selected, required this.onTap});

  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, -18),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          width: 62,
          height: 62,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [AppTheme.primary, Color(0xFFAED600)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withValues(alpha: selected ? 0.4 : 0.28),
                blurRadius: 26,
                spreadRadius: 2,
              ),
            ],
            border: Border.all(color: Colors.black.withValues(alpha: 0.65), width: 4),
          ),
          child: const Icon(Icons.bolt_rounded, color: Colors.black, size: 30),
        ),
      ),
    );
  }
}
