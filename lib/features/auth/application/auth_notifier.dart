import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../../../core/contracts/repository_contracts.dart';
import '../../../shared/models/user_profile.dart';
import '../domain/auth_exception.dart';
import '../domain/auth_state.dart';

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _authRepository;
  StreamSubscription<supabase.AuthState>? _supabaseAuthSubscription;

  AuthNotifier(this._authRepository, {Stream<supabase.AuthState>? authStateChanges}) : super(AuthState.restoringSession()) {
    final stream = authStateChanges ?? supabase.Supabase.instance.client.auth.onAuthStateChange;
    _supabaseAuthSubscription = stream.listen((data) async {
      final event = data.event;
      final session = data.session;

      if (event == supabase.AuthChangeEvent.passwordRecovery) {
        state = AuthState.resettingPassword();
      } else if (event == supabase.AuthChangeEvent.signedOut) {
        if (state.status == AuthStatus.recoveryAwaitingOtp) return;
        state = AuthState.unauthenticated();
      } else if (session != null) {
        // A signup response can briefly emit a session before the OTP gate is
        // rendered. Do not let that transient event bypass verification.
        if (state.status == AuthStatus.unverified ||
            state.status == AuthStatus.resettingPassword) return;
        final userProfile = await _authRepository.getCurrentUser();
        if (userProfile != null) {
          state = AuthState.authenticated(userProfile);
        } else {
          state = AuthState.unverified();
        }
      } else {
        if (state.isAuthenticating || state.status == AuthStatus.resettingPassword) return;
        state = AuthState.unauthenticated();
      }
    });

    if (authStateChanges != null) {
      _authRepository.getCurrentUser().then((userProfile) {
        if (userProfile != null) {
          state = AuthState.authenticated(userProfile);
        } else {
          state = AuthState.unauthenticated();
        }
      });
    }
  }

  @override
  void dispose() {
    _supabaseAuthSubscription?.cancel();
    super.dispose();
  }



  /// Authenticates user with email and password.
  /// UI handles input validation (empty fields, email regex, min password length).
  /// Business/repository errors (invalid credentials, network failure) are handled here.
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    state = AuthState.authenticating();
    try {
      final user = await _authRepository.signIn(
        email: email.trim(),
        password: password,
      );
      state = AuthState.authenticated(user);
      return true;
    } on AuthException catch (e) {
      state = AuthState.error(e.message);
      return false;
    } catch (e) {
      state = AuthState.error('Authentication failed: ${e.toString()}');
      return false;
    }
  }

  /// Registers new user account with email, password, and optional display name.
  /// Does NOT perform financial/wallet initialization (owned by Laksh & Divyanshu).
  Future<bool> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    state = AuthState.authenticating();
    try {
      final user = await _authRepository.signUp(
        email: email.trim(),
        password: password,
        displayName: displayName?.trim(),
      );
      state = AuthState.unverified(user: user);
      return true;
    } on AuthException catch (e) {
      state = AuthState.error(e.message);
      return false;
    } catch (e) {
      state = AuthState.error('Registration failed: ${e.toString()}');
      return false;
    }
  }

  /// Cleans up state and logs user out.
  Future<void> signOut() async {
    state = AuthState.authenticating();
    try {
      await _authRepository.signOut();
    } catch (_) {
      // Ensure local state is cleared even if remote logout encounters a network error
    } finally {
      state = AuthState.unauthenticated();
    }
  }

  /// Deletes active user account via repository, clears session, and updates state.
  Future<bool> deleteAccount() async {
    if (state.isAuthenticating) return false;
    state = AuthState.authenticating();
    try {
      await _authRepository.deleteAccount();
      state = AuthState.unauthenticated();
      return true;
    } on AuthException catch (e) {
      state = AuthState.error(e.message);
      return false;
    } catch (e) {
      state = AuthState.error('Account deletion failed: ${e.toString()}');
      return false;
    }
  }

  /// Resets error state if present.
  void clearError() {
    if (state.status == AuthStatus.error) {
      state = state.user != null
          ? AuthState.authenticated(state.user!)
          : AuthState.unauthenticated();
    }
  }

  Future<bool> verifyOTP({required String email, required String token, required String type}) async {
    state = AuthState.authenticating();
    try {
      await _authRepository.verifyOTP(email: email, token: token, type: type);

      final user = await _authRepository.getCurrentUser();
      if (user != null) {
        state = type == 'recovery'
            ? AuthState.resettingPassword()
            : AuthState.authenticated(user);
      } else {
        state = AuthState.error(
          type == 'recovery'
              ? 'Recovery verification succeeded, but the recovery session is unavailable. Please request a new code.'
              : 'Verification succeeded but session was not established.',
        );
        return false;
      }

      return true;
    } on AuthException catch (e) {
      state = AuthState.error(e.message);
      return false;
    } catch (e) {
      state = AuthState.error('Verification failed: ${e.toString()}');
      return false;
    }
  }

  Future<bool> resendOTP({required String email, required String type}) async {
    try {
      await _authRepository.resendOTP(email: email.trim(), type: type);
      return true;
    } on AuthException catch (e) {
      state = AuthState.error(e.message);
      return false;
    } catch (_) {
      state = AuthState.error('Unable to resend the verification code. Please try again.');
      return false;
    }
  }

  Future<bool> resetPasswordForEmail(String email) async {
    state = AuthState.authenticating();
    try {
      await _authRepository.resetPasswordForEmail(email);
      // Keep this state distinct from unauthenticated so the router cannot
      // lose the recovery OTP flow while the user is entering the code.
      state = const AuthState(status: AuthStatus.recoveryAwaitingOtp);
      return true;
    } on AuthException catch (e) {
      state = AuthState.error(e.message);
      return false;
    } catch (e) {
      state = AuthState.error('Password reset failed: ${e.toString()}');
      return false;
    }
  }

  Future<bool> updatePassword(String newPassword) async {
    state = AuthState.authenticating();
    try {
      await _authRepository.updatePassword(newPassword);
      final user = await _authRepository.getCurrentUser();
      if (user != null) {
        state = AuthState.authenticated(user);
      } else {
        state = AuthState.unauthenticated();
      }
      return true;
    } on AuthException catch (e) {
      state = AuthState.error(e.message);
      return false;
    } catch (e) {
      state = AuthState.error('Password update failed: ${e.toString()}');
      return false;
    }
  }
}
