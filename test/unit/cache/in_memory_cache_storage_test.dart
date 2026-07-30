import 'package:cryptoedu/core/cache/data/storage/in_memory_cache_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('InMemoryCacheStorage Unit Tests', () {
    late InMemoryCacheStorage storage;

    setUp(() {
      storage = InMemoryCacheStorage();
    });

    test('read returns null when key does not exist', () async {
      final value = await storage.read('non_existent');
      expect(value, isNull);
    });

    test('write stores value and read retrieves it', () async {
      await storage.write('key1', 'val1');
      expect(await storage.read('key1'), equals('val1'));
      expect(await storage.containsKey('key1'), isTrue);
      expect(storage.length, equals(1));
    });

    test('write overwrites existing key', () async {
      await storage.write('key1', 'val1');
      await storage.write('key1', 'val2');
      expect(await storage.read('key1'), equals('val2'));
      expect(storage.length, equals(1));
    });

    test('delete removes entry', () async {
      await storage.write('key1', 'val1');
      await storage.delete('key1');
      expect(await storage.read('key1'), isNull);
      expect(await storage.containsKey('key1'), isFalse);
      expect(storage.length, equals(0));
    });

    test('clear wipes all entries', () async {
      await storage.write('k1', 'v1');
      await storage.write('k2', 'v2');
      expect(storage.length, equals(2));

      await storage.clear();
      expect(storage.length, equals(0));
      expect(await storage.containsKey('k1'), isFalse);
      expect(await storage.containsKey('k2'), isFalse);
    });
  });
}
