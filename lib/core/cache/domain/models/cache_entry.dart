import 'package:flutter/foundation.dart';

/// Generic model representing a cached entry with metadata.
@immutable
class CacheEntry<T> {
  /// Unique cache key
  final String key;

  /// The cached payload value
  final T value;

  /// Timestamp when the entry was created or last updated
  final DateTime createdAt;

  /// Time-To-Live duration, or null if the entry never expires
  final Duration? ttl;

  /// Optional version tag for cache schema/invalidation management
  final String? version;

  const CacheEntry({
    required this.key,
    required this.value,
    required this.createdAt,
    this.ttl,
    this.version,
  });

  /// Deterministically checks if this entry is expired relative to [currentTime].
  bool isExpired(DateTime currentTime) {
    if (ttl == null) return false;
    return currentTime.isAfter(createdAt.add(ttl!));
  }

  CacheEntry<T> copyWith({
    String? key,
    T? value,
    DateTime? createdAt,
    Duration? ttl,
    String? version,
  }) {
    return CacheEntry<T>(
      key: key ?? this.key,
      value: value ?? this.value,
      createdAt: createdAt ?? this.createdAt,
      ttl: ttl ?? this.ttl,
      version: version ?? this.version,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CacheEntry<T> &&
        other.key == key &&
        other.value == value &&
        other.createdAt == createdAt &&
        other.ttl == ttl &&
        other.version == version;
  }

  @override
  int get hashCode => Object.hash(key, value, createdAt, ttl, version);

  @override
  String toString() {
    return 'CacheEntry(key: $key, value: $value, createdAt: $createdAt, ttl: $ttl, version: $version)';
  }
}
