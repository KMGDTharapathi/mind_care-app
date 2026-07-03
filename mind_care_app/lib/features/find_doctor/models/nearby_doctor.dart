import 'package:equatable/equatable.dart';

/// Represents a healthcare facility or professional returned from the Overpass API.
class NearbyDoctor extends Equatable {
  /// Overpass element id (e.g. "node/123456")
  final String id;

  /// OSM name tag, or "Unnamed Facility"
  final String name;

  /// Composed from addr:street + addr:city, or ""
  final String address;

  final double lat;
  final double lng;

  /// Haversine distance from search centre
  final double distanceKm;

  /// contact:phone or phone tag
  final String? phone;

  /// website tag
  final String? website;

  /// "hospital" | "clinic" | "doctor" | "healthcare"
  final String type;

  const NearbyDoctor({
    required this.id,
    required this.name,
    required this.address,
    required this.lat,
    required this.lng,
    required this.distanceKm,
    this.phone,
    this.website,
    required this.type,
  });

  /// Returns a copy of this [NearbyDoctor] with the given fields replaced.
  NearbyDoctor copyWith({
    String? id,
    String? name,
    String? address,
    double? lat,
    double? lng,
    double? distanceKm,
    String? phone,
    String? website,
    String? type,
  }) {
    return NearbyDoctor(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      distanceKm: distanceKm ?? this.distanceKm,
      phone: phone ?? this.phone,
      website: website ?? this.website,
      type: type ?? this.type,
    );
  }

  @override
  List<Object?> get props =>
      [id, name, address, lat, lng, distanceKm, phone, website, type];
}
