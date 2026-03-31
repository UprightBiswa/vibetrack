import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vibetreck/core/providers/repositories.dart';
import 'package:vibetreck/features/auth/application/auth_controller.dart';
import 'package:vibetreck/shared/models/leaderboard_entry.dart';
import 'package:vibetreck/shared/models/user_profile.dart';

final currentProfileProvider = FutureProvider<UserProfile?>(
  retry: (count, error) => null,
  (ref) async {
    final user = await ref.watch(authUserProvider.future);
    if (user == null) return null;
    return ref
        .read(profileRepositoryProvider)
        .getOrCreateProfile(userId: user.id, email: user.email);
  },
);

final profileByIdProvider = FutureProvider.family<UserProfile?, String>(
  retry: (count, error) => null,
  (ref, profileId) {
    return ref.read(profileRepositoryProvider).getProfileById(profileId);
  },
);

final leaderboardProvider = FutureProvider<List<LeaderboardEntry>>(
  retry: (count, error) => null,
  (ref) async {
    return ref.read(profileRepositoryProvider).getLeaderboard();
  },
);

final profileActionsProvider = Provider<ProfileActions>((ref) {
  return ProfileActions(ref);
});

class ProfileActions {
  ProfileActions(this._ref);

  final Ref _ref;

  Future<UserProfile> updateProfile({
    required String username,
    required String homeCity,
    String avatarUrl = '',
  }) async {
    final profile = await _ref.read(profileRepositoryProvider).updateProfile(
      username: username,
      homeCity: homeCity,
      avatarUrl: avatarUrl,
    );
    _ref.invalidate(currentProfileProvider);
    _ref.invalidate(profileByIdProvider(profile.id));
    _ref.invalidate(leaderboardProvider);
    return profile;
  }
}
