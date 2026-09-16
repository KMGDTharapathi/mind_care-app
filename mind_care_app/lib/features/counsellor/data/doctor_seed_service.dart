import 'package:flutter/foundation.dart';
import 'doctor_seed_data.dart';

class DoctorSeedService {
  // Bump this version whenever seed data changes — triggers a re-seed
  static const int _seedVersion = 4;

  static Future<void> seedIfEmpty() async {
    // No-op when Firebase is not configured
    // Seed data is already available locally via kRealDoctors
    debugPrint('DoctorSeedService: using local seed data — ${kRealDoctors.length} doctors');
  }
}