import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vibetreck/core/routing/app_routes.dart';
import 'package:vibetreck/core/theme/app_theme.dart';
import 'package:vibetreck/features/feed/application/feed_controller.dart';
import 'package:vibetreck/features/notifications/application/notification_controller.dart';
import 'package:vibetreck/features/profile/presentation/bloc/current_profile_cubit.dart';
import 'package:vibetreck/features/tracking/application/tracking_controller.dart';
import 'package:vibetreck/features/zones/application/zone_controller.dart';
import 'package:vibetreck/shared/models/feed_post.dart';
import 'package:vibetreck/shared/models/user_profile.dart';
import 'package:vibetreck/shared/models/zone.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<CurrentProfileCubit>().state.profile;
    final tracking = context.watch<TrackingCubit>().state;
    final zones = context.watch<ZonesCubit>().state.zones;
    final feedPosts = context.watch<FeedCubit>().state.posts;
    final unreadCount = context.watch<NotificationsCubit>().state.unreadCount;

    final profilePosts = profile == null
        ? const <FeedPost>[]
        : context.watch<FeedCubit>().postsForUser(profile.id);
    final latestPost = _pickLatestPost(profilePosts, feedPosts);
    final featuredZone = _pickFeaturedZone(zones);
    final liveDistanceKm = tracking.distanceM / 1000;
    final publishedDistanceKm = profilePosts.fold<double>(
      0,
      (sum, post) => sum + _doubleFrom(post.statsJson['distanceKm']),
    );
    final progress = _auraProgress(profile?.auraPoints ?? 0);

    return RefreshIndicator(
      onRefresh: () async {
        await context.read<CurrentProfileCubit>().refresh();
        await context.read<FeedCubit>().refresh();
        await context.read<ZonesCubit>().load();
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 140),
        children: [
          _DashboardHeader(
            profile: profile,
            unreadCount: unreadCount,
          ),
          const SizedBox(height: 18),
          _AuraHeroCard(
            profile: profile,
            progress: progress,
            onTapLeaderboard: () => context.push(AppRoutes.leaderboard),
          ),
          const SizedBox(height: 16),
          _ZonePanel(
            zone: featuredZone,
            isGuardian: profile != null &&
                featuredZone?.currentGuardianUserId == profile.id,
            onTap: () => context.go(AppRoutes.zones),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _MetricPanel(
                  icon: Icons.local_fire_department_rounded,
                  iconColor: AppTheme.primary,
                  label: 'Streak',
                  value: '${profile?.currentStreakDays ?? 0}',
                  unit: 'days',
                  footerLabel: (profile?.activeToday ?? false)
                      ? 'Active today'
                      : 'Ride today',
                  footerProgress: ((profile?.currentStreakDays ?? 0) / 7).clamp(0, 1),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricPanel(
                  icon: Icons.speed_rounded,
                  iconColor: AppTheme.glowSky,
                  label: tracking.running ? 'Live Session' : 'Published',
                  value: tracking.running
                      ? liveDistanceKm.toStringAsFixed(2)
                      : publishedDistanceKm.toStringAsFixed(1),
                  unit: 'km',
                  footerLabel: tracking.running
                      ? '${tracking.durationS ~/ 60} min running'
                      : '${profilePosts.length} ride posts',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SocialPulseTile(
            post: latestPost,
            onTap: latestPost == null
                ? null
                : () => context.push(AppRoutes.feedPost(latestPost.id)),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => context.go(AppRoutes.tracking),
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text(tracking.running ? 'Resume Live Session' : 'Start Session'),
            ),
          ),
          const SizedBox(height: 22),
          Text(
            'System Telemetry',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Colors.white60,
                  letterSpacing: 1.2,
                ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _TelemetryCard(
                  label: 'Aura',
                  value: '${profile?.auraPoints ?? 0}',
                  accent: AppTheme.secondary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _TelemetryCard(
                  label: 'Rank',
                  value: profile?.globalRank != null ? '#${profile!.globalRank}' : '--',
                  accent: AppTheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _TelemetryCard(
                  label: 'Longest Streak',
                  value: '${profile?.longestStreakDays ?? 0}d',
                  accent: AppTheme.glowCoral,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _TelemetryCard(
                  label: 'Zone Multiplier',
                  value: featuredZone == null
                      ? '--'
                      : 'x${featuredZone.scoreMultiplier.toStringAsFixed(1)}',
                  accent: AppTheme.glowSky,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({
    required this.profile,
    required this.unreadCount,
  });

  final UserProfile? profile;
  final int unreadCount;

  @override
  Widget build(BuildContext context) {
    final displayName = (profile?.username.trim().isNotEmpty ?? false)
        ? profile!.username.trim()
        : 'Rider';
    final city = (profile?.homeCity.trim().isNotEmpty ?? false)
        ? profile!.homeCity.trim().toUpperCase()
        : 'CONNECTED TO THE STREETS';

    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.primary.withValues(alpha: 0.7)),
            gradient: LinearGradient(
              colors: [
                AppTheme.primary.withValues(alpha: 0.9),
                Colors.white.withValues(alpha: 0.25),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            displayName.characters.first.toUpperCase(),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.black,
                  fontWeight: FontWeight.w900,
                ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome back',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white54,
                      letterSpacing: 0.8,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                displayName.toUpperCase(),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                city,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppTheme.primary,
                      letterSpacing: 0.9,
                    ),
              ),
            ],
          ),
        ),
        _HeaderAction(
          icon: Icons.notifications_rounded,
          activeCount: unreadCount,
          onTap: () => context.push(AppRoutes.notifications),
        ),
        const SizedBox(width: 10),
        _HeaderAction(
          icon: Icons.tune_rounded,
          onTap: () => context.push(AppRoutes.settings),
        ),
      ],
    );
  }
}

class _AuraHeroCard extends StatelessWidget {
  const _AuraHeroCard({
    required this.profile,
    required this.progress,
    required this.onTapLeaderboard,
  });

  final UserProfile? profile;
  final double progress;
  final VoidCallback onTapLeaderboard;

  @override
  Widget build(BuildContext context) {
    final aura = profile?.auraPoints ?? 0;
    final rank = profile?.globalRank != null ? '#${profile!.globalRank}' : 'UNRANKED';
    final streak = profile?.currentStreakDays ?? 0;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF09090B),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppTheme.secondary.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.secondary.withValues(alpha: 0.14),
            blurRadius: 28,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -12,
            top: -8,
            child: Icon(
              Icons.shield_rounded,
              size: 100,
              color: AppTheme.secondary.withValues(alpha: 0.14),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Aura Points',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppTheme.secondary,
                          letterSpacing: 1.5,
                        ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      height: 1,
                      color: AppTheme.secondary.withValues(alpha: 0.18),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatNumber(aura),
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          height: 1,
                        ),
                  ),
                  const SizedBox(width: 10),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      'AP',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppTheme.secondary,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Rank: $rank  |  $streak day streak',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white70,
                    ),
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  minHeight: 8,
                  value: progress,
                  backgroundColor: Colors.white.withValues(alpha: 0.08),
                  color: AppTheme.secondary,
                ),
              ),
              const SizedBox(height: 18),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: onTapLeaderboard,
                  child: const Text('Leaderboard'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ZonePanel extends StatelessWidget {
  const _ZonePanel({
    required this.zone,
    required this.isGuardian,
    required this.onTap,
  });

  final Zone? zone;
  final bool isGuardian;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final title = zone?.name.isNotEmpty == true ? zone!.name : 'No active zone';
    final city = zone?.city.isNotEmpty == true ? zone!.city : 'Awaiting territory sync';
    final multiplier = zone == null ? '--' : 'x${zone!.scoreMultiplier.toStringAsFixed(1)}';
    final status = zone == null
        ? 'Open Zones'
        : isGuardian
        ? 'CONTROLLED'
        : 'CONTESTED';

    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Container(
        height: 220,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            colors: [Color(0xFF090A0D), Color(0xFF11151B), Color(0xFF0D1012)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Stack(
          children: [
            const Positioned.fill(child: _GridPainterWidget()),
            Positioned(
              right: 10,
              top: 10,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.primary.withValues(alpha: 0.25)),
                ),
                child: const Icon(Icons.explore_rounded, color: AppTheme.primary, size: 18),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Current Zone',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                  ),
                ),
                const Spacer(),
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  city,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                      ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _ZoneMeta(label: 'Status', value: status),
                    const SizedBox(width: 18),
                    _ZoneMeta(label: 'Multiplier', value: multiplier),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricPanel extends StatelessWidget {
  const _MetricPanel({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.unit,
    required this.footerLabel,
    this.footerProgress,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String unit;
  final String footerLabel;
  final double? footerProgress;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 164,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0B0D10),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor),
          const SizedBox(height: 10),
          Text(
            label.toUpperCase(),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Colors.white54,
                  letterSpacing: 1,
                ),
          ),
          const SizedBox(height: 4),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                ),
                TextSpan(
                  text: ' $unit',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Colors.white38,
                      ),
                ),
              ],
            ),
          ),
          const Spacer(),
          if (footerProgress != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                minHeight: 6,
                value: footerProgress,
                backgroundColor: Colors.white.withValues(alpha: 0.06),
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 8),
          ],
          Text(
            footerLabel,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Colors.white60,
                ),
          ),
        ],
      ),
    );
  }
}

