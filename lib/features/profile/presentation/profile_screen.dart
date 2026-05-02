import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:vibetreck/core/bloc/view_status.dart';
import 'package:vibetreck/core/routing/app_routes.dart';
import 'package:vibetreck/core/theme/app_theme.dart';
import 'package:vibetreck/features/feed/application/feed_controller.dart';
import 'package:vibetreck/features/feed/presentation/feed_screen.dart';
import 'package:vibetreck/features/notifications/application/notification_controller.dart';
import 'package:vibetreck/features/profile/presentation/bloc/current_profile_cubit.dart';
import 'package:vibetreck/shared/models/feed_post.dart';
import 'package:vibetreck/shared/models/user_profile.dart';
import 'package:vibetreck/shared/widgets/app_empty_state.dart';
import 'package:vibetreck/shared/widgets/app_error_state.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profileState = context.watch<CurrentProfileCubit>().state;
    return Scaffold(
      body: switch (profileState.status) {
        ViewStatus.loading => const Center(child: CircularProgressIndicator()),
        ViewStatus.failure => AppErrorState(
            message: profileState.errorMessage ?? 'Failed to load profile',
            onRetry: () => context.read<CurrentProfileCubit>().refresh(),
          ),
        _ => _ProfileBody(profile: profileState.profile),
      },
    );
  }
}

class _ProfileBody extends StatelessWidget {
  const _ProfileBody({required this.profile});

  final UserProfile? profile;

