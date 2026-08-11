import 'app_environment.dart';

/// Immutable, typed configuration surface for the entire platform layer.
///
/// All values are sourced exclusively from `--dart-define` compile-time
/// constants injected by the build system (CI, Android Gradle, local scripts).
///
/// ## Usage
/// ```
/// flutter run \
///   --dart-define=APP_ENV=development \
///   --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
///   --dart-define=SUPABASE_ANON_KEY=eyJ... \
///   --dart-define=REVENUECAT_PUBLIC_KEY=appl_...
/// ```
///
/// ## Security contract
/// - Only PUBLIC / CLIENT-SAFE values belong here.
/// - Service-role keys, OpenRouter secrets, and any server-side credentials
///   must NEVER be passed through `--dart-define` and must NEVER appear here.
/// - This class is safe to serialise in crash reports.
///
/// ## Adding new values
/// 1. Declare a `static const String _kFooKey = 'FOO';` sentinel.
/// 2. Add the corresponding `final` field with a `fromEnvironment` default.
/// 3. Expose the field through [AppConfig.instance] below.
/// 4. Add the define to `scripts/run_dev.sh` (or equivalent CI step) with a
///    safe placeholder for development.
class AppConfig {
  // ---------------------------------------------------------------------------
  // Private compile-time constant sentinels
  // ---------------------------------------------------------------------------

  static const String _kEnvKey = 'APP_ENV';
  static const String _kSupabaseUrlKey = 'SUPABASE_URL';
  static const String _kSupabaseAnonKey = 'SUPABASE_ANON_KEY';
  static const String _kRevenueCatPublicKey = 'REVENUECAT_PUBLIC_KEY';
  static const String _kBinanceWsBaseUrl = 'BINANCE_WS_BASE_URL';
  static const String _kCoinGeckoApiKey = 'COINGECKO_API_KEY';

  // ---------------------------------------------------------------------------
  // Typed fields
  // ---------------------------------------------------------------------------

  /// Which deployment environment this binary targets.
  final AppEnvironment environment;

  /// Supabase project REST / Realtime URL.
  /// Example: `https://xyzcompany.supabase.co`
  ///
  /// Empty string in development when no define is provided — callers must
  /// guard against this before constructing a real Supabase client.
  final String supabaseUrl;

  /// Supabase anonymous/public API key (JWT).
  ///
  /// This is the `anon` key from the Supabase dashboard → Settings → API.
  /// It is safe to embed in client code; Row Level Security enforces access.
  final String supabaseAnonKey;

  /// RevenueCat public SDK key for this platform.
  ///
  /// Retrieve from the RevenueCat dashboard → Project → API Keys → Public.
  /// Google Play variant typically starts with `goog_...`.
  final String revenueCatPublicKey;

  /// Override for the Binance WebSocket base URL.
  ///
  /// Defaults to `wss://stream.binance.com:9443` (Binance production).
  /// Override in test / staging builds via
  /// `--dart-define=BINANCE_WS_BASE_URL=wss://...`.
  final String binanceWsBaseUrl;

  /// Optional CoinGecko API key for the paid tier.
  ///
  /// The free tier works without a key (empty string).  Provide a key via
  /// `--dart-define=COINGECKO_API_KEY=CG-...` to enable higher rate limits.
  final String coinGeckoApiKey;

  // ---------------------------------------------------------------------------
  // Constructor (package-private — use [AppConfig.instance])
  // ---------------------------------------------------------------------------

  const AppConfig._({
    required this.environment,
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    required this.revenueCatPublicKey,
    required this.binanceWsBaseUrl,
    required this.coinGeckoApiKey,
  });

  // ---------------------------------------------------------------------------
  // Singleton resolved from compile-time defines
  // ---------------------------------------------------------------------------

  /// The single application configuration resolved at compile time.
  ///
  /// Values are read from `--dart-define` flags.  Missing flags fall back to
  /// empty strings so that the app can still launch locally for UI development.
  static const AppConfig instance = AppConfig._(
    environment: AppEnvironment.development, // overridden below via factory
    supabaseUrl: String.fromEnvironment(_kSupabaseUrlKey, defaultValue: ''),
    supabaseAnonKey: String.fromEnvironment(
      _kSupabaseAnonKey,
      defaultValue: '',
    ),
    revenueCatPublicKey: String.fromEnvironment(
      _kRevenueCatPublicKey,
      defaultValue: '',
    ),
    binanceWsBaseUrl: String.fromEnvironment(
      _kBinanceWsBaseUrl,
      defaultValue: 'wss://stream.binance.com:9443',
    ),
    coinGeckoApiKey: String.fromEnvironment(
      _kCoinGeckoApiKey,
      defaultValue: '',
    ),
  );

  // ---------------------------------------------------------------------------
  // Runtime-resolved factory (preferred — reads APP_ENV at runtime)
  // ---------------------------------------------------------------------------

  /// Returns the fully resolved [AppConfig] for the current build.
  ///
  /// Unlike [instance], this factory correctly evaluates [AppEnvironment] from
  /// the `APP_ENV` define.  Use this everywhere outside of `const` contexts.
  static AppConfig resolved() {
    const rawEnv = String.fromEnvironment(
      _kEnvKey,
      defaultValue: 'development',
    );
    return AppConfig._(
      environment: AppEnvironment.fromString(rawEnv),
      supabaseUrl: const String.fromEnvironment(
        _kSupabaseUrlKey,
        defaultValue: '',
      ),
      supabaseAnonKey: const String.fromEnvironment(
        _kSupabaseAnonKey,
        defaultValue: '',
      ),
      revenueCatPublicKey: const String.fromEnvironment(
        _kRevenueCatPublicKey,
        defaultValue: '',
      ),
      binanceWsBaseUrl: const String.fromEnvironment(
        _kBinanceWsBaseUrl,
        defaultValue: 'wss://stream.binance.com:9443',
      ),
      coinGeckoApiKey: const String.fromEnvironment(
        _kCoinGeckoApiKey,
        defaultValue: '',
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Validation helpers
  // ---------------------------------------------------------------------------

  /// Returns `true` when all required values for a live Supabase connection
  /// are present.  Use this to guard Supabase client initialization.
  bool get isSupabaseConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  /// Returns `true` when the RevenueCat SDK key is present.
  bool get isRevenueCatConfigured => revenueCatPublicKey.isNotEmpty;

  /// Returns `true` when a CoinGecko paid-tier API key is present.
  ///
  /// The free tier works without a key; this guard is purely for rate-limit
  /// optimisation — it is safe to proceed without it.
  bool get isCoinGeckoKeyConfigured => coinGeckoApiKey.isNotEmpty;

  // ---------------------------------------------------------------------------
  // Diagnostics
  // ---------------------------------------------------------------------------

  /// Safe representation for logging — deliberately omits key values.
  @override
  String toString() {
    return 'AppConfig('
        'environment: ${environment.label}, '
        'supabaseConfigured: $isSupabaseConfigured, '
        'revenueCatConfigured: $isRevenueCatConfigured, '
        'coinGeckoKeyConfigured: $isCoinGeckoKeyConfigured'
        ')';
  }
}
