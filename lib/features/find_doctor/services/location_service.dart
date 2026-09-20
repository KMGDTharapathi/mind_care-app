import 'dart:async';
import 'package:geolocator/geolocator.dart';

class LocationService {
  /// Checks current permission status and requests foreground permission if
  /// not yet determined. Returns the resulting [LocationPermission].
  /// Never requests background permission.
  Future<LocationPermission> checkAndRequestPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission;
  }

  /// Returns the device's current position.
  /// Throws [TimeoutException] if GPS does not respond within 15 seconds.
  Future<Position> getCurrentPosition() async {
    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    ).timeout(
      const Duration(seconds: 15),
      onTimeout: () => throw TimeoutException('GPS timed out after 15 seconds'),
    );
  }
}
