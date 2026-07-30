import 'package:cryptoedu/core/cache/cache.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final testStringCacheRepoProvider = createCacheRepositoryProvider<String>(
  serializer: const StringCacheSerializer(),
);

void main() {
  group('Cache Riverpod Providers Unit Tests', () {
    test('default cacheStorageProvider returns InMemoryCacheStorage', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final storage = container.read(cacheStorageProvider);
      expect(storage, isA<InMemoryCacheStorage>());
    });

    test('createCacheRepositoryProvider creates strongly typed repository',
        () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final repo = container.read(testStringCacheRepoProvider);
      expect(repo, isA<CacheRepository<String>>());

      await repo.set('test_key', 'hello_riverpod');
      final result = await repo.get('test_key');

      expect(result.dataOrNull, equals('hello_riverpod'));
    });

    test(
        'overriding cacheClockProvider controls time deterministically in providers',
        () async {
      final fixedTime = DateTime(2026, 6, 1, 8, 0, 0);
      final container = ProviderContainer(
        overrides: [
          cacheClockProvider.overrideWithValue(() => fixedTime),
        ],
      );
      addTearDown(container.dispose);

      final repo = container.read(testStringCacheRepoProvider);

      const policy = CachePolicy(ttl: Duration(minutes: 5));
      await repo.set('k1', 'v1', policy: policy);

      final hitResult = await repo.get('k1', policy: policy);
      expect(hitResult.isHit, isTrue);
      expect(
          (hitResult as CacheHit<String>).entry.createdAt, equals(fixedTime));
    });

    test('overriding cacheStorageProvider uses custom storage implementation',
        () async {
      final customStorage = InMemoryCacheStorage();
      final container = ProviderContainer(
        overrides: [
          cacheStorageProvider.overrideWithValue(customStorage),
        ],
      );
      addTearDown(container.dispose);

      final repo = container.read(testStringCacheRepoProvider);
      await repo.set('k1', 'v1');

      expect(await customStorage.read('k1'), isNotNull);
    });
  });
}
