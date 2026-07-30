import 'package:cryptoedu/core/cache/data/serializers/cache_serializer.dart';
import 'package:cryptoedu/core/cache/domain/models/cache_entry.dart';
import 'package:flutter_test/flutter_test.dart';

class _TestUser {
  final String id;
  final String name;

  const _TestUser({required this.id, required this.name});

  Map<String, dynamic> toJson() => {'id': id, 'name': name};

  factory _TestUser.fromJson(Map<String, dynamic> json) {
    return _TestUser(
      id: json['id'] as String,
      name: json['name'] as String,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _TestUser && other.id == id && other.name == name;

  @override
  int get hashCode => Object.hash(id, name);
}

void main() {
  group('CacheSerializer Unit Tests', () {
    test('StringCacheSerializer serializes and deserializes correctly', () {
      const serializer = StringCacheSerializer();
      final now = DateTime(2026, 1, 1, 10, 0, 0);

      final entry = CacheEntry<String>(
        key: 'str_key',
        value: 'hello world',
        createdAt: now,
        ttl: const Duration(hours: 1),
        version: 'v1.0',
      );

      final raw = serializer.serialize(entry);
      final deserialized = serializer.deserialize(raw);

      expect(deserialized.key, equals('str_key'));
      expect(deserialized.value, equals('hello world'));
      expect(deserialized.createdAt, equals(now));
      expect(deserialized.ttl, equals(const Duration(hours: 1)));
      expect(deserialized.version, equals('v1.0'));
    });

    test(
        'JsonCacheSerializer serializes and deserializes custom object correctly',
        () {
      final serializer = JsonCacheSerializer<_TestUser>(
        toJson: (user) => user.toJson(),
        fromJson: (json) => _TestUser.fromJson(json as Map<String, dynamic>),
      );

      final now = DateTime(2026, 1, 1, 10, 0, 0);
      const user = _TestUser(id: 'u123', name: 'Alice');

      final entry = CacheEntry<_TestUser>(
        key: 'user_u123',
        value: user,
        createdAt: now,
        ttl: null,
      );

      final raw = serializer.serialize(entry);
      final deserialized = serializer.deserialize(raw);

      expect(deserialized.key, equals('user_u123'));
      expect(deserialized.value, equals(user));
      expect(deserialized.createdAt, equals(now));
      expect(deserialized.ttl, isNull);
    });

    test('deserialize throws FormatException on invalid json structure', () {
      const serializer = StringCacheSerializer();
      expect(
        () => serializer.deserialize('not a json'),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
