import 'package:flutter_test/flutter_test.dart';
import 'package:cryptoedu/features/auth/application/auth_notifier.dart';
import 'package:cryptoedu/features/auth/application/user_lifecycle_notifier.dart';
import 'package:cryptoedu/features/auth/domain/auth_state.dart';
import 'package:cryptoedu/features/profile/domain/educational_disclosures.dart';
import 'package:cryptoedu/shared/models/user_profile.dart';
import 'package:cryptoedu/core/providers/mocks/mock_repositories.dart';

class FailingMockAuthRepository extends MockAuthRepository {
  @override
  Future<void> deleteAccount() async {
    throw Exception('Simulated network deletion error');
  }
}

void main() {
  late MockAuthRepository mockRepo;
  late AuthNotifier authNotifier;
  late UserLifecycleNotifier userLifecycleNotifier;

  setUp(() {
    mockRepo = MockAuthRepository();
    authNotifier = AuthNotifier(mockRepo);
    userLifecycleNotifier = UserLifecycleNotifier();
  });

  group('Profile & Account Lifecycle Business Logic Tests', () {
    test('Educational disclosures contain required compliance strings', () {
      expect(EducationalDisclosures.simulationNotice,
          contains('educational trading simulation'));
      expect(EducationalDisclosures.noRealCryptoNotice,
          contains('No real cryptocurrency is bought or sold'));
      expect(EducationalDisclosures.noGuaranteeNotice,
          contains('does not guarantee real-world trading results'));
      expect(EducationalDisclosures.regulatoryDisclaimer,
          isNot(contains('regulatory approval')));
    });

    test('UserProfile model extracts required display data accurately', () {
      final now = DateTime.now();
      final user = UserProfile(
        id: 'usr_test_1',
        email: 'test@cryptoedu.app',
        displayName: 'Test Trader',
        virtualBalanceInr: 100000.0,
        createdAt: now,
        isPremium: true,
      );

      expect(user.displayName, equals('Test Trader'));
      expect(user.email, equals('test@cryptoedu.app'));
      expect(user.virtualBalanceInr, equals(100000.0));
      expect(user.createdAt, equals(now));
      expect(user.isPremium, isTrue);
    });

    test('Logout clears auth state and resets user lifecycle state', () async {
      final user = UserProfile.initial(
        id: 'usr_test_1',
        email: 'test@cryptoedu.app',
      );

      await userLifecycleNotifier.initializeUser(user);
      expect(userLifecycleNotifier.state.isInitialized, isTrue);

      await authNotifier.signOut();
      userLifecycleNotifier.reset();

      expect(authNotifier.state.status, equals(AuthStatus.unauthenticated));
      expect(authNotifier.state.user, isNull);
      expect(userLifecycleNotifier.state.status,
          equals(UserLifecycleStatus.uninitialized));
    });

    test('Delete account removes profile, signs out, and resets lifecycle',
        () async {
      final user = await mockRepo.signIn(
        email: 'trader@cryptoedu.app',
        password: 'password123',
      );
      await userLifecycleNotifier.initializeUser(user);

      expect(authNotifier.state.isAuthenticated, isTrue);
      expect(userLifecycleNotifier.state.isInitialized, isTrue);

      final success = await authNotifier.deleteAccount();
      userLifecycleNotifier.reset();

      expect(success, isTrue);
      expect(authNotifier.state.status, equals(AuthStatus.unauthenticated));
      expect(authNotifier.state.user, isNull);
      expect(await mockRepo.getCurrentUser(), isNull);
      expect(userLifecycleNotifier.state.status,
          equals(UserLifecycleStatus.uninitialized));
    });

    test('Delete account failure handles repository exception gracefully',
        () async {
      final failingRepo = FailingMockAuthRepository();
      final failingNotifier = AuthNotifier(failingRepo);

      final success = await failingNotifier.deleteAccount();

      expect(success, isFalse);
      expect(failingNotifier.state.status, equals(AuthStatus.error));
      expect(failingNotifier.state.errorMessage,
          contains('Account deletion failed'));
    });
  });
}
