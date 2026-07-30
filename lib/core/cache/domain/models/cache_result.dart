import 'package:flutter/foundation.dart';
import 'cache_entry.dart';

/// Sealed hierarchy representing the explicit result of a cache lookup.
@immutable
sealed class CacheResult<T> {
  const CacheResult();

  /// Whether the cache lookup returned a valid hit.
  bool get isHit => this is CacheHit<T>;

  /// Whether the cache lookup missed (key not found).
  bool get isMiss => this is CacheMiss<T>;

  /// Whether the cache entry was found but expired.
  bool get isExpired => this is CacheExpired<T>;

  /// Whether an error occurred during read or deserialization.
  bool get isFailure => this is CacheFailure<T>;

  /// Returns the cached payload if available (hit or stale entry on expired), or null otherwise.
  T? get dataOrNull {
    final result = this;
    if (result is CacheHit<T>) {
      return result.value;
    } else if (result is CacheExpired<T>) {
      return result.staleEntry?.value;
    }
    return null;
  }
}

/// Represents a successful cache hit.
final class CacheHit<T> extends CacheResult<T> {
  /// The cached deserialized payload value.
  final T value;

  /// The complete cache entry with metadata.
  final CacheEntry<T> entry;

  /// Indicates whether the returned entry is stale (when allowed by policy).
  final bool isStale;

  const CacheHit({
    required this.value,
    required this.entry,
    this.isStale = false,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CacheHit<T> &&
        other.value == value &&
        other.entry == entry &&
        other.isStale == isStale;
  }

  @override
  int get hashCode => Object.hash(value, entry, isStale);

  @override
  String toString() => 'CacheHit(value: $value, isStale: $isStale)';
}

/// Represents a cache miss (key not present in storage).
final class CacheMiss<T> extends CacheResult<T> {
  const CacheMiss();

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is CacheMiss<T>;

  @override
  int get hashCode => (CacheMiss).hashCode;

  @override
  String toString() => 'CacheMiss()';
}

/// Represents an expired cache entry.
final class CacheExpired<T> extends CacheResult<T> {
  /// Optional stale cache entry if available and retained.
  final CacheEntry<T>? staleEntry;

  const CacheExpired({this.staleEntry});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CacheExpired<T> && other.staleEntry == staleEntry;
  }

  @override
  int get hashCode => staleEntry.hashCode;

  @override
  String toString() => 'CacheExpired(staleEntry: $staleEntry)';
}

/// Represents a failure during cache read, corrupt payload, or deserialization error.
final class CacheFailure<T> extends CacheResult<T> {
  /// The underlying error or exception encountered.
  final Object error;

  /// StackTrace associated with the error, if available.
  final StackTrace? stackTrace;

  const CacheFailure(this.error, [this.stackTrace]);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CacheFailure<T> && other.error == error;
  }

  @override
  int get hashCode => error.hashCode;

  @override
  String toString() => 'CacheFailure(error: $error)';
}
