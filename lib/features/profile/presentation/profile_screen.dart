import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:vibetreck/core/bloc/view_status.dart';
import 'package:vibetreck/core/routing/app_routes.dart';
import 'package:vibetreck/core/theme/app_theme.dart';
import 'package:vibetreck/features/feed/application/feed_controller.dart';
import 'package:vibetreck/features/feed/presentation/feed_screen.dart';
import 'package:vibetreck/features/profile/presentation/bloc/current_profile_cubit.dart';
import 'package:vibetreck/features/profile/presentation/bloc/current_profile_state.dart';
import 'package:vibetreck/shared/models/feed_post.dart';
import 'package:vibetreck/shared/models/user_profile.dart';
import 'package:vibetreck/shared/widgets/app_empty_state.dart';
import 'package:vibetreck/shared/widgets/app_error_state.dart';
import 'package:vibetreck/shared/widgets/bento_card.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profileState = context.watch<CurrentProfileCubit>().state;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            onPressed: () => context.push(AppRoutes.editProfile),
            icon: const Icon(Icons.edit_rounded),
          ),
        ],
      ),
      body: switch (profileState.status) {
        ViewStatus.loading => const Center(child: CircularProgressIndicator()),
        ViewStatus.failure => AppErrorState(
            message: profileState.errorMessage ?? 'Failed to load profile',
            onRetry: () => context.read<CurrentProfileCubit>().refresh(),
          ),
        _ => _buildContent(context, profileState.profile),
      },
    );
  }

  Widget _buildContent(BuildContext context, UserProfile? profile) {
    if (profile == null) {
      return const AppEmptyState(
        title: 'Profile unavailable',
        message: 'Sign in again to load your rider profile.',
        icon: Icons.person_off_rounded,
      );
    }

    final posts = context.watch<FeedCubit>().postsForUser(profile.id);
    final analytics = _ProfileAnalytics.fromPosts(posts);
    return RefreshIndicator(
      onRefresh: () async {
        await context.read<CurrentProfileCubit>().refresh();
        await context.read<FeedCubit>().refresh();
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _ProfileHero(profile: profile, analytics: analytics),
          const SizedBox(height: 18),
          _AnalyticsGrid(profile: profile, analytics: analytics),
          const SizedBox(height: 18),
          _SectionHeader(
            title: 'Ride Signals',
            actionLabel: 'Leaderboard',
            onTap: () => context.push(AppRoutes.leaderboard),
          ),
          const SizedBox(height: 12),
          _SignalStrip(profile: profile, analytics: analytics),
          const SizedBox(height: 20),
          _SectionHeader(
            title: 'Own Feed',
            actionLabel: 'Global feed',
            onTap: () => context.go(AppRoutes.feed),
          ),
          const SizedBox(height: 12),
          if (posts.isEmpty)
            const AppEmptyState(
              title: 'No rides published yet',
              message:
                  'Finish a session and publish it to start building your public rider profile.',
              icon: Icons.directions_bike_outlined,
            )
          else
            ...posts.map(
              (post) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _OwnPostCard(post: post),
              ),
            ),
        ],
      ),
    );
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({required this.profile, required this.analytics});

  final UserProfile profile;
  final _ProfileAnalytics analytics;

  @override
  Widget build(BuildContext context) {
    final rawName = profile.username.trim();
    final avatarInitial = rawName.isEmpty ? 'R' : rawName.characters.first.toUpperCase();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.zoneHeroGradient,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: AppTheme.primary.withValues(alpha: 0.18),
                child: Text(
                  avatarInitial,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.black,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rawName.isEmpty ? 'Rider' : rawName,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      profile.email ?? 'No email synced',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white70,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _HeroPill(
                          label: profile.homeCity.trim().isEmpty
                              ? 'CITY UNSET'
                              : profile.homeCity.toUpperCase(),
                        ),
                        _HeroPill(
                          label: profile.globalRank != null
                              ? 'GLOBAL #${profile.globalRank}'
                              : 'GLOBAL --',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'Own the map with consistent rides, sharp posts, and a stronger aura footprint every week.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white70,
                  height: 1.4,
                ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _HeroStat(label: 'Aura', value: '${profile.auraPoints}'),
              _HeroStat(
                label: 'Distance',
                value: '${analytics.totalDistanceKm.toStringAsFixed(1)} km',
              ),
              _HeroStat(label: 'Posts', value: '${analytics.postCount}'),
              _HeroStat(
                label: 'Engagement',
                value: '${analytics.totalLikes + analytics.totalComments}',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AnalyticsGrid extends StatelessWidget {
  const _AnalyticsGrid({required this.profile, required this.analytics});

  final UserProfile profile;
  final _ProfileAnalytics analytics;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.18,
      children: [
        BentoCard(
          title: 'Current Streak',
          value: '${profile.currentStreakDays ?? 0} days',
          subtitle: (profile.activeToday ?? false)
              ? 'Locked in today'
              : 'Ride today to keep the chain alive',
          accent: AppTheme.primary,
        ),
        BentoCard(
          title: 'Longest Streak',
          value: '${profile.longestStreakDays ?? 0} days',
          subtitle: 'Best consistency run',
          accent: AppTheme.secondary,
        ),
        BentoCard(
          title: 'Total Ride Time',
          value: analytics.totalDurationLabel,
          subtitle: 'Across published rides',
          accent: const Color(0xFF52B6FF),
        ),
        BentoCard(
          title: 'Avg Ride',
          value: analytics.averageDistanceLabel,
          subtitle: 'Per published post',
          accent: const Color(0xFFFF7A59),
        ),
      ],
    );
  }
}

class _SignalStrip extends StatelessWidget {
  const _SignalStrip({required this.profile, required this.analytics});

  final UserProfile profile;
  final _ProfileAnalytics analytics;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SignalTile(
          icon: Icons.favorite_rounded,
          title: 'Post likes',
          value: '${analytics.totalLikes}',
          subtitle: 'Total appreciation across your published rides',
        ),
        const SizedBox(height: 10),
        _SignalTile(
          icon: Icons.mode_comment_rounded,
          title: 'Comments received',
          value: '${analytics.totalComments}',
          subtitle: 'Conversation generated by your ride posts',
        ),
        const SizedBox(height: 10),
        _SignalTile(
          icon: Icons.local_fire_department_rounded,
          title: 'Best ride',
          value: analytics.bestRideDistanceLabel,
          subtitle: 'Longest distance published from your own feed',
        ),
      ],
    );
  }
}

