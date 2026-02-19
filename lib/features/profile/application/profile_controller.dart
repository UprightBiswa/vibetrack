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
