import '../../../../core/cache/domain/models/cache_policy.dart';

/// Centralized configuration for market data cache policies and TTL definitions.
class MarketCachePolicyDefaults {
  MarketCachePolicyDefaults._();

  /// Default Time-To-Live duration for market cache items (30 seconds).
  static const Duration defaultTtl = Duration(seconds: 30);

  /// Current schema version tag for market cache validation.
  static const String currentVersion = 'v1';

  /// Standard display policy for market repository requests.
  ///
  /// Stale values may be shown only as explicitly stale display data. They
  /// are never execution inputs; execution pricing is resolved afresh by the
  /// server-side execute_trade function.
  static const CachePolicy defaultPolicy = CachePolicy(
    ttl: defaultTtl,
    allowStale: true,
    version: currentVersion,
  );
}
