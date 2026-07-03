import 'dart:collection';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'distance_calculator.dart';

/// Exception thrown when geocoding fails due to an HTTP error or network failure.
class GeocoderException implements Exception {
  final String message;
  const GeocoderException(this.message);

  @override
  String toString() => 'GeocoderException: $message';
}

/// Service that converts a place/district name into geographic coordinates
/// using the Nominatim OpenStreetMap API.
///
/// Features:
/// - LRU cache with capacity 10 (keyed by normalised query string)
/// - Rate limiting: minimum 1-second interval between outbound HTTP requests
/// - Accepts an optional [http.Client] for testability
class GeocoderService {
  static const int _kCacheCapacity = 10;
  static const String _kUserAgent = 'MindCareApp/1.0 (contact@mindcare.app)';
  static const Duration _kMinInterval = Duration(seconds: 1);

  final http.Client _client;

  /// LRU cache: insertion-ordered map; oldest entry is at the front.
  final LinkedHashMap<String, LatLng> _cache = LinkedHashMap();

  /// Timestamp of the last outbound HTTP request.
  DateTime? _lastRequestTime;

  GeocoderService({http.Client? client}) : _client = client ?? http.Client();

  /// Converts [query] (a district or place name) to a [LatLng] coordinate.
  ///
  /// Returns `null` if the Nominatim API returns no results for the query.
  /// Throws [GeocoderException] on HTTP errors (non-200 status) or network
  /// failures.
  ///
  /// Results are cached in an LRU cache (capacity 10). Repeated calls with
  /// the same query (case-insensitive, trimmed) return the cached value
  /// without making a network request.
  Future<LatLng?> geocode(String query) async {
    final key = query.trim().toLowerCase();
    if (key.isEmpty) return null;

    // Return cached result if available.
    if (_cache.containsKey(key)) {
      // Move to end to mark as most-recently used.
      final cached = _cache.remove(key)!;
      _cache[key] = cached;
      return cached;
    }

    // Enforce minimum interval between outbound requests.
    final now = DateTime.now();
    if (_lastRequestTime != null) {
      final elapsed = now.difference(_lastRequestTime!);
      if (elapsed < _kMinInterval) {
        await Future.delayed(_kMinInterval - elapsed);
      }
    }
    _lastRequestTime = DateTime.now();

    // Build Nominatim URL restricted to Sri Lanka.
    final uri = Uri.parse(
      'https://nominatim.openstreetmap.org/search'
      '?q=${Uri.encodeComponent(query.trim())}'
      '&countrycodes=lk&format=json&limit=1',
    );

    try {
      final response = await _client.get(
        uri,
        headers: {'User-Agent': _kUserAgent},
      );

      if (response.statusCode != 200) {
        throw GeocoderException(
          'Nominatim returned status ${response.statusCode}',
        );
      }

      final List<dynamic> results =
          jsonDecode(response.body) as List<dynamic>;

      if (results.isEmpty) return null;

      final first = results.first as Map<String, dynamic>;
      final lat = double.parse(first['lat'] as String);
      final lng = double.parse(first['lon'] as String);
      final result = LatLng(lat, lng);

      // Evict the oldest (first) entry when at capacity.
      if (_cache.length >= _kCacheCapacity) {
        _cache.remove(_cache.keys.first);
      }
      _cache[key] = result;

      return result;
    } on GeocoderException {
      rethrow;
    } catch (e) {
      throw GeocoderException('Failed to geocode "$query": $e');
    }
  }
}
