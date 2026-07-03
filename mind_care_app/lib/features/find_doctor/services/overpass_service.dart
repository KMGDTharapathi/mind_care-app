import 'dart:convert';
import 'package:flutter/foundation.dart'; // for @visibleForTesting
import 'package:http/http.dart' as http;
import '../models/nearby_doctor.dart';
import 'distance_calculator.dart';

/// Exception thrown when the Overpass API returns an HTTP error.
class OverpassException implements Exception {
  final String message;
  const OverpassException(this.message);
  @override
  String toString() => 'OverpassException: $message';
}

/// Internal cache entry holding a result list and its expiry time.
class _CacheEntry {
  final List<NearbyDoctor> doctors;
  final DateTime expiresAt;
  _CacheEntry(this.doctors, this.expiresAt);
  bool get isValid => DateTime.now().isBefore(expiresAt);
}

/// Queries the Overpass API for healthcare POIs near a coordinate.
/// Caches the most recent result per (lat, lng, radius) key for 5 minutes.
class OverpassService {
  static const _kOverpassUrl = 'https://overpass-api.de/api/interpreter';
  static const _kUserAgent = 'MindCareApp/1.0 (contact@mindcare.app)';
  static const _kCacheTtl = Duration(minutes: 5);
  static const _kMaxResults = 50;

  final http.Client _client;
  final Map<String, _CacheEntry> _cache = {};

  OverpassService({http.Client? client}) : _client = client ?? http.Client();

  /// Returns up to 50 [NearbyDoctor] entries within [radiusKm] of [center],
  /// sorted by ascending distance. Uses the TTL cache when available.
  Future<List<NearbyDoctor>> searchNearby(LatLng center, int radiusKm) async {
    final cacheKey =
        '${center.lat.toStringAsFixed(4)}_${center.lng.toStringAsFixed(4)}_$radiusKm';

    // Return cached result if still valid
    final cached = _cache[cacheKey];
    if (cached != null && cached.isValid) {
      return cached.doctors;
    }

    final query = _buildQuery(center, radiusKm);
    final body = 'data=${Uri.encodeComponent(query)}';

    final response = await _client.post(
      Uri.parse(_kOverpassUrl),
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'User-Agent': _kUserAgent,
      },
      body: body,
    );

    if (response.statusCode != 200) {
      throw OverpassException(
        'HTTP ${response.statusCode}: ${response.reasonPhrase}',
      );
    }

    final Map<String, dynamic> json = jsonDecode(response.body);
    final List<dynamic> elements = json['elements'] as List<dynamic>? ?? [];

    final doctors = <NearbyDoctor>[];
    for (final element in elements) {
      final doctor = parseElement(
        element as Map<String, dynamic>,
        center,
      );
      if (doctor != null) {
        doctors.add(doctor);
      }
    }

    // Sort ascending by distance, then cap at 50
    doctors.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    final capped = doctors.length > _kMaxResults
        ? doctors.sublist(0, _kMaxResults)
        : doctors;

    // Store in cache
    _cache[cacheKey] = _CacheEntry(
      capped,
      DateTime.now().add(_kCacheTtl),
    );

    return capped;
  }

  /// Builds the Overpass QL query string for the given [center] and [radiusKm].
  String _buildQuery(LatLng center, int radiusKm) {
    final radiusM = radiusKm * 1000;
    final lat = center.lat;
    final lng = center.lng;
    return '''
[out:json][timeout:25];
(
  node["healthcare"](around:$radiusM,$lat,$lng);
  way["healthcare"](around:$radiusM,$lat,$lng);
  node["amenity"="doctors"](around:$radiusM,$lat,$lng);
  way["amenity"="doctors"](around:$radiusM,$lat,$lng);
  node["amenity"="hospital"](around:$radiusM,$lat,$lng);
  way["amenity"="hospital"](around:$radiusM,$lat,$lng);
);
out body;
>;
out skel qt;
''';
  }

  /// Parses a single Overpass API element into a [NearbyDoctor].
  ///
  /// Returns `null` if the element has no usable lat/lng coordinates.
  @visibleForTesting
  NearbyDoctor? parseElement(
    Map<String, dynamic> element,
    LatLng center,
  ) {
    final String type = element['type'] as String? ?? '';
    final dynamic rawId = element['id'];
    final String id = '$type/$rawId';

    double? lat;
    double? lng;

    if (type == 'way') {
      // Way elements carry coordinates in the nested 'center' field
      final centerField = element['center'] as Map<String, dynamic>?;
      if (centerField != null) {
        lat = (centerField['lat'] as num?)?.toDouble();
        lng = (centerField['lon'] as num?)?.toDouble();
      }
    } else {
      // Node elements carry coordinates at the top level
      lat = (element['lat'] as num?)?.toDouble();
      lng = (element['lon'] as num?)?.toDouble();
    }

    // Skip elements with no usable coordinates
    if (lat == null || lng == null) {
      return null;
    }

    final tags = element['tags'] as Map<String, dynamic>? ?? {};

    final String name = tags['name'] as String? ?? 'Unnamed Facility';

    final street = tags['addr:street'] as String?;
    final city = tags['addr:city'] as String?;
    final addressParts = [street, city]
        .where((s) => s != null && s.isNotEmpty)
        .cast<String>()
        .toList();
    final String address = addressParts.join(', ');

    final String? phone =
        tags['contact:phone'] as String? ?? tags['phone'] as String?;
    final String? website = tags['website'] as String?;
    final String facilityType =
        tags['healthcare'] as String? ?? tags['amenity'] as String? ?? 'healthcare';

    final double distanceKm = DistanceCalculator.distanceKm(
      center,
      LatLng(lat, lng),
    );

    return NearbyDoctor(
      id: id,
      name: name,
      address: address,
      lat: lat,
      lng: lng,
      distanceKm: distanceKm,
      phone: phone,
      website: website,
      type: facilityType,
    );
  }
}
