import 'package:flutter/foundation.dart';

/// Configuration policy describing caching metadata behavior for reads and writes.
@immutable
class CachePolicy {
  /// Time-To-Live duration for cached entries.
  /// If null, the cached item does not expire automatically.
  final Duration? ttl;

  /// Whether stale (expired) entries can be returned when reading,
  /// marked as stale in [CacheHit] or [CacheExpired].
  final bool allowStale;

  /// Optional version indicator for validation and invalidation.
  final String? version;

  const CachePolicy({
    this.ttl,
    this.allowStale = false,
    this.version,
  });

  /// Default policy with no expiration and no stale returns.
  static const CachePolicy defaultPolicy = CachePolicy();

  /// Policy helper for temporary caching with a specific TTL duration.
  factory CachePolicy.withTtl(Duration ttl,
      {bool allowStale = false, String? version}) {
    return CachePolicy(
      ttl: ttl,
      allowStale: allowStale,
      version: version,
    );
  }

  CachePolicy copyWith({
    Duration? ttl,
    bool? allowStale,
    String? version,
  }) {
    return CachePolicy(
      ttl: ttl ?? this.ttl,
      allowStale: allowStale ?? this.allowStale,
      version: version ?? this.version,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CachePolicy &&
        other.ttl == ttl &&
        other.allowStale == allowStale &&
        other.version == version;
  }

  @override
  int get hashCode => Object.hash(ttl, allowStale, version);

  @override
  String toString() {
    return 'CachePolicy(ttl: $ttl, allowStale: $allowStale, version: $version)';
  }
}