  @override
  Widget build(BuildContext context) {
    if (profile == null) {
      return const AppEmptyState(
        title: 'Profile unavailable',
        message: 'Sign in again to load your rider profile.',
        icon: Icons.person_off_rounded,
      );
    }

    final posts = context.watch<FeedCubit>().postsForUser(profile!.id)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final unreadCount = context.watch<NotificationsCubit>().state.unreadCount;
    final totalLikes = posts.fold<int>(0, (sum, p) => sum + p.likeCount);
    final totalComments = posts.fold<int>(0, (sum, p) => sum + p.commentCount);
    final totalDistance = posts.fold<double>(0, (sum, p) => sum + _num(p.statsJson['distanceKm']));
    final totalDuration = posts.fold<double>(0, (sum, p) => sum + _num(p.statsJson['durationMin']));
    final bestRide = posts.fold<double>(0, (best, p) => _num(p.statsJson['distanceKm']) > best ? _num(p.statsJson['distanceKm']) : best);
    final zoneCount = posts.isEmpty ? 0 : ((totalDistance / 60).round() + 1);
    final auraLevel = (profile!.auraPoints ~/ 200).clamp(1, 999);
    final progress = ((profile!.auraPoints % 200) / 200).clamp(0.08, 1.0);
    final eliteTag = totalDistance >= 800 ? 'ELITE OPS' : totalDistance >= 300 ? 'FIELD CORE' : totalDistance >= 100 ? 'ZONE ACTIVE' : 'RISING NODE';

    return RefreshIndicator(
      onRefresh: () async {
        await context.read<CurrentProfileCubit>().refresh();
        await context.read<FeedCubit>().refresh();
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 140),
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppTheme.primary, width: 1.5)),
                child: const Icon(Icons.bolt_rounded, color: AppTheme.primary, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                'VIBETRACK',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppTheme.primary, fontWeight: FontWeight.w900, letterSpacing: 1.4),
              ),
              const Spacer(),
              _orb(context, icon: Icons.notifications_none_rounded, badge: unreadCount, onTap: () => context.push(AppRoutes.notifications)),
              const SizedBox(width: 10),
              _orb(context, icon: Icons.tune_rounded, onTap: () => context.push(AppRoutes.settings)),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            (profile!.username.trim().isEmpty ? 'RIDER' : profile!.username.trim().toUpperCase()),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, height: 0.94),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppTheme.secondary.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: AppTheme.secondary.withValues(alpha: 0.28)),
                          ),
                          child: Text(eliteTag, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppTheme.secondary, fontWeight: FontWeight.w900, letterSpacing: 1)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        _miniStat(context, 'Aura Level', 'LVL $auraLevel', AppTheme.primary),
                        Container(width: 1, height: 44, margin: const EdgeInsets.symmetric(horizontal: 18), color: Colors.white.withValues(alpha: 0.1)),
                        _miniStat(context, 'Global Rank', profile!.globalRank != null ? '#${profile!.globalRank}' : '--', Colors.white),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () => context.go(AppRoutes.tracking),
                icon: const Icon(Icons.bolt_rounded),
                label: const Text('Activate'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: const Color(0xFF17171A),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: AppTheme.secondary.withValues(alpha: 0.2)),
              boxShadow: [BoxShadow(color: AppTheme.secondary.withValues(alpha: 0.12), blurRadius: 30)],
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Aura Points', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.white54, letterSpacing: 1.4)),
                  const SizedBox(height: 6),
                  RichText(
                    text: TextSpan(children: [
                      TextSpan(text: _compact(profile!.auraPoints), style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w900, color: Colors.white, height: 1)),
                      TextSpan(text: ' XP', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white54, fontWeight: FontWeight.w800)),
                    ]),
                  ),
                ])),
                Container(width: 52, height: 52, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(16)), child: const Icon(Icons.auto_awesome_rounded, color: AppTheme.secondary)),
              ]),
              const SizedBox(height: 18),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Progress to LVL ${auraLevel + 1}', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppTheme.secondary, fontWeight: FontWeight.w800)),
                Text('${200 - (profile!.auraPoints % 200)} XP left', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.white54)),
              ]),
              const SizedBox(height: 10),
              ClipRRect(borderRadius: BorderRadius.circular(999), child: LinearProgressIndicator(value: progress, minHeight: 10, backgroundColor: Colors.white.withValues(alpha: 0.06), color: AppTheme.secondary)),
              const SizedBox(height: 18),
              Wrap(spacing: 10, runSpacing: 10, children: [
                _chip(context, profile!.homeCity.trim().isEmpty ? 'UNASSIGNED CITY' : profile!.homeCity.trim().toUpperCase()),
                _chip(context, '${posts.length} ARCHIVED POSTS'),
                _chip(context, '${profile!.currentStreakDays ?? 0} DAY STREAK'),
              ]),
            ]),
          ),
          const SizedBox(height: 18),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: 1.08,
            children: [
              _statCard(context, 'Zones', '$zoneCount', null, posts.isEmpty ? 'No recent changes' : '+${(posts.length / 2).ceil()} in last 24h', Icons.hexagon_outlined, AppTheme.primary),
              _statCard(context, 'Distance', totalDistance.toStringAsFixed(0), 'KM', 'All-time tracked', Icons.route_rounded, Colors.white),
              _statCard(context, 'Ride Time', _durationLabel(totalDuration), null, 'Across published rides', Icons.timer_outlined, AppTheme.secondary),
              _statCard(context, 'Engagement', '${totalLikes + totalComments}', null, '$totalLikes likes | $totalComments comments', Icons.signal_cellular_alt_rounded, AppTheme.glowSky),
            ],
          ),
          const SizedBox(height: 22),
          _sectionHeader(context, 'Flex Feed', 'Global Feed', () => context.go(AppRoutes.feed)),
          const SizedBox(height: 12),
          if (posts.isEmpty)
            const AppEmptyState(
              title: 'No rides published yet',
              message: 'Finish and publish a session to turn this profile into a real rider archive.',
              icon: Icons.auto_awesome_motion_rounded,
            )
          else
            SizedBox(
              height: 420,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: posts.length,
                separatorBuilder: (_, _) => const SizedBox(width: 16),
                itemBuilder: (context, index) => _feedCard(context, posts[index]),
              ),
            ),
          const SizedBox(height: 24),
          _sectionHeader(context, 'Ride Signals', 'Leaderboard', () => context.push(AppRoutes.leaderboard)),
          const SizedBox(height: 12),
          _signalTile(context, Icons.favorite_rounded, 'Post likes', '$totalLikes', 'Total appreciation across your published rides'),
          const SizedBox(height: 10),
          _signalTile(context, Icons.mode_comment_rounded, 'Comments received', '$totalComments', 'Conversation generated by your ride archive'),
          const SizedBox(height: 10),
          _signalTile(context, Icons.local_fire_department_rounded, 'Best ride', '${bestRide.toStringAsFixed(1)} km', 'Longest distance published from your own feed'),
        ],
      ),
    );
  }
}

Widget _orb(BuildContext context, {required IconData icon, int badge = 0, required VoidCallback onTap}) => InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Stack(clipBehavior: Clip.none, children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(color: const Color(0xFF18191C), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white.withValues(alpha: 0.08))),
          child: Icon(icon, color: Colors.white),
        ),
        if (badge > 0)
          Positioned(
            top: -5,
            right: -5,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(999)),
              child: Text(badge > 9 ? '9+' : '$badge', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.black, fontWeight: FontWeight.w900)),
            ),
          ),
      ]),
    );

Widget _miniStat(BuildContext context, String label, String value, Color accent) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.white54, letterSpacing: 1.1)),
        const SizedBox(height: 2),
        Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: accent, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic)),
      ],
    );

Widget _chip(BuildContext context, String label) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(999), border: Border.all(color: Colors.white.withValues(alpha: 0.08))),
      child: Text(label, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.white70, fontWeight: FontWeight.w800, letterSpacing: 0.8)),
    );

