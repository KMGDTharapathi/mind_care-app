import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../local/hive_service.dart';
import '../../local/preferences_service.dart';
import '../../models/mood_entry.dart';
import '../mood_repository.dart';

class FirestoreMoodRepository implements MoodRepository {
  FirestoreMoodRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  Future<String> _resolveUid() async {
    final authUid = _auth.currentUser?.uid;
    if (authUid != null && authUid.isNotEmpty) return authUid;
    try {
      final localId = await PreferencesService.getUserId();
      if (localId != null && localId.isNotEmpty) return localId;
    } catch (_) {}
    return 'anonymous';
  }

  Future<CollectionReference<Map<String, dynamic>>> _getCollection() async {
    final uid = await _resolveUid();
    return _firestore.collection('users').doc(uid).collection('moods');
  }

  MoodType _parseMood(Map<String, dynamic> data, int level) {
    final moodStr = data['mood'] as String?;
    if (moodStr != null) {
      for (final m in MoodType.values) {
        if (m.name == moodStr) return m;
      }
    }
    return MoodEntry.mapLevelToMoodType(level);
  }

  @override
  Future<void> saveMoodEntry(MoodEntry entry) async {
    // 1. Always save locally in Hive first so Mood History works immediately
    try {
      await HiveService.moodEntries.put(entry.id, entry);
    } catch (_) {}

    // 2. Also sync to Firestore (best-effort)
    try {
      final col = await _getCollection();
      await col.doc(entry.id).set({
        'id': entry.id,
        'mood': entry.mood.name,
        'level': entry.level,
        'note': entry.note,
        'timestamp': Timestamp.fromDate(entry.timestamp),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Ignore Firestore errors when offline or unauthenticated; Hive has the entry
    }
  }

  @override
  Future<List<MoodEntry>> getLast7Days() async {
    final now = DateTime.now();
    final cutoff = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(days: 6));

    final byId = <String, MoodEntry>{};

    // 1. Load local Hive mood entries (logged from MoodCheckinScreen or MoodTrackerScreen)
    try {
      for (final e in HiveService.moodEntries.values) {
        if (!e.timestamp.isBefore(cutoff)) {
          byId[e.id] = e;
        }
      }
    } catch (_) {}

    // 2. Merge remote Firestore mood entries if available
    try {
      final col = await _getCollection();
      final snapshot = await col
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get()
          .timeout(const Duration(seconds: 4));

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final ts = data['timestamp'];
        if (ts is! Timestamp) continue;
        final date = ts.toDate();
        if (date.isBefore(cutoff)) continue;

        final level = data['level'] as int? ?? 5;
        final id = (data['id'] as String?) ?? doc.id;
        final entry = MoodEntry(
          id: id,
          mood: _parseMood(data, level),
          levelValue: level,
          note: data['note'] as String?,
          timestamp: date,
        );
        byId.putIfAbsent(id, () => entry);
      }
    } catch (_) {
      // Use local Hive entries when offline or unauthenticated
    }

    final result = byId.values.toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return result;
  }

  @override
  Future<MoodEntry?> getTodayEntry() async {
    final today = DateTime.now();
    final startOfToday = DateTime(today.year, today.month, today.day);
    MoodEntry? latest;

    try {
      for (final entry in HiveService.moodEntries.values) {
        if (!entry.timestamp.isBefore(startOfToday)) {
          if (latest == null || entry.timestamp.isAfter(latest.timestamp)) {
            latest = entry;
          }
        }
      }
    } catch (_) {}

    try {
      final col = await _getCollection();
      final snapshot = await col
          .where(
            'timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfToday),
          )
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get()
          .timeout(const Duration(seconds: 3));

      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data();
        final level = data['level'] as int? ?? 5;
        final remoteEntry = MoodEntry(
          id: (data['id'] as String?) ?? snapshot.docs.first.id,
          mood: _parseMood(data, level),
          levelValue: level,
          note: data['note'] as String?,
          timestamp: (data['timestamp'] as Timestamp).toDate(),
        );
        if (latest == null || remoteEntry.timestamp.isAfter(latest.timestamp)) {
          latest = remoteEntry;
        }
      }
    } catch (_) {}

    return latest;
  }
}