class _SocialPulseTile extends StatelessWidget {
  const _SocialPulseTile({
    required this.post,
    required this.onTap,
  });

  final FeedPost? post;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final title = post == null
        ? 'No ride posts yet'
        : '${post!.username.toUpperCase()} shared ${post!.caption.isEmpty ? 'a fresh ride' : '"${post!.caption}"'}';
    final subtitle = post == null
        ? 'Finish and publish a session to start the social feed pulse.'
        : '${post!.commentCount} comments | ${post!.likeCount} likes';

    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppTheme.primary.withValues(alpha: 0.18)),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.groups_rounded, color: AppTheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white54,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const Icon(Icons.chevron_right_rounded, color: Colors.white38),
          ],
        ),
      ),
    );
  }
}

class _TelemetryCard extends StatelessWidget {
  const _TelemetryCard({
    required this.label,
    required this.value,
    required this.accent,
  });

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF101317),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Colors.white54,
                  letterSpacing: 1,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w900,
                ),
          ),
        ],
      ),
    );
  }
}

class _HeaderAction extends StatelessWidget {
  const _HeaderAction({
    required this.icon,
    required this.onTap,
    this.activeCount = 0,
  });

  final IconData icon;
  final VoidCallback onTap;
  final int activeCount;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFF0D1116),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: Icon(icon, color: Colors.white70),
          ),
          if (activeCount > 0)
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(999),
                ),
                alignment: Alignment.center,
                child: Text(
                  activeCount > 9 ? '9+' : '$activeCount',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.black,
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ZoneMeta extends StatelessWidget {
  const _ZoneMeta({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Colors.white54,
                letterSpacing: 0.9,
              ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
      ],
    );
  }
}

