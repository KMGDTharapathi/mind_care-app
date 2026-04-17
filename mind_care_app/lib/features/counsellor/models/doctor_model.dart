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
  final bool isVerified;
  final bool isAvailable;
  final double rating;
  final int totalReviews;
  final int sessionFeeLkr;
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
    required this.isVerified,
    required this.isAvailable,
    required this.rating,
    required this.totalReviews,
    required this.sessionFeeLkr,
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
      isVerified: d['is_verified'] ?? false,
      isAvailable: d['is_available'] ?? false,
      rating: (d['rating'] ?? 0.0).toDouble(),
      totalReviews: d['total_reviews'] ?? 0,
      sessionFeeLkr: d['session_fee_lkr'] ?? 0,
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
      isVerified: true,
      isAvailable: true,
      rating: 4.8,
      totalReviews: 124,
      sessionFeeLkr: 1500,
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
      isVerified: true,
      isAvailable: true,
      rating: 4.6,
      totalReviews: 89,
      sessionFeeLkr: 0,
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
      isVerified: true,
      isAvailable: false,
      rating: 4.9,
      totalReviews: 210,
      sessionFeeLkr: 2500,
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
      isVerified: true,
      isAvailable: true,
      rating: 4.5,
      totalReviews: 56,
      sessionFeeLkr: 800,
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
      isVerified: true,
      isAvailable: true,
      rating: 4.7,
      totalReviews: 143,
      sessionFeeLkr: 1200,
      callType: 'audio',
    ),
  ];
}

class Hotline {
  final String id;
  final String name;
  final String number;
  final String description;
  final List<String> languages;
  final bool isFree;
  final String available;
  final String category;

  const Hotline({
    required this.id,
    required this.name,
    required this.number,
    required this.description,
    required this.languages,
    required this.isFree,
    required this.available,
    required this.category,
  });

  factory Hotline.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Hotline(
      id: doc.id,
      name: d['name'] ?? '',
      number: d['number'] ?? '',
      description: d['description'] ?? '',
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
      number: '1926',
      description: '24/7 free and confidential mental health support',
      languages: ['Sinhala', 'English', 'Tamil'],
      isFree: true,
      available: '24/7',
      category: 'mental_health',
    ),
    Hotline(
      id: 'sumithrayo',
      name: 'Sumithrayo',
      number: '0112696666',
      description: 'Emotional support and suicide prevention',
      languages: ['Sinhala', 'English'],
      isFree: true,
      available: '24/7',
      category: 'suicide',
    ),
    Hotline(
      id: 'emergency',
      name: 'Emergency',
      number: '119',
      description: 'Police and emergency services',
      languages: ['Sinhala', 'English', 'Tamil'],
      isFree: true,
      available: '24/7',
      category: 'emergency',
    ),
  ];
}