class _OwnPostCard extends StatelessWidget {
  const _OwnPostCard({required this.post});

  final FeedPost post;

  @override
  Widget build(BuildContext context) {
    final distance = _doubleFrom(post.statsJson['distanceKm']);
    final duration = _doubleFrom(post.statsJson['durationMin']);
    final calories = _doubleFrom(post.statsJson['calories']);

    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () => context.push(AppRoutes.feedPost(post.id)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.surface,
              Colors.white.withValues(alpha: 0.03),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.border.withValues(alpha: 0.75)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              child: SizedBox(
                height: 220,
                width: double.infinity,
                child: PostMedia(post: post, stats: post.statsJson),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          post.caption.isEmpty ? 'Ride completed' : post.caption,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        DateFormat('MMM d').format(post.createdAt),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.white54,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _MiniMetricChip(label: 'Distance', value: '${distance.toStringAsFixed(2)} km'),
                      _MiniMetricChip(label: 'Duration', value: '${duration.toStringAsFixed(0)} min'),
                      _MiniMetricChip(label: 'Calories', value: '${calories.toStringAsFixed(0)} kcal'),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      _IconStat(icon: Icons.favorite_rounded, value: '${post.likeCount}'),
                      const SizedBox(width: 16),
                      _IconStat(icon: Icons.mode_comment_rounded, value: '${post.commentCount}'),
                      const Spacer(),
                      Text(
                        'Open details',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: AppTheme.primary,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.actionLabel, required this.onTap});

  final String title;
  final String actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(title, style: Theme.of(context).textTheme.titleLarge)),
        TextButton(onPressed: onTap, child: Text(actionLabel)),
      ],
    );
  }
}

class _HeroPill extends StatelessWidget {
  const _HeroPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Colors.white70,
              letterSpacing: 0.8,
            ),
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 110,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Colors.white60,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

class _SignalTile extends StatelessWidget {
  const _SignalTile({required this.icon, required this.title, required this.value, required this.subtitle});

  final IconData icon;
  final String title;
  final String value;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.85)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppTheme.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white60,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppTheme.primary,
                ),
          ),
        ],
      ),
    );
  }
}

class _MiniMetricChip extends StatelessWidget {
  const _MiniMetricChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Text(
        '$label  $value',
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Colors.white70,
            ),
      ),
    );
  }
}

class _IconStat extends StatelessWidget {
  const _IconStat({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: Colors.white60),
        const SizedBox(width: 6),
        Text(value, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

class _ProfileAnalytics {
  const _ProfileAnalytics({
    required this.postCount,
    required this.totalLikes,
    required this.totalComments,
    required this.totalDistanceKm,
    required this.totalDurationMin,
    required this.totalCalories,
    required this.bestRideDistanceKm,
  });

  final int postCount;
  final int totalLikes;
  final int totalComments;
  final double totalDistanceKm;
  final double totalDurationMin;
  final double totalCalories;
  final double bestRideDistanceKm;

  String get totalDurationLabel {
    final totalMinutes = totalDurationMin.round();
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    if (hours == 0) return '${minutes}m';
    return '${hours}h ${minutes}m';
  }

  String get averageDistanceLabel {
    if (postCount == 0) return '0.0 km';
    return '${(totalDistanceKm / postCount).toStringAsFixed(1)} km';
  }

  String get bestRideDistanceLabel => '${bestRideDistanceKm.toStringAsFixed(1)} km';

  factory _ProfileAnalytics.fromPosts(List<FeedPost> posts) {
    var likes = 0;
    var comments = 0;
    var distance = 0.0;
    var duration = 0.0;
    var calories = 0.0;
    var bestRide = 0.0;

    for (final post in posts) {
      likes += post.likeCount;
      comments += post.commentCount;
      final rideDistance = _doubleFrom(post.statsJson['distanceKm']);
      distance += rideDistance;
      duration += _doubleFrom(post.statsJson['durationMin']);
      calories += _doubleFrom(post.statsJson['calories']);
      if (rideDistance > bestRide) {
        bestRide = rideDistance;
      }
    }

    return _ProfileAnalytics(
      postCount: posts.length,
      totalLikes: likes,
      totalComments: comments,
      totalDistanceKm: distance,
      totalDurationMin: duration,
      totalCalories: calories,
      bestRideDistanceKm: bestRide,
    );
  }
}

double _doubleFrom(Object? value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0;
}
