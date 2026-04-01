import 'package:equatable/equatable.dart';
import 'package:vibetreck/shared/models/app_user.dart';

class AuthState extends Equatable {
  const AuthState({
    this.user,
    this.isSubmitting = false,
    this.errorMessage,
    this.infoMessage,
    this.initialized = false,
  });

  final AppUser? user;
  final bool isSubmitting;
  final String? errorMessage;
  final String? infoMessage;
  final bool initialized;

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    AppUser? user,
    bool updateUser = false,
    bool? isSubmitting,
    String? errorMessage,
    String? infoMessage,
    bool? initialized,
    bool clearError = false,
    bool clearInfo = false,
  }) {
    return AuthState(
      user: updateUser ? user : this.user,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      infoMessage: clearInfo ? null : (infoMessage ?? this.infoMessage),
      initialized: initialized ?? this.initialized,
    );
  }

  @override
  List<Object?> get props => [user, isSubmitting, errorMessage, infoMessage, initialized];
}