class _GridPainterWidget extends StatelessWidget {
  const _GridPainterWidget();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _GridPainter(),
      child: const SizedBox.expand(),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = AppTheme.primary.withValues(alpha: 0.06)
      ..strokeWidth = 1;
    const step = 28.0;
    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);
    }
    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

FeedPost? _pickLatestPost(List<FeedPost> profilePosts, List<FeedPost> allPosts) {
  if (profilePosts.isNotEmpty) {
    final sorted = [...profilePosts]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted.first;
  }
  if (allPosts.isNotEmpty) {
    final sorted = [...allPosts]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted.first;
  }
  return null;
}

Zone? _pickFeaturedZone(List<Zone> zones) {
  if (zones.isEmpty) return null;
  final sorted = [...zones]
    ..sort((a, b) => b.scoreMultiplier.compareTo(a.scoreMultiplier));
  return sorted.first;
}

double _auraProgress(int auraPoints) {
  const bucket = 1000;
  final remainder = auraPoints % bucket;
  return math.max(remainder / bucket, auraPoints == 0 ? 0.08 : 0.12);
}

String _formatNumber(int value) {
  if (value >= 1000) {
    final compact = value / 1000;
    return compact % 1 == 0 ? '${compact.toStringAsFixed(0)}K' : '${compact.toStringAsFixed(1)}K';
  }
  return '$value';
}

double _doubleFrom(Object? value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0;
}
