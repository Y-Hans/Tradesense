/// Minimal key-value storage contract for persistent or in-memory cache engines.
abstract class CacheStorage {
  /// Reads raw string content stored at [key]. Returns null if not found.
  Future<String?> read(String key);

  /// Writes raw string [value] at [key].
  Future<void> write(String key, String value);

  /// Removes entry at [key] if present.
  Future<void> delete(String key);

  /// Clears all entries from storage.
  Future<void> clear();

  /// Checks if [key] exists in storage.
  Future<bool> containsKey(String key);
}
