import 'package:flutter/foundation.dart';
import '../../../shared/models/user_profile.dart';

enum AuthStatus {
  /// Session restoration in progress on app startup. Prevents flashing login screen.
  restoringSession,

  /// No active authenticated user session.
  unauthenticated,

  /// Authentication operation in progress (login, registration, logout).
  authenticating,

  /// Valid authenticated user session.
  authenticated,

  /// Authentication failure state.
  error,
}

@immutable
class AuthState {
  final AuthStatus status;
  final UserProfile? user;
  final String? errorMessage;

  const AuthState({
    required this.status,
    this.user,
    this.errorMessage,
  });

  factory AuthState.restoringSession() =>
      const AuthState(status: AuthStatus.restoringSession);

  factory AuthState.unauthenticated([String? errorMessage]) =>
      AuthState(status: AuthStatus.unauthenticated, errorMessage: errorMessage);

  factory AuthState.authenticating() =>
      const AuthState(status: AuthStatus.authenticating);

  factory AuthState.authenticated(UserProfile user) =>
      AuthState(status: AuthStatus.authenticated, user: user);

  factory AuthState.error(String message, {UserProfile? user}) =>
      AuthState(status: AuthStatus.error, errorMessage: message, user: user);

  bool get isRestoring => status == AuthStatus.restoringSession;
  bool get isAuthenticated =>
      status == AuthStatus.authenticated && user != null;
  bool get isAuthenticating => status == AuthStatus.authenticating;
  bool get hasError => status == AuthStatus.error && errorMessage != null;

  AuthState copyWith({
    AuthStatus? status,
    UserProfile? user,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthState &&
          runtimeType == other.runtimeType &&
          status == other.status &&
          user == other.user &&
          errorMessage == other.errorMessage;

  @override
  int get hashCode => status.hashCode ^ user.hashCode ^ errorMessage.hashCode;
}
