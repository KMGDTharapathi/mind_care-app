import 'dart:math';

/// A simple geographic coordinate value class.
class LatLng {
  final double lat;
  final double lng;

  const LatLng(this.lat, this.lng);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LatLng &&
          runtimeType == other.runtimeType &&
          lat == other.lat &&
          lng == other.lng;

  @override
  int get hashCode => lat.hashCode ^ lng.hashCode;

  @override
  String toString() => 'LatLng($lat, $lng)';
}

/// Pure utility class for geographic distance calculations.
/// No state, no I/O.
class DistanceCalculator {
  /// Returns the great-circle distance in kilometres between [a] and [b]
  /// using the Haversine formula.
  ///
  /// Earth radius = 6371.0 km
  static double distanceKm(LatLng a, LatLng b) {
    const double earthRadiusKm = 6371.0;

    final double dLat = (b.lat - a.lat) * pi / 180.0;
    final double dLng = (b.lng - a.lng) * pi / 180.0;

    final double aVal = sin(dLat / 2) * sin(dLat / 2) +
        cos(a.lat * pi / 180.0) *
            cos(b.lat * pi / 180.0) *
            sin(dLng / 2) *
            sin(dLng / 2);

    final double c = 2 * atan2(sqrt(aVal), sqrt(1 - aVal));

    return earthRadiusKm * c;
  }
}
