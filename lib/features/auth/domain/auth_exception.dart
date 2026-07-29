class AuthException implements Exception {
  final String message;
  final String? code;

  const AuthException(this.message, [this.code]);

  factory AuthException.invalidCredentials() => const AuthException(
        'Invalid email or password. Please check your credentials and try again.',
        'invalid_credentials',
      );

  factory AuthException.userAlreadyExists() => const AuthException(
        'An account with this email address already exists. Please log in instead.',
        'user_already_exists',
      );

  factory AuthException.networkError() => const AuthException(
        'Network failure. Please check your internet connection and try again.',
        'network_error',
      );

  factory AuthException.sessionExpired() => const AuthException(
        'Your session has expired. Please log in again to continue.',
        'session_expired',
      );

  factory AuthException.unknown([String? details]) => AuthException(
        details ??
            'An unexpected authentication error occurred. Please try again.',
        'unknown',
      );

  @override
  String toString() => message;
}
