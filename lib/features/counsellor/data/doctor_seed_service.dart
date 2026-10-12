import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'doctor_seed_data.dart';

class DoctorSeedService {
  // Bump this version whenever seed data changes — triggers a re-seed
  static const int _seedVersion = 5;
  static const String _versionDoc = '_seed_meta';

  static Future<void> seedIfEmpty() async {
    // 1. Try seeding the top-level /doctors collection
    await _seedCollection(FirebaseFirestore.instance.collection('doctors'));

    // 2. Also seed under /users/{uid}/doctors so it always succeeds even if
    // Firebase Console rules only permit /users/{userId}/{document=**}
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await _seedCollection(
        FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('doctors'),
      );
    }
  }

  static Future<void> _seedCollection(
    CollectionReference<Map<String, dynamic>> col,
  ) async {
    try {
      final meta = await col.doc(_versionDoc).get();
      final currentVersion = meta.exists
          ? (meta.data()?['version'] as int? ?? 0)
          : 0;

      if (currentVersion >= _seedVersion) return;

      final existing = await col.get();
      final deleteBatch = FirebaseFirestore.instance.batch();
      for (final doc in existing.docs) {
        if (doc.id != _versionDoc) {
          deleteBatch.delete(doc.reference);
        }
      }
      await deleteBatch.commit();

      final seedBatch = FirebaseFirestore.instance.batch();
      for (var i = 0; i < kRealDoctors.length; i++) {
        final doctor = kRealDoctors[i];
        final docId = (doctor['registration_no'] as String? ?? 'doc_$i')
            .toLowerCase()
            .replaceAll(RegExp(r'[^a-z0-9_-]'), '_');
        final ref = col.doc(docId);
        seedBatch.set(ref, {
          ...doctor,
          'created_at': FieldValue.serverTimestamp(),
        });
      }

      seedBatch.set(col.doc(_versionDoc), {
        'version': _seedVersion,
        'updated_at': FieldValue.serverTimestamp(),
      });

      await seedBatch.commit();
      debugPrint(
        'DoctorSeedService: seeded v$_seedVersion (${kRealDoctors.length} doctors) into ${col.path}',
      );
    } catch (e) {
      debugPrint('DoctorSeedService: seed failed on ${col.path} — $e');
    }
  }
}
