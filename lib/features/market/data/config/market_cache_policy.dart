import '../../../../core/cache/domain/models/cache_policy.dart';

/// Centralized configuration for market data cache policies and TTL definitions.
class MarketCachePolicyDefaults {
  MarketCachePolicyDefaults._();

  /// Default Time-To-Live duration for market cache items (5 minutes).
  static const Duration defaultTtl = Duration(minutes: 5);

  /// Current schema version tag for market cache validation.
  static const String currentVersion = 'v1';

  /// Standard cache policy for market repository requests with stale fallback allowed.
  static const CachePolicy defaultPolicy = CachePolicy(
    ttl: defaultTtl,
    allowStale: true,
    version: currentVersion,
  );
}
