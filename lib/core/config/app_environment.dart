/// Represents the deployment environment the app is running in.
///
/// Selected at build time via the `--dart-define=APP_ENV=<value>` flag.
/// Defaults to [AppEnvironment.development] when the flag is absent.
enum AppEnvironment {
  /// Local development builds — verbose logging, mock backends permitted.
  development,

  /// Internal QA / staging builds — real backend, non-production project.
  staging,

  /// Google Play production release builds.
  production;

  /// Parses the raw string value passed through `--dart-define=APP_ENV=...`.
  ///
  /// Falls back to [AppEnvironment.development] for any unrecognised value so
  /// that running `flutter run` without explicit defines always works locally.
  static AppEnvironment fromString(String value) {
    switch (value.toLowerCase()) {
      case 'staging':
        return AppEnvironment.staging;
      case 'production':
        return AppEnvironment.production;
      default:
        return AppEnvironment.development;
    }
  }

  /// Whether verbose platform / network logging should be emitted.
  bool get isDebugLoggingEnabled => this != AppEnvironment.production;

  /// Whether the app should use mock repositories instead of live backends.
  ///
  /// Mocks are ONLY active in development by default.  Staging and production
  /// always connect to the real backend.
  bool get useMockBackend => this == AppEnvironment.development;

  /// Convenience alias used in diagnostics and analytics.
  String get label => name; // 'development' | 'staging' | 'production'
}
