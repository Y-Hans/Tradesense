import 'package:flutter_test/flutter_test.dart';
import 'package:cryptoedu/core/providers/mocks/mock_repositories.dart';
import 'package:cryptoedu/features/auth/application/auth_notifier.dart';
import 'package:cryptoedu/features/auth/domain/auth_state.dart';
import 'package:cryptoedu/features/onboarding/application/onboarding_notifier.dart';
import 'package:cryptoedu/shared/models/user_profile.dart';

void main() {
  late MockAuthRepository mockRepo;
  late AuthNotifier authNotifier;
  late OnboardingNotifier onboardingNotifier;

  setUp(() {
    mockRepo = MockAuthRepository();
    authNotifier = AuthNotifier(mockRepo);
    onboardingNotifier = OnboardingNotifier();
  });

  group('Onboarding Flow & Persistence Unit Tests', () {
    test('Default mock user is completed by default', () {
      expect(onboardingNotifier.isCompleted('usr_mock_123'), isTrue);
    });

    test('New user ID defaults to incomplete onboarding', () {
      expect(onboardingNotifier.isCompleted('usr_new_999'), isFalse);
    });

    test('completeOnboarding marks user ID as completed', () {
      expect(onboardingNotifier.isCompleted('usr_new_999'), isFalse);

      onboardingNotifier.completeOnboarding('usr_new_999');

      expect(onboardingNotifier.isCompleted('usr_new_999'), isTrue);
    });

    test('Multiple users maintain independent onboarding completion states',
        () async {
      final user1 =
          UserProfile.initial(id: 'usr_u1', email: 'u1@cryptoedu.app');
      final user2 =
          UserProfile.initial(id: 'usr_u2', email: 'u2@cryptoedu.app');

      expect(onboardingNotifier.isCompleted(user1.id), isFalse);
      expect(onboardingNotifier.isCompleted(user2.id), isFalse);

      // User 1 completes onboarding
      onboardingNotifier.completeOnboarding(user1.id);

      expect(onboardingNotifier.isCompleted(user1.id), isTrue);
      expect(onboardingNotifier.isCompleted(user2.id), isFalse);
    });

    test(
        'Session restoration with user profiles integrates with onboarding notifier',
        () async {
      mockRepo.setCurrentUser(UserProfile.initial(
        id: 'usr_mock_123',
        email: 'trader@cryptoedu.app',
      ));
      await authNotifier.restoreSession();

      expect(authNotifier.state.status, equals(AuthStatus.authenticated));
      final userId = authNotifier.state.user?.id;
      expect(onboardingNotifier.isCompleted(userId), isTrue);
    });

    test(
        'Logout clears auth session while retaining user onboarding completion mapping',
        () async {
      await authNotifier.signUp(
        email: 'trader2@cryptoedu.app',
        password: 'password123',
      );
      final userId = authNotifier.state.user!.id;
      expect(onboardingNotifier.isCompleted(userId), isFalse);

      onboardingNotifier.completeOnboarding(userId);
      expect(onboardingNotifier.isCompleted(userId), isTrue);

      await authNotifier.signOut();
      expect(authNotifier.state.status, equals(AuthStatus.unauthenticated));

      // After logging back in, user 2 still has completed onboarding
      expect(onboardingNotifier.isCompleted(userId), isTrue);
    });
  });
}
