import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/default_cache_repository.dart';
import '../data/serializers/cache_serializer.dart';
import '../data/storage/in_memory_cache_storage.dart';
import '../domain/contracts/cache_repository.dart';
import '../domain/contracts/cache_storage.dart';

/// Provider exposing the injectable [Clock] function for timestamping and TTL resolution.
final cacheClockProvider = Provider<Clock>((ref) => DateTime.now);

/// Provider exposing the default [CacheStorage] engine.
final cacheStorageProvider = Provider<CacheStorage>((ref) {
  return InMemoryCacheStorage();
});

/// Creates a strongly-typed Riverpod [Provider] for a [CacheRepository<T>].
///
/// Features can define their own providers using this helper:
/// ```dart
/// final stringCacheRepoProvider = createCacheRepositoryProvider<String>(
///   serializer: StringCacheSerializer(),
/// );
/// ```
Provider<CacheRepository<T>> createCacheRepositoryProvider<T>({
  required CacheSerializer<T> serializer,
  CacheStorage? customStorage,
}) {
  return Provider<CacheRepository<T>>((ref) {
    final CacheStorage storage = customStorage ?? ref.watch(cacheStorageProvider);
    final clock = ref.watch(cacheClockProvider);
    return DefaultCacheRepository<T>(
      storage: storage,
      serializer: serializer,
      clock: clock,
    );
  });
}
