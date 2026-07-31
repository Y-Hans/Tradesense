import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/contracts/repository_contracts.dart';
import '../domain/auth_exception.dart';
import '../domain/auth_state.dart';

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _authRepository;

  AuthNotifier(this._authRepository) : super(AuthState.restoringSession()) {
    restoreSession();
  }

  /// Restores active user session on app launch.
  /// Prevents flashing login screens during initialization.
  Future<void> restoreSession() async {
    state = AuthState.restoringSession();
    try {
      final user = await _authRepository.getCurrentUser();
      if (user != null) {
        state = AuthState.authenticated(user);
      } else {
        state = AuthState.unauthenticated();
      }
    } catch (e) {
      state = AuthState.unauthenticated();
    }
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
      state = AuthState.authenticated(user);
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

  /// Resets error state if present.
  void clearError() {
    if (state.status == AuthStatus.error) {
      state = state.user != null
          ? AuthState.authenticated(state.user!)
          : AuthState.unauthenticated();
    }
  }
}
