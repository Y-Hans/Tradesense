import 'package:cryptoedu/core/cache/domain/models/cache_entry.dart';
import 'package:cryptoedu/core/cache/domain/models/cache_result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CacheResult Sealed Hierarchy Unit Tests', () {
    final entry = CacheEntry<String>(
      key: 'k',
      value: 'hello',
      createdAt: DateTime(2026, 1, 1),
    );

    test('CacheHit properties and getters', () {
      final hit = CacheHit<String>(value: 'hello', entry: entry, isStale: false);

      expect(hit.isHit, isTrue);
      expect(hit.isMiss, isFalse);
      expect(hit.isExpired, isFalse);
      expect(hit.isFailure, isFalse);
      expect(hit.dataOrNull, equals('hello'));
      expect(hit.value, equals('hello'));
      expect(hit.isStale, isFalse);
    });

    test('CacheMiss properties and getters', () {
      const miss = CacheMiss<String>();

      expect(miss.isHit, isFalse);
      expect(miss.isMiss, isTrue);
      expect(miss.isExpired, isFalse);
      expect(miss.isFailure, isFalse);
      expect(miss.dataOrNull, isNull);
    });

    test('CacheExpired properties and getters', () {
      final expiredWithStale = CacheExpired<String>(staleEntry: entry);

      expect(expiredWithStale.isHit, isFalse);
      expect(expiredWithStale.isMiss, isFalse);
      expect(expiredWithStale.isExpired, isTrue);
      expect(expiredWithStale.isFailure, isFalse);
      expect(expiredWithStale.dataOrNull, equals('hello'));

      const expiredNoStale = CacheExpired<String>();
      expect(expiredNoStale.dataOrNull, isNull);
    });

    test('CacheFailure properties and getters', () {
      const error = FormatException('Bad JSON');
      const failure = CacheFailure<String>(error);

      expect(failure.isHit, isFalse);
      expect(failure.isMiss, isFalse);
      expect(failure.isExpired, isFalse);
      expect(failure.isFailure, isTrue);
      expect(failure.dataOrNull, isNull);
      expect(failure.error, equals(error));
    });

    test('Dart 3 pattern matching works as expected', () {
      final CacheResult<String> result = CacheHit<String>(value: 'test', entry: entry);

      final message = switch (result) {
        CacheHit(:final value) => 'Hit: $value',
        CacheMiss() => 'Miss',
        CacheExpired() => 'Expired',
        CacheFailure(:final error) => 'Failure: $error',
      };

      expect(message, equals('Hit: test'));
    });
  });
}
