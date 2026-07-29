import 'package:cryptoedu/core/cache/data/repositories/default_cache_repository.dart';
import 'package:cryptoedu/core/cache/data/serializers/cache_serializer.dart';
import 'package:cryptoedu/core/cache/data/storage/in_memory_cache_storage.dart';
import 'package:cryptoedu/core/cache/domain/models/cache_policy.dart';
import 'package:cryptoedu/core/cache/domain/models/cache_result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DefaultCacheRepository Unit Tests', () {
    late InMemoryCacheStorage storage;
    late StringCacheSerializer serializer;
    late DateTime currentTime;
    late DefaultCacheRepository<String> repository;

    setUp(() {
      storage = InMemoryCacheStorage();
      serializer = const StringCacheSerializer();
      currentTime = DateTime(2026, 1, 1, 12, 0, 0);
      repository = DefaultCacheRepository<String>(
        storage: storage,
        serializer: serializer,
        clock: () => currentTime,
      );
    });

    test('get returns CacheMiss when key is not present', () async {
      final result = await repository.get('missing_key');
      expect(result, isA<CacheMiss<String>>());
      expect(result.isMiss, isTrue);
      expect(result.dataOrNull, isNull);
    });

    test('set and get returns CacheHit for valid non-expired item', () async {
      const policy = CachePolicy(ttl: Duration(minutes: 10));
      await repository.set('k1', 'v1', policy: policy);

      final result = await repository.get('k1', policy: policy);
      expect(result, isA<CacheHit<String>>());

      final hit = result as CacheHit<String>;
      expect(hit.value, equals('v1'));
      expect(hit.isStale, isFalse);
      expect(hit.entry.key, equals('k1'));
    });

    test('deterministic expiration with injected clock', () async {
      const policy = CachePolicy(ttl: Duration(minutes: 10));
      await repository.set('k1', 'v1', policy: policy);

      // Advance clock by 5 minutes (within TTL)
      currentTime = currentTime.add(const Duration(minutes: 5));
      final resultWithin = await repository.get('k1', policy: policy);
      expect(resultWithin, isA<CacheHit<String>>());
      expect((resultWithin as CacheHit<String>).isStale, isFalse);

      // Advance clock past 10 minutes (expired)
      currentTime = currentTime.add(const Duration(minutes: 6));
      final resultExpired = await repository.get('k1', policy: policy);
      expect(resultExpired, isA<CacheExpired<String>>());
      expect((resultExpired as CacheExpired<String>).staleEntry?.value, equals('v1'));
    });

    test('expired entry returns CacheHit with isStale=true when allowStale is true', () async {
      const setPolicy = CachePolicy(ttl: Duration(minutes: 10));
      await repository.set('k1', 'v1', policy: setPolicy);

      // Advance time past TTL
      currentTime = currentTime.add(const Duration(minutes: 15));

      const getPolicyWithStale = CachePolicy(ttl: Duration(minutes: 10), allowStale: true);
      final result = await repository.get('k1', policy: getPolicyWithStale);

      expect(result, isA<CacheHit<String>>());
      final hit = result as CacheHit<String>;
      expect(hit.value, equals('v1'));
      expect(hit.isStale, isTrue);
    });

    test('version mismatch returns CacheExpired', () async {
      const policyV1 = CachePolicy(version: 'v1');
      await repository.set('k1', 'v1', policy: policyV1);

      const policyV2 = CachePolicy(version: 'v2');
      final result = await repository.get('k1', policy: policyV2);

      expect(result, isA<CacheExpired<String>>());
    });

    test('overwrite updates existing cache entry', () async {
      await repository.set('k1', 'val_initial');
      await repository.set('k1', 'val_updated');

      final result = await repository.get('k1');
      expect(result.dataOrNull, equals('val_updated'));
    });

    test('delete removes cached entry', () async {
      await repository.set('k1', 'v1');
      expect(await repository.containsKey('k1'), isTrue);

      await repository.delete('k1');
      expect(await repository.containsKey('k1'), isFalse);
      expect(await repository.get('k1'), isA<CacheMiss<String>>());
    });

    test('clear removes all entries in storage', () async {
      await repository.set('k1', 'v1');
      await repository.set('k2', 'v2');

      await repository.clear();
      expect(await repository.get('k1'), isA<CacheMiss<String>>());
      expect(await repository.get('k2'), isA<CacheMiss<String>>());
    });

    test('corrupted data returns CacheFailure gracefully without crashing', () async {
      // Manually write bad raw payload to storage
      await storage.write('corrupt_key', 'definitely not valid json');

      final result = await repository.get('corrupt_key');
      expect(result, isA<CacheFailure<String>>());
      expect((result as CacheFailure<String>).error, isA<FormatException>());
      expect(result.dataOrNull, isNull);
    });
  });
}
