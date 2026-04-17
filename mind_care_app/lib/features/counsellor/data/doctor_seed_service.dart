import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'doctor_seed_data.dart';

class DoctorSeedService {
  static Future<void> seedIfEmpty() async {
    try {
      final col = FirebaseFirestore.instance.collection('doctors');
      final snap = await col.limit(1).get();
      if (snap.docs.isNotEmpty) return; // already seeded

      final batch = FirebaseFirestore.instance.batch();
      for (final doctor in kRealDoctors) {
        final ref = col.doc();
        batch.set(ref, {
          ...doctor,
          'created_at': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
      debugPrint('DoctorSeedService: seeded ${kRealDoctors.length} doctors');
    } catch (e) {
      debugPrint('DoctorSeedService: seed failed — $e');
    }
  }
}
