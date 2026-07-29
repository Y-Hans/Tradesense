import 'package:cryptoedu/core/cache/domain/models/cache_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CachePolicy Unit Tests', () {
    test('default policy properties', () {
      const policy = CachePolicy.defaultPolicy;
      expect(policy.ttl, isNull);
      expect(policy.allowStale, isFalse);
      expect(policy.version, isNull);
    });

    test('CachePolicy.withTtl factory construct', () {
      final policy = CachePolicy.withTtl(
        const Duration(minutes: 15),
        allowStale: true,
        version: '1.0',
      );
      expect(policy.ttl, equals(const Duration(minutes: 15)));
      expect(policy.allowStale, isTrue);
      expect(policy.version, equals('1.0'));
    });

    test('copyWith updates properties correctly', () {
      const initial = CachePolicy(ttl: Duration(minutes: 5), allowStale: false);
      final updated = initial.copyWith(allowStale: true, version: 'v2');

      expect(updated.ttl, equals(const Duration(minutes: 5)));
      expect(updated.allowStale, isTrue);
      expect(updated.version, equals('v2'));
    });
  });
}
