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
    final d = doc.data() as Map<String, dynamic>;
    return Doctor(
      id: doc.id,
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

  /// Sample doctors shown when Firestore has no data yet.
  static const List<Doctor> samples = [
    Doctor(
      id: 's1',
      name: 'Dr. Kasun Perera',
      photoUrl: '',
      specialization: 'Clinical Psychologist',
      languages: ['Sinhala', 'English'],
      bio: '10+ years experience in anxiety, depression, and trauma therapy. '
          'Trained at University of Colombo and NIMH.',
      qualifications: [
        'MBBS – University of Colombo',
        'MD Psychiatry – Postgraduate Institute',
      ],
      registrationNo: 'SLMC-12345',
      hospital: 'NIMH Angoda',
      address: 'Mulleriyawa New Town, Angoda, Colombo 10',
      clinicHours: 'Mon–Fri: 8:00 AM – 4:00 PM\nSat: 8:00 AM – 12:00 PM',
      isVerified: true,
      isAvailable: true,
      callType: 'audio',
    ),
    Doctor(
      id: 's2',
      name: 'Dr. Nimesha Fernando',
      photoUrl: '',
      specialization: 'Counsellor',
      languages: ['Sinhala', 'English', 'Tamil'],
      bio: 'Specialist in grief counselling, relationship issues, and stress '
          'management. Fluent in all three national languages.',
      qualifications: [
        'BSc Psychology – University of Kelaniya',
        'MSc Counselling – University of Colombo',
      ],
      registrationNo: 'SLMC-67890',
      hospital: 'Nawaloka Hospital',
      address: '23 Sri Sugathadasa Mawatha, Colombo 2',
      clinicHours: 'Mon–Fri: 8:00 AM – 5:00 PM\nSat: 8:00 AM – 1:00 PM',
      isVerified: true,
      isAvailable: true,
      callType: 'audio',
    ),
    Doctor(
      id: 's3',
      name: 'Dr. Roshan Silva',
      photoUrl: '',
      specialization: 'Psychiatrist',
      languages: ['Sinhala', 'English'],
      bio: 'Consultant Psychiatrist with expertise in mood disorders, OCD, '
          'and PTSD. Available for medication review and therapy.',
      qualifications: [
        'MBBS – University of Sri Jayewardenepura',
        'MRCPsych – Royal College of Psychiatrists, UK',
      ],
      registrationNo: 'SLMC-24680',
      hospital: 'Lanka Hospitals',
      address: '578 Elvitigala Mawatha, Colombo 5',
      clinicHours: 'Mon–Fri: 8:00 AM – 8:00 PM\nSat–Sun: 8:00 AM – 5:00 PM',
      isVerified: true,
      isAvailable: false,
      callType: 'audio',
    ),
    Doctor(
      id: 's4',
      name: 'Dr. Amali Jayawardena',
      photoUrl: '',
      specialization: 'GP',
      languages: ['Sinhala', 'Tamil'],
      bio: 'General Practitioner with a focus on mental wellness and holistic '
          'health. Provides initial assessments and referrals.',
      qualifications: [
        'MBBS – University of Ruhuna',
      ],
      registrationNo: 'SLMC-11223',
      hospital: 'Asiri Medical Hospital',
      address: '181 Kirula Road, Colombo 5',
      clinicHours: 'Mon–Fri: 8:00 AM – 8:00 PM\nSat–Sun: 8:00 AM – 5:00 PM',
      isVerified: true,
      isAvailable: true,
      callType: 'audio',
    ),
    Doctor(
      id: 's5',
      name: 'Dr. Tharaka Bandara',
      photoUrl: '',
      specialization: 'Clinical Psychologist',
      languages: ['Sinhala', 'English'],
      bio: 'Specialises in child and adolescent mental health, ADHD, and '
          'behavioural therapy. Works with families and schools.',
      qualifications: [
        'BSc Psychology – University of Peradeniya',
        'PhD Clinical Psychology – University of Colombo',
      ],
      registrationNo: 'SLMC-33445',
      hospital: 'Lady Ridgeway Hospital',
      address: 'Dr. Denister De Silva Mawatha, Colombo 8',
      clinicHours: 'Mon–Sat: 8:00 AM – 12:00 PM',
      isVerified: true,
      isAvailable: true,
      callType: 'audio',
    ),
  ];
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
