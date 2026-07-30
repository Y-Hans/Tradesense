import '../../domain/contracts/cache_storage.dart';

/// In-memory implementation of [CacheStorage] using a Dart Map.
class InMemoryCacheStorage implements CacheStorage {
  final Map<String, String> _store = {};

  @override
  Future<String?> read(String key) async {
    return _store[key];
  }

  @override
  Future<void> write(String key, String value) async {
    _store[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    _store.remove(key);
  }

  @override
  Future<void> clear() async {
    _store.clear();
  }

  @override
  Future<bool> containsKey(String key) async {
    return _store.containsKey(key);
  }

  /// Number of entries currently stored (utility getter for testing/monitoring).
  int get length => _store.length;
}
