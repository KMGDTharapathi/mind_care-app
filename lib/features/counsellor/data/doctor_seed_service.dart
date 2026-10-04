import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'doctor_seed_data.dart';

class DoctorSeedService {
  // Bump this version whenever seed data changes â€” triggers a re-seed
  static const int _seedVersion = 4;
  static const String _versionDoc = '__seed_meta__';

  static Future<void> seedIfEmpty() async {
    try {
      final col = FirebaseFirestore.instance.collection('doctors');

      // Check current seed version
      final meta = await col.doc(_versionDoc).get();
      final currentVersion = meta.exists
          ? (meta.data()?['version'] as int? ?? 0)
          : 0;

      if (currentVersion >= _seedVersion) return; // already up to date

      // Delete all existing doctor docs (not the meta doc)
      final existing = await col.get();
      final deleteBatch = FirebaseFirestore.instance.batch();
      for (final doc in existing.docs) {
        if (doc.id != _versionDoc) {
          deleteBatch.delete(doc.reference);
        }
      }
      await deleteBatch.commit();

      // Re-seed with new data in a fresh batch
      final seedBatch = FirebaseFirestore.instance.batch();
      for (final doctor in kRealDoctors) {
        final ref = col.doc();
        seedBatch.set(ref, {
          ...doctor,
          'created_at': FieldValue.serverTimestamp(),
        });
      }

      // Update version
      seedBatch.set(col.doc(_versionDoc), {
        'version': _seedVersion,
        'updated_at': FieldValue.serverTimestamp(),
      });

      await seedBatch.commit();
      debugPrint('DoctorSeedService: seeded v$_seedVersion â€” ${kRealDoctors.length} doctors');
    } catch (e) {
      debugPrint('DoctorSeedService: seed failed â€” $e');
    }
  }
}
