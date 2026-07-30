import '../../../../core/cache/domain/models/cache_policy.dart';

/// Centralized configuration for AI Coach cache policies and TTL definitions.
class CoachCachePolicyDefaults {
  CoachCachePolicyDefaults._();

  /// Default Time-To-Live duration for AI coach responses (24 hours).
  static const Duration defaultTtl = Duration(hours: 24);

  /// Current schema version tag for AI coach cache validation.
  static const String currentVersion = 'v1';

  /// Standard cache policy for AI coach requests with stale fallback allowed.
  static const CachePolicy defaultPolicy = CachePolicy(
    ttl: defaultTtl,
    allowStale: true,
    version: currentVersion,
  );
}
