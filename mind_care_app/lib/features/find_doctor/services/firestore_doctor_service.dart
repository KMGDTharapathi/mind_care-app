import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/nearby_doctor.dart';
import '../../counsellor/data/doctor_seed_data.dart';

/// Fetches the seeded doctors/counsellors from Firestore and maps them to
/// [NearbyDoctor] so they can be displayed in the Find Doctor screen.
class FirestoreDoctorService {
  final FirebaseFirestore _firestore;

  FirestoreDoctorService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Returns all verified doctors from Firestore, sorted by availability
  /// (available first) then by name.
  ///
  /// Since Firestore seed data has no lat/lng coordinates, [distanceKm] is
  /// set to 0.0 for all entries. The [type] field is mapped from
  /// [specialization].
  Future<List<NearbyDoctor>> fetchAll() async {
    final snapshot = await _firestore
        .collection('doctors')
        .where('is_verified', isEqualTo: true)
        .get();

    final doctors = snapshot.docs
        .where((doc) => doc.id != '__seed_meta__')
        .map((doc) {
          final data = doc.data();

          // Merge address/clinicHours from seed data if missing in Firestore
          String address = data['address'] as String? ?? '';
          if (address.isEmpty) {
            final match = kRealDoctors
                .where((s) => s['name'] == data['name'])
                .firstOrNull;
            if (match != null) {
              address = match['address'] as String? ?? '';
            }
          }

          final specialization =
              data['specialization'] as String? ?? 'healthcare';
          final type = _specializationToType(specialization);

          return NearbyDoctor(
            id: doc.id,
            name: data['name'] as String? ?? 'Unknown',
            address: address,
            lat: 0.0,
            lng: 0.0,
            distanceKm: 0.0,
            phone: null,
            website: null,
            type: type,
          );
        })
        .toList();

    // Available doctors first, then alphabetical
    doctors.sort((a, b) {
      final aAvail = _isAvailable(snapshot, a.id) ? 0 : 1;
      final bAvail = _isAvailable(snapshot, b.id) ? 0 : 1;
      if (aAvail != bAvail) return aAvail.compareTo(bAvail);
      return a.name.compareTo(b.name);
    });

    return doctors;
  }

  bool _isAvailable(QuerySnapshot snapshot, String id) {
    try {
      final doc = snapshot.docs.firstWhere((d) => d.id == id);
      return (doc.data() as Map<String, dynamic>)['is_available'] as bool? ??
          false;
    } catch (_) {
      return false;
    }
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
