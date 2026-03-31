import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vibetreck/core/providers/repositories.dart';
import 'package:vibetreck/features/auth/application/auth_controller.dart';
import 'package:vibetreck/shared/models/user_profile.dart';

final currentProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final user = await ref.watch(authUserProvider.future);
  if (user == null) return null;
  return ref
      .read(profileRepositoryProvider)
      .getOrCreateProfile(userId: user.id, email: user.email);
});

final profileByIdProvider = FutureProvider.family<UserProfile?, String>((
  ref,
  profileId,
) {
  return ref.read(profileRepositoryProvider).getProfileById(profileId);
});

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
    return profile;
  }
}
