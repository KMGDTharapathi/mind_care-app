import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/mood_entry.dart';
import '../mood_repository.dart';

/// Firestore-backed [MoodRepository] scoped to the signed-in user.
///
/// Collection and field names match the ones [FirestoreSyncService] uses, so
/// the direct repository and the Hive<->Firestore sync listeners agree on a
/// single schema instead of writing two incompatible copies.
///
/// Every method degrades gracefully when the user is signed out or offline:
/// reads return empty/null and writes are skipped rather than throwing, so the
/// mood flow keeps working on the local-only path. Use
/// `FirestoreSyncService.enqueueMoodEntry` when you want writes queued for
/// later delivery instead of dropped.
class FirestoreMoodRepository implements MoodRepository {
  FirestoreMoodRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  /// Null while signed out. Never fall back to a placeholder id: the security
  /// rules scope every document to `request.auth.uid`, so a synthetic path
  /// would just fail with permission-denied.
  String? get _uid => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>>? get _collection {
    final uid = _uid;
    if (uid == null) return null;
    return _firestore.collection('users').doc(uid).collection('mood_entries');
  }

  @override
  Future<void> saveMoodEntry(MoodEntry entry) async {
    final collection = _collection;
    if (collection == null) return;
    try {
      await collection.doc(entry.id).set({
        'id': entry.id,
        'mood': entry.mood.name,
        'level': entry.level,
        if (entry.note != null) 'note': entry.note,
        'timestamp': Timestamp.fromDate(entry.timestamp),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Swallow: the caller has already persisted to Hive, and an offline or
      // permission error must not break the mood check-in.
    }
  }

  @override
  Future<List<MoodEntry>> getLast7Days() async {
    final collection = _collection;
    if (collection == null) return const [];
    try {
      final snapshot = await collection
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();
      // Returned chronologically, oldest first, to match HiveMoodRepository.
      return snapshot.docs
          .map(_toEntry)
          .whereType<MoodEntry>()
          .toList()
          .reversed
          .toList();
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<MoodEntry?> getTodayEntry() async {
    final collection = _collection;
    if (collection == null) return null;
    try {
      final today = DateTime.now();
      final startOfToday = DateTime(today.year, today.month, today.day);
      final snapshot = await collection
          .where('timestamp',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfToday))
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;
      return _toEntry(snapshot.docs.first);
    } catch (_) {
      return null;
    }
  }

  /// Maps a Firestore document back to a [MoodEntry], or null if malformed.
  ///
  /// Prefers the `mood` name written by the sync service and falls back to the
  /// numeric `level` so documents written by older clients still load.
  MoodEntry? _toEntry(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) return null;
    final timestamp = data['timestamp'];
    if (timestamp is! Timestamp) return null;

    final moodName = data['mood'] as String?;
    final level = data['level'] as int?;
    final mood = moodName != null
        ? MoodType.values.firstWhere(
            (m) => m.name == moodName,
            orElse: () => MoodEntry.mapLevelToMoodType(level ?? 5),
          )
        : MoodEntry.mapLevelToMoodType(level ?? 5);

    return MoodEntry(
      id: data['id'] as String? ?? doc.id,
      mood: mood,
      levelValue: level,
      note: data['note'] as String?,
      timestamp: timestamp.toDate(),
    );
  }
}
