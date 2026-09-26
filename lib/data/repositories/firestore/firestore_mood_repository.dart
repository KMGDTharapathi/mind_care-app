import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/mood_entry.dart';
import '../mood_repository.dart';

class FirestoreMoodRepository implements MoodRepository {
  FirestoreMoodRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String get _uid => _auth.currentUser?.uid ?? 'anonymous';

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('users').doc(_uid).collection('moods');

  @override
  Future<void> saveMoodEntry(MoodEntry entry) async {
    try {
      await _collection.doc(entry.id).set({
        'id': entry.id,
        'level': entry.level,
        'note': entry.note,
        'timestamp': Timestamp.fromDate(entry.timestamp),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<MoodEntry>> getLast7Days() async {
    try {
      final snapshot = await _collection
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();
      final entries = snapshot.docs.map((doc) {
        final data = doc.data();
        final level = data['level'] as int? ?? 5;
        return MoodEntry(
          id: data['id'] as String,
          mood: MoodEntry.mapLevelToMoodType(level),
          levelValue: level,
          note: data['note'] as String?,
          timestamp: (data['timestamp'] as Timestamp).toDate(),
        );
      }).toList();
      // Return entries sorted chronologically
      return entries.reversed.toList();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<MoodEntry?> getTodayEntry() async {
    try {
      final today = DateTime.now();
      final startOfToday = DateTime(today.year, today.month, today.day);
      final snapshot = await _collection
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfToday))
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;
      final data = snapshot.docs.first.data();
      final level = data['level'] as int? ?? 5;
      return MoodEntry(
        id: data['id'] as String,
        mood: MoodEntry.mapLevelToMoodType(level),
        levelValue: level,
        note: data['note'] as String?,
        timestamp: (data['timestamp'] as Timestamp).toDate(),
      );
    } catch (e) {
      return null;
    }
  }
}
