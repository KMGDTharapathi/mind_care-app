import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mind_care_app/data/models/mood_entry.dart';

class FirestoreMoodRepository {
  FirestoreMoodRepository({
    FirebaseFirestore? firestore,
    required this.uid,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  final String uid;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('users').doc(uid).collection('mood_entries');

  Future<void> save(MoodEntry entry) async {
    try {
      await _collection.doc(entry.id).set({
        'id': entry.id,
        'mood': entry.mood.name,
        'note': entry.note,
        'timestamp': Timestamp.fromDate(entry.timestamp),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<void> delete(String id) async {
    try {
      await _collection.doc(id).delete();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<MoodEntry>> getAll() async {
    try {
      final snapshot = await _collection.get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return MoodEntry(
          id: data['id'] as String,
          mood: MoodType.values.firstWhere((m) => m.name == data['mood']),
          note: data['note'] as String?,
          timestamp: (data['timestamp'] as Timestamp).toDate(),
        );
      }).toList();
    } catch (e) {
      rethrow;
    }
  }
}
