import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vibetreck/core/config/app_env.dart';
import 'package:vibetreck/core/notifications/push_notifications_service.dart';
import 'package:vibetreck/core/routing/app_routes.dart';
import 'package:vibetreck/core/theme/theme_controller.dart';
import 'package:vibetreck/features/auth/application/auth_controller.dart';
import 'package:vibetreck/features/notifications/application/notification_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final env = ref.watch(appEnvProvider);
    final user = ref.watch(authUserProvider).asData?.value;
    final themeSettings = ref.watch(themeControllerProvider);
    final themeActions = ref.read(themeControllerProvider.notifier);
    final unreadNotifications = ref.watch(unreadNotificationCountProvider).asData?.value ?? 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.manage_accounts_rounded),
                  title: const Text('Account'),
                  subtitle: Text(user?.email ?? 'Not signed in'),
                ),
                if (user != null)
                  ListTile(
                    leading: const Icon(Icons.logout_rounded),
                    title: const Text('Sign out'),
                    subtitle: const Text('This device will stop receiving account notifications until you sign in again.'),
                    onTap: () => _confirmSignOut(context, ref),
                  )
                else
                  ListTile(
                    leading: const Icon(Icons.login_rounded),
                    title: const Text('Go to sign in'),
                    onTap: () => context.go(AppRoutes.auth),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.notifications_active_rounded),
                  title: const Text('Notifications'),
                  subtitle: Text(
                    unreadNotifications > 0
                        ? '$unreadNotifications unread notification(s)'
                        : 'View your notification history and delivery status.',
                  ),
                  trailing: unreadNotifications > 0
                      ? CircleAvatar(
                          radius: 12,
                          child: Text(
                            '$unreadNotifications',
                            style: const TextStyle(fontSize: 11),
                          ),
                        )
                      : const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.go(AppRoutes.notifications),
                ),
                ListTile(
                  leading: const Icon(Icons.developer_mode_rounded),
                  title: const Text('Backend API'),
                  subtitle: Text(
                    env.hasBackendApi ? env.effectiveBackendApiUrl : 'Not configured',
                  ),
                ),
                if (env.backendSetupHint != null)
                  ListTile(
                    leading: const Icon(Icons.info_outline_rounded),
                    title: const Text('Backend setup hint'),
                    subtitle: Text(env.backendSetupHint!),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.brightness_6_rounded),
                  title: const Text('Theme mode'),
                  subtitle: const Text('Choose how the app follows light and dark appearance.'),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: SegmentedButton<AppThemeMode>(
                    segments: const [
                      ButtonSegment(
                        value: AppThemeMode.system,
                        label: Text('System'),
                        icon: Icon(Icons.phone_android_rounded),
                      ),
                      ButtonSegment(
                        value: AppThemeMode.light,
                        label: Text('Light'),
                        icon: Icon(Icons.light_mode_rounded),
                      ),
                      ButtonSegment(
                        value: AppThemeMode.dark,
                        label: Text('Dark'),
                        icon: Icon(Icons.dark_mode_rounded),
                      ),
                    ],
                    selected: {themeSettings.mode},
                    onSelectionChanged: (selection) {
                      themeActions.setMode(selection.first);
                    },
                  ),
                ),
                SwitchListTile(
                  value: themeSettings.useDynamicColor,
                  onChanged: themeActions.setUseDynamicColor,
                  secondary: const Icon(Icons.color_lens_rounded),
                  title: const Text('Use dynamic color'),
                  subtitle: const Text('Use your device wallpaper colors when supported.'),
                ),
                ListTile(
                  leading: const Icon(Icons.palette_rounded),
                  title: const Text('Accent color'),
                  subtitle: const Text('Pick a fallback accent when dynamic color is off or unavailable.'),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: AppAccentColor.values.map((accent) {
                      final isSelected = themeSettings.accent == accent;
                      final color = _accentPreviewColor(accent);
                      return InkWell(
                        borderRadius: BorderRadius.circular(999),
                        onTap: () => themeActions.setAccent(accent),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? Theme.of(context).colorScheme.onSurface
                                  : Colors.transparent,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: color.withValues(alpha: 0.34),
                                blurRadius: 14,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: isSelected
                              ? const Icon(Icons.check_rounded, color: Colors.black)
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('You will be returned to the login screen and this device token will be removed from your account.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await ref.read(pushNotificationsServiceProvider).unregisterCurrentDevice();
    await ref.read(authActionsProvider).signOut();
    ref.read(notificationActionsProvider).refresh();
    if (context.mounted) {
      context.go(AppRoutes.auth);
    }
  }

  Color _accentPreviewColor(AppAccentColor accent) {
    switch (accent) {
      case AppAccentColor.lime:
        return const Color(0xFFD6FF3F);
      case AppAccentColor.teal:
        return const Color(0xFF38E0C4);
      case AppAccentColor.coral:
        return const Color(0xFFFF7A59);
      case AppAccentColor.sky:
        return const Color(0xFF52B6FF);
    }
  }
}
