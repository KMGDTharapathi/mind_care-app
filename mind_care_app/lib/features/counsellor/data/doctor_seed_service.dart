import 'package:flutter/foundation.dart';
import 'doctor_seed_data.dart';

class DoctorSeedService {
  static Future<void> seedIfEmpty() async {
    // No-op when Firebase is not configured
    // Seed data is already available locally via kRealDoctors
    debugPrint('DoctorSeedService: using local seed data — ${kRealDoctors.length} doctors');
  }
}