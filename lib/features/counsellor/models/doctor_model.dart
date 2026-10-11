import 'package:cloud_firestore/cloud_firestore.dart';

class Doctor {
  final String id;
  final String name;
  final String photoUrl;
  final String specialization;
  final List<String> languages;
  final String bio;
  final List<String> qualifications;
  final String registrationNo;
  final String hospital;
  final String? address;
  final String? clinicHours;
  final bool isVerified;
  final bool isAvailable;
  final String callType;

  const Doctor({
    required this.id,
    required this.name,
    required this.photoUrl,
    required this.specialization,
    required this.languages,
    required this.bio,
    required this.qualifications,
    required this.registrationNo,
    required this.hospital,
    this.address,
    this.clinicHours,
    required this.isVerified,
    required this.isAvailable,
    required this.callType,
  });

  factory Doctor.fromFirestore(DocumentSnapshot doc) {
    return Doctor.fromMap(doc.id, doc.data() as Map<String, dynamic>);
  }

  /// Builds a [Doctor] from a plain map, matching the Firestore schema used by
  /// the bundled seed data ([kRealDoctors]).
  factory Doctor.fromMap(String id, Map<String, dynamic> d) {
    return Doctor(
      id: id,
      name: d['name'] ?? '',
      photoUrl: d['photo_url'] ?? '',
      specialization: d['specialization'] ?? '',
      languages: List<String>.from(d['languages'] ?? []),
      bio: d['bio'] ?? '',
      qualifications: List<String>.from(d['qualifications'] ?? []),
      registrationNo: d['registration_no'] ?? '',
      hospital: d['hospital'] ?? '',
      address: d['address'],
      clinicHours: d['clinic_hours'],
      isVerified: d['is_verified'] ?? false,
      isAvailable: d['is_available'] ?? false,
      callType: d['call_type'] ?? 'audio',
    );
  }
}

class Hotline {
  final String id;
  final String name;
  final String? nameSi;
  final String number;
  final String description;
  final String? descriptionSi;
  final List<String> languages;
  final bool isFree;
  final String available;
  final String category;

  const Hotline({
    required this.id,
    required this.name,
    this.nameSi,
    required this.number,
    required this.description,
    this.descriptionSi,
    required this.languages,
    required this.isFree,
    required this.available,
    required this.category,
  });

  String localName(bool isSinhala) =>
      (isSinhala && nameSi != null && nameSi!.isNotEmpty) ? nameSi! : name;

  String localDescription(bool isSinhala) =>
      (isSinhala && descriptionSi != null && descriptionSi!.isNotEmpty)
      ? descriptionSi!
      : description;

  factory Hotline.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Hotline(
      id: doc.id,
      name: d['name'] ?? '',
      nameSi: d['name_si'],
      number: d['number'] ?? '',
      description: d['description'] ?? '',
      descriptionSi: d['description_si'],
      languages: List<String>.from(d['languages'] ?? []),
      isFree: d['is_free'] ?? true,
      available: d['available'] ?? '24/7',
      category: d['category'] ?? 'general',
    );
  }

  static const List<Hotline> fallback = [
    Hotline(
      id: 'nimh',
      name: 'NIMH Mental Health Helpline',
      nameSi: 'NIMH මානසික සෞඛ්‍ය උපකාර මාර්ගය',
      number: '1926',
      description: '24/7 free and confidential mental health support',
      descriptionSi: '24/7 නොමිලේ සහ රහස්‍ය මානසික සෞඛ්‍ය සහාය',
      languages: ['Sinhala', 'English', 'Tamil'],
      isFree: true,
      available: '24/7',
      category: 'mental_health',
    ),
    Hotline(
      id: 'sumithrayo',
      name: 'Sumithrayo',
      nameSi: 'සුමිත්‍රයෝ',
      number: '0112696666',
      description: 'Emotional support and suicide prevention',
      descriptionSi: 'චිත්තවේගීය සහාය සහ සියදිවි නසාගැනීම් වැළැක්වීම',
      languages: ['Sinhala', 'English'],
      isFree: true,
      available: '24/7',
      category: 'suicide',
    ),
    Hotline(
      id: 'emergency',
      name: 'Emergency',
      nameSi: 'හදිසි ඇමතුම',
      number: '119',
      description: 'Police and emergency services',
      descriptionSi: 'පොලිස් සහ හදිසි සේවා',
      languages: ['Sinhala', 'English', 'Tamil'],
      isFree: true,
      available: '24/7',
      category: 'emergency',
    ),
  ];
}
