import 'package:flutter_riverpod/flutter_riverpod.dart';

class OnboardingNotifier extends StateNotifier<Map<String, bool>> {
  OnboardingNotifier()
      : super({
          // Default mock trader user starts with completed onboarding
          'usr_mock_123': true,
        });

  /// Returns whether onboarding is completed for the specified user ID.
  bool isCompleted(String? userId) {
    if (userId == null) return false;
    return state[userId] ?? false;
  }

  /// Marks onboarding as completed for the given user ID.
  void completeOnboarding(String userId) {
    state = {
      ...state,
      userId: true,
    };
  }
}
