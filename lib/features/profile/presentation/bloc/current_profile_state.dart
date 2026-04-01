import 'package:equatable/equatable.dart';
import 'package:vibetreck/core/bloc/view_status.dart';
import 'package:vibetreck/shared/models/user_profile.dart';

class CurrentProfileState extends Equatable {
  const CurrentProfileState({
    this.status = ViewStatus.initial,
    this.profile,
    this.errorMessage,
  });

  final ViewStatus status;
  final UserProfile? profile;
  final String? errorMessage;

  CurrentProfileState copyWith({
    ViewStatus? status,
    UserProfile? profile,
    String? errorMessage,
    bool clearError = false,
  }) {
    return CurrentProfileState(
      status: status ?? this.status,
      profile: profile ?? this.profile,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [status, profile, errorMessage];
}
