import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/user_profile.dart';

enum UserLifecycleStatus {
  uninitialized,
  initializing,
  initialized,
  error,
}

@immutable
class UserLifecycleState {
  final UserLifecycleStatus status;
  final String? userId;
  final String? errorMessage;

  const UserLifecycleState({
    required this.status,
    this.userId,
    this.errorMessage,
  });

  factory UserLifecycleState.uninitialized() =>
      const UserLifecycleState(status: UserLifecycleStatus.uninitialized);

  factory UserLifecycleState.initializing(String userId) => UserLifecycleState(
      status: UserLifecycleStatus.initializing, userId: userId);

  factory UserLifecycleState.initialized(String userId) => UserLifecycleState(
      status: UserLifecycleStatus.initialized, userId: userId);

  factory UserLifecycleState.error(String message, {String? userId}) =>
      UserLifecycleState(
          status: UserLifecycleStatus.error,
          errorMessage: message,
          userId: userId);

  bool get isInitialized => status == UserLifecycleStatus.initialized;
  bool get isInitializing => status == UserLifecycleStatus.initializing;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserLifecycleState &&
          runtimeType == other.runtimeType &&
          status == other.status &&
          userId == other.userId &&
          errorMessage == other.errorMessage;

  @override
  int get hashCode => status.hashCode ^ userId.hashCode ^ errorMessage.hashCode;
}

class UserLifecycleNotifier extends StateNotifier<UserLifecycleState> {
  final Set<String> _initializedUserIds = {};

  UserLifecycleNotifier() : super(UserLifecycleState.uninitialized());

  /// Idempotently initializes user lifecycle for the given user profile.
  /// Repeated calls for the same user ID will be safely skipped.
  Future<void> initializeUser(UserProfile user) async {
    if (_initializedUserIds.contains(user.id)) {
      // User lifecycle has already been initialized idempotently.
      if (state.userId != user.id || !state.isInitialized) {
        state = UserLifecycleState.initialized(user.id);
      }
      return;
    }

    state = UserLifecycleState.initializing(user.id);

    try {
      // Coordinate profile check & user lifecycle setup
      // Note: No wallet creation, ₹100,000 balance assignment, or portfolio creation is performed here.

      // TODO(Laksh): Future virtual wallet and portfolio initialization hook.
      // Laksh's financial initialization contract should be invoked here idempotently upon user lifecycle setup.

      _initializedUserIds.add(user.id);
      state = UserLifecycleState.initialized(user.id);
    } catch (e) {
      state = UserLifecycleState.error(
        'User lifecycle initialization failed: ${e.toString()}',
        userId: user.id,
      );
    }
  }

  /// Resets lifecycle state upon logout.
  void reset() {
    state = UserLifecycleState.uninitialized();
  }
}
