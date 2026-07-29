import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../../../core/contracts/repository_contracts.dart';
import '../../../shared/models/user_profile.dart';
import '../domain/auth_exception.dart';

class SupabaseAuthRepository implements AuthRepository {
  final supabase.SupabaseClient _client;

  SupabaseAuthRepository([supabase.SupabaseClient? client])
      : _client = client ?? supabase.Supabase.instance.client;

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

  @override
  Future<void> deleteAccount() async {
    throw UnimplementedError(
        'Account deletion depends on Divyanshu infrastructure & backend implementation.');
  }
}
