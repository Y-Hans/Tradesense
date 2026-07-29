import 'package:flutter_test/flutter_test.dart';
import 'package:cryptoedu/features/auth/application/auth_notifier.dart';
import 'package:cryptoedu/features/auth/domain/auth_state.dart';
import 'package:cryptoedu/core/providers/mocks/mock_repositories.dart';

void main() {
  late MockAuthRepository mockRepo;
  late AuthNotifier notifier;

  setUp(() {
    mockRepo = MockAuthRepository();
    notifier = AuthNotifier(mockRepo);
  });

  group('AuthNotifier Unit Tests', () {
    test('session restoration sets authenticated state when active user exists',
        () async {
      await notifier.restoreSession();

      expect(notifier.state.status, equals(AuthStatus.authenticated));
      expect(notifier.state.user?.email, equals('trader@cryptoedu.app'));
    });

    test('session restoration sets unauthenticated state when no user exists',
        () async {
      mockRepo.setCurrentUser(null);
      await notifier.restoreSession();

      expect(notifier.state.status, equals(AuthStatus.unauthenticated));
      expect(notifier.state.user, isNull);
    });

    test('signIn with valid credentials succeeds', () async {
      final result = await notifier.signIn(
        email: 'trader@cryptoedu.app',
        password: 'password123',
      );

      expect(result, isTrue);
      expect(notifier.state.status, equals(AuthStatus.authenticated));
      expect(notifier.state.user?.email, equals('trader@cryptoedu.app'));
    });

    test('signIn with invalid credentials fails and emits error state',
        () async {
      final result = await notifier.signIn(
        email: 'trader@cryptoedu.app',
        password: 'wrong_password',
      );

      expect(result, isFalse);
      expect(notifier.state.status, equals(AuthStatus.error));
      expect(
          notifier.state.errorMessage, contains('Invalid email or password'));
    });

    test('signUp with new email succeeds', () async {
      final result = await notifier.signUp(
        email: 'newuser@cryptoedu.app',
        password: 'securePass123',
        displayName: 'NewTrader',
      );

      expect(result, isTrue);
      expect(notifier.state.status, equals(AuthStatus.authenticated));
      expect(notifier.state.user?.email, equals('newuser@cryptoedu.app'));
      expect(notifier.state.user?.displayName, equals('NewTrader'));
    });

    test('signUp with duplicate email fails with duplicate error message',
        () async {
      final result = await notifier.signUp(
        email: 'trader@cryptoedu.app',
        password: 'password123',
      );

      expect(result, isFalse);
      expect(notifier.state.status, equals(AuthStatus.error));
      expect(notifier.state.errorMessage, contains('already exists'));
    });

    test('signOut clears user state and transitions to unauthenticated',
        () async {
      await notifier.signIn(
        email: 'trader@cryptoedu.app',
        password: 'password123',
      );
      expect(notifier.state.isAuthenticated, isTrue);

      await notifier.signOut();

      expect(notifier.state.status, equals(AuthStatus.unauthenticated));
      expect(notifier.state.user, isNull);
    });
  });
}
