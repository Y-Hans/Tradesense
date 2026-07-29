import 'package:flutter_test/flutter_test.dart';
import 'package:cryptoedu/core/providers/mocks/mock_repositories.dart';
import 'package:cryptoedu/features/auth/domain/auth_exception.dart';

void main() {
  late MockAuthRepository repo;

  setUp(() {
    repo = MockAuthRepository();
  });

  group('MockAuthRepository Unit Tests', () {
    test('signIn succeeds with registered credentials', () async {
      final user = await repo.signIn(
        email: 'trader@cryptoedu.app',
        password: 'password123',
      );

      expect(user.email, equals('trader@cryptoedu.app'));
    });

    test('signIn throws AuthException.invalidCredentials on incorrect password',
        () async {
      expect(
        () => repo.signIn(
          email: 'trader@cryptoedu.app',
          password: 'badpassword',
        ),
        throwsA(isA<AuthException>()),
      );
    });

    test('signUp registers new user successfully', () async {
      final user = await repo.signUp(
        email: 'student@cryptoedu.app',
        password: 'pass123Word',
        displayName: 'StudentTrader',
      );

      expect(user.email, equals('student@cryptoedu.app'));
      expect(user.displayName, equals('StudentTrader'));
    });

    test(
        'signUp throws AuthException.userAlreadyExists on duplicate registration',
        () async {
      expect(
        () => repo.signUp(
          email: 'trader@cryptoedu.app',
          password: 'password123',
        ),
        throwsA(isA<AuthException>()),
      );
    });

    test('signOut clears current active user session', () async {
      final initialUser = await repo.getCurrentUser();
      expect(initialUser, isNotNull);

      await repo.signOut();
      final userAfterSignOut = await repo.getCurrentUser();

      expect(userAfterSignOut, isNull);
    });
  });
}
