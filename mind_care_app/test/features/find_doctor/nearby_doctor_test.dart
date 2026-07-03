import 'package:flutter_test/flutter_test.dart';
import 'package:mind_care_app/features/find_doctor/models/nearby_doctor.dart';

void main() {
  group('NearbyDoctor', () {
    const doctor = NearbyDoctor(
      id: 'node/123456',
      name: 'City Mental Health Clinic',
      address: '42 Main St, Colombo',
      lat: 6.9271,
      lng: 79.8612,
      distanceKm: 2.5,
      phone: '+94112345678',
      website: 'https://example.com',
      type: 'clinic',
    );

    test('props includes all fields', () {
      expect(
        doctor.props,
        equals([
          'node/123456',
          'City Mental Health Clinic',
          '42 Main St, Colombo',
          6.9271,
          79.8612,
          2.5,
          '+94112345678',
          'https://example.com',
          'clinic',
        ]),
      );
    });

    test('equality holds for identical instances', () {
      const same = NearbyDoctor(
        id: 'node/123456',
        name: 'City Mental Health Clinic',
        address: '42 Main St, Colombo',
        lat: 6.9271,
        lng: 79.8612,
        distanceKm: 2.5,
        phone: '+94112345678',
        website: 'https://example.com',
        type: 'clinic',
      );
      expect(doctor, equals(same));
    });

    test('inequality when any field differs', () {
      final different = doctor.copyWith(distanceKm: 5.0);
      expect(doctor, isNot(equals(different)));
    });

    test('copyWith returns new instance with updated fields', () {
      final updated = doctor.copyWith(
        name: 'Updated Clinic',
        distanceKm: 1.2,
        phone: null,
      );

      expect(updated.name, 'Updated Clinic');
      expect(updated.distanceKm, 1.2);
      // phone is not overridden when null is passed — copyWith keeps original
      expect(updated.phone, '+94112345678');
      // unchanged fields are preserved
      expect(updated.id, doctor.id);
      expect(updated.address, doctor.address);
      expect(updated.lat, doctor.lat);
      expect(updated.lng, doctor.lng);
      expect(updated.website, doctor.website);
      expect(updated.type, doctor.type);
    });

    test('copyWith with no arguments returns equivalent instance', () {
      final copy = doctor.copyWith();
      expect(copy, equals(doctor));
    });

    test('optional fields can be null', () {
      const minimal = NearbyDoctor(
        id: 'way/999',
        name: 'Unnamed Facility',
        address: '',
        lat: 7.0,
        lng: 80.0,
        distanceKm: 0.5,
        type: 'hospital',
      );
      expect(minimal.phone, isNull);
      expect(minimal.website, isNull);
    });
  });
}
