import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cryptoedu/core/config/app_preferences.dart';
import 'package:cryptoedu/core/providers/mocks/mock_repositories.dart';
import 'package:cryptoedu/features/auth/application/auth_notifier.dart';
import 'package:cryptoedu/features/auth/domain/auth_state.dart';
import 'package:cryptoedu/features/onboarding/application/onboarding_notifier.dart';
import 'package:cryptoedu/shared/models/user_profile.dart';

void main() {
  late MockAuthRepository mockRepo;
  late AuthNotifier authNotifier;
  late OnboardingNotifier onboardingNotifier;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppPreferences.resetForTesting(clear: false);
    await AppPreferences.initialize();
    mockRepo = MockAuthRepository();
    authNotifier =
        AuthNotifier(mockRepo, authStateChanges: const Stream.empty());
    onboardingNotifier = OnboardingNotifier();
  });

  group('Onboarding Flow & Persistence Unit Tests', () {
    test('Fresh install starts every user with incomplete onboarding', () {
      expect(onboardingNotifier.isCompleted('usr_mock_123'), isFalse);
    });

    test('New user ID defaults to incomplete onboarding', () {
      expect(onboardingNotifier.isCompleted('usr_new_999'), isFalse);
    });

    test('completeOnboarding marks user ID as completed', () async {
      expect(onboardingNotifier.isCompleted('usr_new_999'), isFalse);

      await onboardingNotifier.completeOnboarding('usr_new_999');

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
      await onboardingNotifier.completeOnboarding(user1.id);

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
      await Future.delayed(Duration.zero);

      expect(authNotifier.state.status, equals(AuthStatus.authenticated));
      final userId = authNotifier.state.user?.id;
      expect(onboardingNotifier.isCompleted(userId), isFalse);
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

      await onboardingNotifier.completeOnboarding(userId);
      expect(onboardingNotifier.isCompleted(userId), isTrue);

      await authNotifier.signOut();
      expect(authNotifier.state.status, equals(AuthStatus.unauthenticated));

      // After logging back in, user 2 still has completed onboarding
      expect(onboardingNotifier.isCompleted(userId), isTrue);
    });

    test('Restart preserves onboarding completion without sharing users',
        () async {
      await onboardingNotifier.completeOnboarding('usr_restart_user');

      final sharedPreferences = await SharedPreferences.getInstance();
      await AppPreferences.resetForTesting(clear: false);
      await AppPreferences.initialize(preferences: sharedPreferences);
      final restartedNotifier = OnboardingNotifier();

      expect(restartedNotifier.isCompleted('usr_restart_user'), isTrue);
      expect(restartedNotifier.isCompleted('usr_other_user'), isFalse);
    });
  });
}
