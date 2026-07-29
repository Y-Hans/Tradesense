import '../../domain/contracts/cache_repository.dart';
import '../../domain/contracts/cache_storage.dart';
import '../../domain/models/cache_entry.dart';
import '../../domain/models/cache_policy.dart';
import '../../domain/models/cache_result.dart';
import '../serializers/cache_serializer.dart';

/// Clock function typedef for injectable time resolution.
typedef Clock = DateTime Function();

/// Default implementation of [CacheRepository<T>].
class DefaultCacheRepository<T> implements CacheRepository<T> {
  final CacheStorage _storage;
  final CacheSerializer<T> _serializer;
  final Clock _clock;

  DefaultCacheRepository({
    required CacheStorage storage,
    required CacheSerializer<T> serializer,
    Clock? clock,
  })  : _storage = storage,
        _serializer = serializer,
        _clock = clock ?? DateTime.now;

  @override
  Future<CacheResult<T>> get(String key, {CachePolicy? policy}) async {
    final effectivePolicy = policy ?? CachePolicy.defaultPolicy;

    try {
      final raw = await _storage.read(key);
      if (raw == null) {
        return CacheMiss<T>();
      }

      final entry = _serializer.deserialize(raw);

      // Check version mismatch if specified in policy
      if (effectivePolicy.version != null && entry.version != effectivePolicy.version) {
        return CacheExpired<T>(staleEntry: entry);
      }

      final now = _clock();
      final isExpired = entry.isExpired(now);

      if (isExpired) {
        if (effectivePolicy.allowStale) {
          return CacheHit<T>(
            value: entry.value,
            entry: entry,
            isStale: true,
          );
        } else {
          return CacheExpired<T>(staleEntry: entry);
        }
      }

      return CacheHit<T>(
        value: entry.value,
        entry: entry,
        isStale: false,
      );
    } catch (e, st) {
      return CacheFailure<T>(e, st);
    }
  }

  @override
  Future<void> set(String key, T value, {CachePolicy? policy}) async {
    final effectivePolicy = policy ?? CachePolicy.defaultPolicy;
    final now = _clock();

    final entry = CacheEntry<T>(
      key: key,
      value: value,
      createdAt: now,
      ttl: effectivePolicy.ttl,
      version: effectivePolicy.version,
    );

    final raw = _serializer.serialize(entry);
    await _storage.write(key, raw);
  }

  @override
  Future<void> delete(String key) async {
    await _storage.delete(key);
  }

  @override
  Future<void> clear() async {
    await _storage.clear();
  }

  @override
  Future<bool> containsKey(String key) async {
    return _storage.containsKey(key);
  }
}
