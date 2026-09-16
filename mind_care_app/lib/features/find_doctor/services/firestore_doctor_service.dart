import '../models/nearby_doctor.dart';
import '../../counsellor/data/doctor_seed_data.dart';

/// Local implementation that fetches doctors from seed data instead of Firestore.
/// Used when running without Firebase.
class FirestoreDoctorService {
  /// Returns all verified doctors from seed data.
  Future<List<NearbyDoctor>> fetchAll() async {
    final doctors = kRealDoctors
        .where((s) => s['verified'] == true)
        .map((data) {
      final specialization = data['specialization'] as String? ?? 'healthcare';
      final type = _specializationToType(specialization);

      return NearbyDoctor(
        id: data['id'] as String? ?? data['name'] as String? ?? 'unknown',
        name: data['name'] as String? ?? 'Unknown',
        address: data['address'] as String? ?? '',
        lat: 0.0,
        lng: 0.0,
        distanceKm: 0.0,
        phone: data['phone'] as String?,
        website: data['website'] as String?,
        type: type,
      );
    })
    .toList();

    // Available doctors first, then alphabetical
    doctors.sort((a, b) {
      final aAvail = _isAvailable(a) ? 0 : 1;
      final bAvail = _isAvailable(b) ? 0 : 1;
      if (aAvail != bAvail) return aAvail.compareTo(bAvail);
      return a.name.compareTo(b.name);
    });

    return doctors;
  }

  bool _isAvailable(NearbyDoctor doctor) {
    // Check if doctor has availability from seed data
    final match = kRealDoctors.where((s) => s['name'] == doctor.name).firstOrNull;
    return match?['is_available'] as bool? ?? false;
  }

  String _specializationToType(String specialization) {
    switch (specialization.toLowerCase()) {
      case 'psychiatrist':
        return 'psychiatrist';
      case 'clinical psychologist':
        return 'psychologist';
      case 'counsellor':
      case 'counselor':
        return 'counsellor';
      case 'gp':
        return 'general_practitioner';
      default:
        return 'healthcare';
    }
  }
}