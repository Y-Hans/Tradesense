import 'package:flutter_test/flutter_test.dart';
import 'package:cryptoedu/features/auth/domain/auth_state.dart';
import 'package:cryptoedu/shared/models/user_profile.dart';

void main() {
  group('AuthState Domain Model Tests', () {
    test('initial state defaults to restoringSession', () {
      final state = AuthState.restoringSession();
      expect(state.status, equals(AuthStatus.restoringSession));
      expect(state.isRestoring, isTrue);
      expect(state.isAuthenticated, isFalse);
      expect(state.isAuthenticating, isFalse);
      expect(state.hasError, isFalse);
    });

    test('authenticated state correctly identifies active user', () {
      final user = UserProfile.initial(
        id: 'usr_1',
        email: 'test@cryptoedu.app',
        displayName: 'TestUser',
      );
      final state = AuthState.authenticated(user);

      expect(state.status, equals(AuthStatus.authenticated));
      expect(state.user, equals(user));
      expect(state.isAuthenticated, isTrue);
      expect(state.isRestoring, isFalse);
      expect(state.hasError, isFalse);
    });

    test('error state captures error message', () {
      final state = AuthState.error('Invalid credentials');

      expect(state.status, equals(AuthStatus.error));
      expect(state.errorMessage, equals('Invalid credentials'));
      expect(state.hasError, isTrue);
      expect(state.isAuthenticated, isFalse);
    });

    test('copyWith updates fields as expected', () {
      final initial = AuthState.unauthenticated();
      final user = UserProfile.initial(id: 'u2', email: 'a@b.com');
      final updated = initial.copyWith(
        status: AuthStatus.authenticated,
        user: user,
      );

      expect(updated.status, equals(AuthStatus.authenticated));
      expect(updated.user, equals(user));
    });
  });
}
