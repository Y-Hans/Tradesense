import 'package:cryptoedu/core/cache/domain/models/cache_entry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CacheEntry Unit Tests', () {
    test('isExpired returns false when ttl is null', () {
      final now = DateTime(2026, 1, 1, 12, 0, 0);
      final entry = CacheEntry<String>(
        key: 'key1',
        value: 'val1',
        createdAt: now,
        ttl: null,
      );

      final checkTime = now.add(const Duration(days: 365));
      expect(entry.isExpired(checkTime), isFalse);
    });

    test('isExpired returns false when within ttl window', () {
      final createdAt = DateTime(2026, 1, 1, 12, 0, 0);
      final entry = CacheEntry<String>(
        key: 'key1',
        value: 'val1',
        createdAt: createdAt,
        ttl: const Duration(minutes: 5),
      );

      final withinWindow =
          createdAt.add(const Duration(minutes: 4, seconds: 59));
      expect(entry.isExpired(withinWindow), isFalse);
    });

    test('isExpired returns true when past ttl window', () {
      final createdAt = DateTime(2026, 1, 1, 12, 0, 0);
      final entry = CacheEntry<String>(
        key: 'key1',
        value: 'val1',
        createdAt: createdAt,
        ttl: const Duration(minutes: 5),
      );

      final afterWindow = createdAt.add(const Duration(minutes: 5, seconds: 1));
      expect(entry.isExpired(afterWindow), isTrue);
    });

    test('copyWith produces updated instance correctly', () {
      final createdAt = DateTime(2026, 1, 1, 12, 0, 0);
      final entry = CacheEntry<int>(
        key: 'count',
        value: 10,
        createdAt: createdAt,
        ttl: const Duration(seconds: 30),
        version: 'v1',
      );

      final updated = entry.copyWith(value: 20, version: 'v2');
      expect(updated.key, equals('count'));
      expect(updated.value, equals(20));
      expect(updated.createdAt, equals(createdAt));
      expect(updated.ttl, equals(const Duration(seconds: 30)));
      expect(updated.version, equals('v2'));
    });

    test('equality and hashCode work as expected', () {
      final time = DateTime(2026, 1, 1, 12, 0, 0);
      final entry1 = CacheEntry<String>(
        key: 'k',
        value: 'v',
        createdAt: time,
        ttl: const Duration(minutes: 1),
      );
      final entry2 = CacheEntry<String>(
        key: 'k',
        value: 'v',
        createdAt: time,
        ttl: const Duration(minutes: 1),
      );

      expect(entry1, equals(entry2));
      expect(entry1.hashCode, equals(entry2.hashCode));
    });
  });
}
