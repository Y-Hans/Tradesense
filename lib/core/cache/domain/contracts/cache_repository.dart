import '../models/cache_policy.dart';
import '../models/cache_result.dart';

/// Generic repository abstraction for typed domain caching.
abstract class CacheRepository<T> {
  /// Retrieves cached payload for [key] evaluated against [policy].
  Future<CacheResult<T>> get(String key, {CachePolicy? policy});

  /// Caches [value] under [key] applying duration and version metadata from [policy].
  Future<void> set(String key, T value, {CachePolicy? policy});

  /// Removes cached entry associated with [key].
  Future<void> delete(String key);

  /// Clears all entries managed by this repository.
  Future<void> clear();

  /// Checks whether an entry exists for [key].
  Future<bool> containsKey(String key);
}
