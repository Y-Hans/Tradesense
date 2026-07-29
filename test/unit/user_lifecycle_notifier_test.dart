import 'package:flutter_test/flutter_test.dart';
import 'package:cryptoedu/shared/models/user_profile.dart';
import 'package:cryptoedu/features/auth/application/user_lifecycle_notifier.dart';

void main() {
  late UserLifecycleNotifier notifier;

  setUp(() {
    notifier = UserLifecycleNotifier();
  });

  group('UserLifecycleNotifier Unit Tests', () {
    test('initial state is uninitialized', () {
      expect(notifier.state.status, equals(UserLifecycleStatus.uninitialized));
      expect(notifier.state.isInitialized, isFalse);
    });

    test('initializeUser transitions to initialized state', () async {
      final user = UserProfile.initial(
        id: 'usr_test_1',
        email: 'test1@cryptoedu.app',
      );

      await notifier.initializeUser(user);

      expect(notifier.state.status, equals(UserLifecycleStatus.initialized));
      expect(notifier.state.userId, equals('usr_test_1'));
      expect(notifier.state.isInitialized, isTrue);
    });

    test('initializeUser is idempotent on repeated calls for same user ID',
        () async {
      final user = UserProfile.initial(
        id: 'usr_test_1',
        email: 'test1@cryptoedu.app',
      );

      await notifier.initializeUser(user);
      expect(notifier.state.status, equals(UserLifecycleStatus.initialized));

      // Repeated call should remain initialized without re-triggering logic
      await notifier.initializeUser(user);
      expect(notifier.state.status, equals(UserLifecycleStatus.initialized));
      expect(notifier.state.userId, equals('usr_test_1'));
    });

    test('reset clears lifecycle state back to uninitialized', () async {
      final user = UserProfile.initial(
        id: 'usr_test_1',
        email: 'test1@cryptoedu.app',
      );

      await notifier.initializeUser(user);
      expect(notifier.state.isInitialized, isTrue);

      notifier.reset();

      expect(notifier.state.status, equals(UserLifecycleStatus.uninitialized));
      expect(notifier.state.userId, isNull);
    });
  });
}