Widget _statCard(BuildContext context, String title, String value, String? unit, String footer, IconData icon, Color accent) => Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFF17181B), borderRadius: BorderRadius.circular(22), border: Border.all(color: Colors.white.withValues(alpha: 0.05))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Expanded(child: Text(title.toUpperCase(), style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.white54, letterSpacing: 1.3))), Icon(icon, color: accent, size: 28)]),
        const Spacer(),
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Flexible(child: Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, height: 1))),
          if (unit != null) ...[const SizedBox(width: 6), Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(unit, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white54, fontWeight: FontWeight.w900)))],
        ]),
        const SizedBox(height: 8),
        Text(footer, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: accent == Colors.white ? Colors.white54 : accent, fontWeight: FontWeight.w700)),
      ]),
    );

Widget _sectionHeader(BuildContext context, String title, String actionLabel, VoidCallback onTap) => Row(
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic)),
        const SizedBox(width: 12),
        Container(width: 44, height: 2, color: AppTheme.primary),
        const Spacer(),
        TextButton(onPressed: onTap, child: Text(actionLabel)),
      ],
    );
Widget _feedCard(BuildContext context, FeedPost post) {
  final distance = _num(post.statsJson['distanceKm']);
  final duration = _num(post.statsJson['durationMin']);
  final speed = _speed(post);
  return InkWell(
    borderRadius: BorderRadius.circular(24),
    onTap: () => context.push(AppRoutes.feedPost(post.id)),
    child: SizedBox(
      width: 320,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(fit: StackFit.expand, children: [
          PostMedia(post: post, stats: post.statsJson),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.black.withValues(alpha: 0.82), Colors.black.withValues(alpha: 0.18), Colors.black.withValues(alpha: 0.84)],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    if (speed != null) _overlay(context, Icons.speed_rounded, '${speed.toStringAsFixed(1)} km/h', AppTheme.primary),
                    const SizedBox(height: 8),
                    _overlay(context, Icons.favorite_rounded, '${post.likeCount} likes', AppTheme.secondary),
                  ]),
                ),
                Text(DateFormat('MMM d').format(post.createdAt), style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.white70)),
              ]),
              const Spacer(),
              Text(_zone(post), style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppTheme.primary, fontWeight: FontWeight.w900, letterSpacing: 0.9)),
              const SizedBox(height: 10),
              Text(
                post.caption.isEmpty ? 'Ride completed and synced to archive.' : post.caption,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, height: 1.05),
              ),
              const SizedBox(height: 14),
              Row(children: [
                _statFoot(context, Icons.thumb_up_alt_outlined, '${post.likeCount}'),
                const SizedBox(width: 16),
                _statFoot(context, Icons.chat_bubble_outline_rounded, '${post.commentCount}'),
                const Spacer(),
                Text('${distance.toStringAsFixed(1)} km | ${duration.toStringAsFixed(0)} min', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.white70)),
              ]),
            ]),
          ),
        ]),
      ),
    ),
  );
}

Widget _overlay(BuildContext context, IconData icon, String label, Color accent) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.36), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withValues(alpha: 0.1))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, color: accent, size: 16), const SizedBox(width: 6), Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w800))]),
    );

Widget _statFoot(BuildContext context, IconData icon, String value) => Row(
      children: [Icon(icon, size: 18, color: Colors.white), const SizedBox(width: 6), Text(value, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w800))],
    );

Widget _signalTile(BuildContext context, IconData icon, String title, String value, String subtitle) => Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF15171B), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withValues(alpha: 0.05))),
      child: Row(children: [
        Container(width: 46, height: 46, decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: AppTheme.primary)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: Theme.of(context).textTheme.titleMedium), const SizedBox(height: 2), Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white60))])),
        const SizedBox(width: 12),
        Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppTheme.primary)),
      ]),
    );

double _num(Object? value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0;
}

double? _speed(FeedPost post) {
  final distanceKm = _num(post.statsJson['distanceKm']);
  final durationMin = _num(post.statsJson['durationMin']);
  if (distanceKm <= 0 || durationMin <= 0) return null;
  return distanceKm / (durationMin / 60);
}

String _zone(FeedPost post) {
  final caption = post.caption.trim();
  if (caption.isEmpty) return 'RIDE ARCHIVE';
  final words = caption.split(RegExp(r'\s+')).where((word) => word.isNotEmpty).take(3);
  return words.isEmpty ? 'RIDE ARCHIVE' : words.join(' ').toUpperCase();
}

String _compact(int value) {
  if (value >= 1000) {
    final compact = value / 1000;
    return compact % 1 == 0 ? '${compact.toStringAsFixed(0)}K' : '${compact.toStringAsFixed(1)}K';
  }
  return '$value';
}

String _durationLabel(double totalDuration) {
  final totalMinutes = totalDuration.round();
  final hours = totalMinutes ~/ 60;
  final minutes = totalMinutes % 60;
  if (hours == 0) return '${minutes}M';
  return '${hours}H ${minutes}M';
}
