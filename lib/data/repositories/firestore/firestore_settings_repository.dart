import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreSettingsRepository {
  FirestoreSettingsRepository({
    FirebaseFirestore? firestore,
    required this.uid,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  final String uid;

  DocumentReference<Map<String, dynamic>> get _doc =>
      _firestore.collection('users').doc(uid).collection('settings').doc('preferences');

  Future<void> save(Map<String, dynamic> settings) async {
    try {
      await _doc.set({
        ...settings,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> get() async {
    try {
      final snapshot = await _doc.get();
      return snapshot.exists ? snapshot.data() : null;
    } catch (e) {
      rethrow;
    }
  }
}
