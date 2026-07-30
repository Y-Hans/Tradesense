import 'dart:convert';
import '../../domain/models/cache_entry.dart';

/// Contract for serializing complete [CacheEntry<T>] objects (metadata + payload T).
abstract class CacheSerializer<T> {
  /// Serializes [entry] into a raw String format for storage.
  String serialize(CacheEntry<T> entry);

  /// Deserializes raw stored String into a typed [CacheEntry<T>].
  CacheEntry<T> deserialize(String raw);
}

/// Generic JSON implementation of [CacheSerializer<T>].
class JsonCacheSerializer<T> implements CacheSerializer<T> {
  final Object? Function(T value) _toJson;
  final T Function(dynamic json) _fromJson;

  const JsonCacheSerializer({
    required Object? Function(T value) toJson,
    required T Function(dynamic json) fromJson,
  })  : _toJson = toJson,
        _fromJson = fromJson;

  @override
  String serialize(CacheEntry<T> entry) {
    final map = <String, dynamic>{
      'key': entry.key,
      'createdAt': entry.createdAt.toIso8601String(),
      'ttlMilliseconds': entry.ttl?.inMilliseconds,
      'version': entry.version,
      'value': _toJson(entry.value),
    };
    return jsonEncode(map);
  }

  @override
  CacheEntry<T> deserialize(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException(
          'Invalid cache entry JSON structure: expected Map');
    }

    final key = decoded['key'] as String;
    final createdAt = DateTime.parse(decoded['createdAt'] as String);
    final ttlMs = decoded['ttlMilliseconds'] as int?;
    final ttl = ttlMs != null ? Duration(milliseconds: ttlMs) : null;
    final version = decoded['version'] as String?;
    final value = _fromJson(decoded['value']);

    return CacheEntry<T>(
      key: key,
      value: value,
      createdAt: createdAt,
      ttl: ttl,
      version: version,
    );
  }
}

/// Specialized serializer for primitive [String] cache payloads.
class StringCacheSerializer extends JsonCacheSerializer<String> {
  const StringCacheSerializer()
      : super(
          toJson: _identityToJson,
          fromJson: _identityFromJson,
        );

  static Object? _identityToJson(String value) => value;
  static String _identityFromJson(dynamic json) => json as String;
}
