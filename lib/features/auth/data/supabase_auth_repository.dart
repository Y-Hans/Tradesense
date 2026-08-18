import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../../../core/contracts/repository_contracts.dart';
import '../../../shared/models/user_profile.dart';
import '../domain/auth_exception.dart';

class SupabaseAuthRepository implements AuthRepository {
  final supabase.SupabaseClient _client;

  SupabaseAuthRepository([supabase.SupabaseClient? client])
      : _client = client ?? supabase.Supabase.instance.client;

  @override
  Stream<UserProfile?> get authStateChanges {
    return _client.auth.onAuthStateChange.map((event) {
      final session = event.session;
      final user = session?.user;
      if (session == null || user == null) return null;

      final metadata = user.userMetadata ?? {};
      final displayName = metadata['display_name'] as String? ??
          user.email?.split('@').first ??
          'Trader';

      return UserProfile.initial(
        id: user.id,
        email: user.email ?? '',
        displayName: displayName,
      );
    });
  }

  @override
  Future<UserProfile?> getCurrentUser() async {
    try {
      final session = _client.auth.currentSession;
      final user = _client.auth.currentUser;
      if (session == null || user == null) return null;

      final metadata = user.userMetadata ?? {};
      final displayName = metadata['display_name'] as String? ??
          user.email?.split('@').first ??
          'Trader';

      return UserProfile.initial(
        id: user.id,
        email: user.email ?? '',
        displayName: displayName,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<UserProfile> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: displayName != null ? {'display_name': displayName} : null,
      );

      final user = response.user;
      if (user == null) {
        throw AuthException.unknown('Registration failed. No user returned.');
      }

      if (user.identities != null && user.identities!.isEmpty) {
        throw AuthException.userAlreadyExists();
      }

      return UserProfile.initial(
        id: user.id,
        email: user.email ?? email,
        displayName: displayName ?? user.email?.split('@').first,
      );
    } on supabase.AuthException catch (e) {
      if (e.message.contains('already registered') ||
          e.code == 'user_already_exists') {
        throw AuthException.userAlreadyExists();
      }
      throw AuthException(e.message, e.code);
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException.networkError();
    }
  }

  @override
  Future<UserProfile> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final user = response.user;
      if (user == null) {
        throw AuthException.invalidCredentials();
      }

      final metadata = user.userMetadata ?? {};
      final displayName = metadata['display_name'] as String? ??
          user.email?.split('@').first ??
          'Trader';

      return UserProfile.initial(
        id: user.id,
        email: user.email ?? email,
        displayName: displayName,
      );
    } on supabase.AuthException catch (e) {
      if (e.code == 'invalid_credentials' ||
          e.message.toLowerCase().contains('invalid login credentials')) {
        throw AuthException.invalidCredentials();
      }
      throw AuthException(e.message, e.code);
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException.networkError();
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (e) {
      throw AuthException.networkError();
    }
  }

  supabase.OtpType _parseOtpType(String type) {
    switch (type) {
      case 'signup':
        return supabase.OtpType.signup;
      case 'recovery':
        return supabase.OtpType.recovery;
      default:
        throw AuthException('Invalid OTP type: $type', 'invalid_otp_type');
    }
  }

  AuthException _mapAuthException(supabase.AuthException e, String fallback) {
    final code = e.code?.toLowerCase();
    final message = e.message.toLowerCase();
    if (message.contains('already confirmed') ||
        message.contains('already verified')) {
      return const AuthException(
        'This account is already verified. Please sign in.',
        'already_verified',
      );
    }
    if (code == 'otp_expired' || message.contains('expired')) {
      return const AuthException(
        'This code has expired. Please request a new code.',
        'otp_expired',
      );
    }
    if (code == 'invalid_otp' || message.contains('invalid otp') || message.contains('invalid token')) {
      return const AuthException(
        'That code is invalid. Please check it and try again.',
        'invalid_otp',
      );
    }
    return AuthException(e.message, e.code ?? fallback);
  }

  @override
  Future<void> verifyOTP({required String email, required String token, required String type}) async {
    try {
      await _client.auth.verifyOTP(
        email: email,
        token: token,
        type: _parseOtpType(type),
      );
    } on supabase.AuthException catch (e) {
      throw _mapAuthException(e, 'verify_error');
    } catch (e) {
      throw AuthException.networkError();
    }
  }

  @override
  Future<void> resendOTP({required String email, required String type}) async {
    try {
      if (type == 'recovery') {
        // GoTrue does not accept recovery in resend(); requesting the reset
        // email again is the supported recovery-OTP resend operation.
        await _client.auth.resetPasswordForEmail(email);
      } else {
        await _client.auth.resend(
          type: _parseOtpType(type),
          email: email,
        );
      }
    } on supabase.AuthException catch (e) {
      throw _mapAuthException(e, 'resend_error');
    } catch (_) {
      throw AuthException.networkError();
    }
  }

  @override
  Future<void> resetPasswordForEmail(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email);
    } on supabase.AuthException catch (_) {
      // Do not pass provider/account-existence details to the UI.
      throw AuthException.networkError();
    } catch (_) {
      throw AuthException.networkError();
    }
  }

  @override
  Future<void> updatePassword(String newPassword) async {
    try {
      await _client.auth.updateUser(supabase.UserAttributes(password: newPassword));
    } catch (e) {
      throw AuthException('Failed to update password: $e', 'update_error');
    }
  }

  @override
  Future<void> deleteAccount() async {
    try {
      await _client.rpc('delete_user');
      await signOut();
    } catch (e) {
      throw AuthException('Account deletion failed: $e', 'delete_error');
    }
  }
}
