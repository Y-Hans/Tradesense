import 'package:flutter_test/flutter_test.dart';
import 'package:cryptoedu/features/auth/application/auth_notifier.dart';
import 'package:cryptoedu/features/auth/domain/auth_state.dart';
import 'package:cryptoedu/features/auth/domain/auth_exception.dart';
import 'package:cryptoedu/core/providers/mocks/mock_repositories.dart';

void main() {
  late MockAuthRepository mockRepo;
  late AuthNotifier notifier;

  setUp(() {
    mockRepo = MockAuthRepository();
    notifier = AuthNotifier(mockRepo, authStateChanges: const Stream.empty());
  });

  group('AuthNotifier Unit Tests', () {


    test('signIn with valid credentials succeeds', () async {
      final result = await notifier.signIn(
        email: 'trader@cryptoedu.app',
        password: 'password123',
      );

      expect(result, isTrue);
      expect(notifier.state.status, equals(AuthStatus.authenticated));
      expect(notifier.state.user?.email, equals('trader@cryptoedu.app'));
    });



    test('signUp with new email succeeds and sets unverified state', () async {
      // Updated 2026-08-15: signUp now requires email OTP verification before authentication
      final result = await notifier.signUp(
        email: 'newuser@cryptoedu.app',
        password: 'securePass123',
        displayName: 'NewTrader',
      );

      expect(result, isTrue);
      expect(notifier.state.status, equals(AuthStatus.unverified));
      expect(notifier.state.user?.email, equals('newuser@cryptoedu.app'));
      expect(notifier.state.user?.displayName, equals('NewTrader'));
    });

    test('verifyOTP with signup type transitions state to authenticated', () async {
      await notifier.signUp(
        email: 'newuser@cryptoedu.app',
        password: 'securePass123',
        displayName: 'NewTrader',
      );
      expect(notifier.state.status, equals(AuthStatus.unverified));

      final result = await notifier.verifyOTP(
        email: 'newuser@cryptoedu.app',
        token: '123456',
        type: 'signup',
      );

      expect(result, isTrue);
      expect(notifier.state.status, equals(AuthStatus.authenticated));
      expect(notifier.state.user?.email, equals('newuser@cryptoedu.app'));
    });

    test('verifyOTP with recovery type returns true and lets stream manage resettingPassword state', () async {
      final result = await notifier.verifyOTP(
        email: 'trader@cryptoedu.app',
        token: '123456',
        type: 'recovery',
      );

      expect(result, isTrue);
      // For recovery type, verifyOTP does not force authenticated state
      expect(notifier.state.status, isNot(equals(AuthStatus.authenticated)));
    });

    test('recovery request enters a distinct OTP-awaiting state', () async {
      final result = await notifier.resetPasswordForEmail(
        'otp_test' '@example.invalid',
      );

      expect(result, isTrue);
      expect(notifier.state.status, equals(AuthStatus.recoveryAwaitingOtp));
    });

    test('recovery verification establishes a recovery session', () async {
      final result = await notifier.verifyOTP(
        email: 'otp_test' '@example.invalid',
        token: '123456',
        type: 'recovery',
      );

      expect(result, isTrue);
      expect(notifier.state.status, equals(AuthStatus.resettingPassword));
    });

    test('invalid and expired OTP errors are surfaced without authenticating', () async {
      mockRepo.verifyOtpError = const AuthException(
        'That code is invalid. Please check it and try again.',
        'invalid_otp',
      );

      final invalid = await notifier.verifyOTP(
        email: 'otp_test' '@example.invalid',
        token: '000000',
        type: 'signup',
      );

      expect(invalid, isFalse);
      expect(notifier.state.status, equals(AuthStatus.error));
      expect(notifier.state.errorMessage, contains('invalid'));

      mockRepo.verifyOtpError = const AuthException(
        'This code has expired. Please request a new code.',
        'otp_expired',
      );
      final expired = await notifier.verifyOTP(
        email: 'otp_test' '@example.invalid',
        token: '111111',
        type: 'signup',
      );

      expect(expired, isFalse);
      expect(notifier.state.errorMessage, contains('expired'));
    });

    test('resend OTP delegates to the repository', () async {
      expect(
        await notifier.resendOTP(
          email: 'otp_test' '@example.invalid',
          type: 'signup',
        ),
        isTrue,
      );
    });

    test('password update succeeds only after recovery verification', () async {
      await notifier.verifyOTP(
        email: 'otp_test' '@example.invalid',
        token: '123456',
        type: 'recovery',
      );

      final result = await notifier.updatePassword('newSecurePass123');

      expect(result, isTrue);
      expect(notifier.state.status, equals(AuthStatus.authenticated));
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

    test(
        'deleteAccount calls repository and transitions state to unauthenticated',
        () async {
      await notifier.signIn(
        email: 'trader@cryptoedu.app',
        password: 'password123',
      );
      expect(notifier.state.isAuthenticated, isTrue);

      final success = await notifier.deleteAccount();

      expect(success, isTrue);
      expect(notifier.state.status, equals(AuthStatus.unauthenticated));
      expect(notifier.state.user, isNull);
      expect(await mockRepo.getCurrentUser(), isNull);
    });
  });
}
