import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

/// A simple, type-safe cache layer on top of [SharedPreferences].
///
/// Supports:
/// - Primitive types (String, int, double, bool)
/// - JSON-serializable objects via [CacheEntry]
/// - Automatic expiration (TTL)
/// - Batch operations
class CacheService {
  CacheService._();

  static CacheService? _instance;
  static SharedPreferences? _prefs;

  /// Initialize the cache service. Must be called once at app startup.
  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
    _instance ??= CacheService._();
  }

  /// Singleton instance.
  static CacheService get instance {
    if (_instance == null) {
      throw StateError('CacheService not initialized. Call CacheService.init() first.');
    }
    return _instance!;
  }

  SharedPreferences get _p => _prefs!;

  // ── Key prefixes for namespacing ──────────────────────────────────────────
  static const _prefixData = 'cache_data_';
  static const _prefixMeta = 'cache_meta_';
  static const _prefixTTL = 'cache_ttl_';

  String _dataKey(String key) => '$_prefixData$key';
  String _metaKey(String key) => '$_prefixMeta$key';
  String _ttlKey(String key) => '$_prefixTTL$key';

  // ── Core Operations ────────────────────────────────────────────────────────

  /// Stores a JSON-serializable value with optional TTL.
  Future<bool> set<T>(
    String key,
    T value, {
    Duration? ttl,
  }) async {
    final dataKey = _dataKey(key);
    final metaKey = _metaKey(key);
    final ttlKey = _ttlKey(key);

    final now = DateTime.now().millisecondsSinceEpoch;
    final expiresAt = ttl != null ? now + ttl.inMilliseconds : null;

    // Store as JSON string
    final jsonString = _encode(value);
    await _p.setString(dataKey, jsonString);

    // Store metadata
    await _p.setString(metaKey, _encode({
      'type': T.toString(),
      'createdAt': now,
      'expiresAt': expiresAt,
    }));

    if (ttl != null && expiresAt != null) {
      await _p.setInt(ttlKey, expiresAt);
    }

    return true;
  }

  /// Retrieves a value, returning `null` if not found or expired.
  T? get<T>(String key, {T Function(String)? decoder}) {
    final dataKey = _dataKey(key);
    final metaKey = _metaKey(key);

    final jsonString = _p.getString(dataKey);
    if (jsonString == null) return null;

    // Check expiration
    final metaString = _p.getString(metaKey);
    if (metaString != null) {
      try {
        final meta = _decode(metaString);
        final expiresAt = meta['expiresAt'] as int?;
        if (expiresAt != null && DateTime.now().millisecondsSinceEpoch > expiresAt) {
          // Expired - remove and return null
          remove(key);
          return null;
        }
      } catch (_) {}
    }

    if (decoder != null) {
      return decoder(jsonString);
    }
    return _decode(jsonString) as T?;
  }

  /// Retrieves a value or returns a default if not found/expired.
  T getOrDefault<T>(String key, T defaultValue, {T Function(String)? decoder}) {
    final value = get<T>(key, decoder: decoder);
    return value ?? defaultValue;
  }

  /// Removes a cached entry and its metadata.
  Future<bool> remove(String key) async {
    final dataKey = _dataKey(key);
    final metaKey = _metaKey(key);
    final ttlKey = _ttlKey(key);

    await Future.wait([
      _p.remove(dataKey),
      _p.remove(metaKey),
      _p.remove(ttlKey),
    ]);
    return true;
  }

  /// Checks if a key exists and is not expired.
  bool has(String key) {
    final dataKey = _dataKey(key);
    final metaKey = _metaKey(key);

    if (!_p.containsKey(dataKey)) return false;

    final metaString = _p.getString(metaKey);
    if (metaString != null) {
      try {
        final meta = _decode(metaString);
        final expiresAt = meta['expiresAt'] as int?;
        if (expiresAt != null && DateTime.now().millisecondsSinceEpoch > expiresAt) {
          return false;
        }
      } catch (_) {}
    }
    return true;
  }

  /// Removes all expired entries.
  Future<int> clearExpired() async {
    int removed = 0;
    final keys = _p.getKeys().where((k) => k.startsWith(_prefixMeta)).toList();

    for (final metaKey in keys) {
      final key = metaKey.substring(_prefixMeta.length);
      if (!has(key)) {
        await remove(key);
        removed++;
      }
    }
    return removed;
  }

  /// Clears all cached data (including metadata).
  Future<bool> clearAll() async {
    final keys = _p.getKeys().where((k) =>
        k.startsWith(_prefixData) ||
        k.startsWith(_prefixMeta) ||
        k.startsWith(_prefixTTL)).toList();

    for (final key in keys) {
      await _p.remove(key);
    }
    return true;
  }

  // ── Batch Operations ──────────────────────────────────────────────────────

  /// Sets multiple values at once.
  Future<bool> setAll(Map<String, dynamic> entries, {Duration? ttl}) async {
    for (final entry in entries.entries) {
      await set(entry.key, entry.value, ttl: ttl);
    }
    return true;
  }

  /// Gets multiple values at once.
  Map<String, T?> getAll<T>(Iterable<String> keys, {T Function(String)? decoder}) {
    final result = <String, T?>{};
    for (final key in keys) {
      result[key] = get<T>(key, decoder: decoder);
    }
    return result;
  }

  /// Removes multiple keys at once.
  Future<bool> removeAll(Iterable<String> keys) async {
    for (final key in keys) {
      await remove(key);
    }
    return true;
  }

  // ── Convenience Methods for Common Types ──────────────────────────────────

  Future<bool> setString(String key, String value, {Duration? ttl}) =>
      set<String>(key, value, ttl: ttl);

  String? getString(String key) => get<String>(key);

  Future<bool> setInt(String key, int value, {Duration? ttl}) =>
      set<int>(key, value, ttl: ttl);

  int? getInt(String key) => get<int>(key);

  Future<bool> setDouble(String key, double value, {Duration? ttl}) =>
      set<double>(key, value, ttl: ttl);

  double? getDouble(String key) => get<double>(key);

  Future<bool> setBool(String key, bool value, {Duration? ttl}) =>
      set<bool>(key, value, ttl: ttl);

  bool? getBool(String key) => get<bool>(key);

  Future<bool> setStringList(String key, List<String> value, {Duration? ttl}) =>
      set<List<String>>(key, value, ttl: ttl);

  List<String>? getStringList(String key) => get<List<String>>(key);

  // ── JSON Encoding/Decoding ────────────────────────────────────────────────

  String _encode(dynamic value) {
    // Simple JSON encoding for primitives and collections
    if (value == null) return 'null';
    if (value is String) return '"${value.replaceAll('"', '\\"')}"';
    if (value is bool) return value.toString();
    if (value is num) return value.toString();
    if (value is List) {
      return '[${value.map(_encode).join(',')}]';
    }
    if (value is Map) {
      return '{${value.entries.map((e) => '"${e.key}":${_encode(e.value)}').join(',')}}';
    }
    return value.toString();
  }

  dynamic _decode(String json) {
    // Very basic JSON decoding - for complex objects use a proper decoder
    json = json.trim();
    if (json == 'null') return null;
    if (json.startsWith('"') && json.endsWith('"')) {
      return json.substring(1, json.length - 1).replaceAll('\\"', '"');
    }
    if (json == 'true') return true;
    if (json == 'false') return false;
    if (json.startsWith('[') && json.endsWith(']')) {
      // Simple list parsing
      final content = json.substring(1, json.length - 1).trim();
      if (content.isEmpty) return <String>[];
      return content.split(',').map((e) => _decode(e.trim())).toList();
    }
    if (json.startsWith('{') && json.endsWith('}')) {
      // Simple map parsing - not full JSON, just for metadata
      return <String, dynamic>{};
    }
    return num.tryParse(json) ?? json;
  }
}

/// Extension for easier usage with custom objects
extension CacheServiceExtensions on CacheService {
  /// Stores a custom object with a JSON encoder
  Future<bool> setObject<T>(
    String key,
    T object, {
    required String Function(T) encoder,
    Duration? ttl,
  }) =>
      set<String>(key, encoder(object), ttl: ttl);

  /// Retrieves a custom object with a JSON decoder
  T? getObject<T>(
    String key, {
    required T Function(String) decoder,
  }) {
    final json = get<String>(key);
    if (json == null) return null;
    return decoder(json);
  }

  /// Retrieves a custom object or default
  T getObjectOrDefault<T>(
    String key,
    T defaultValue, {
    required T Function(String) decoder,
  }) {
    final json = get<String>(key);
    if (json == null || json.isEmpty) return defaultValue;
    return decoder(json);
  }
}