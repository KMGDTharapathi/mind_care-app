import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/wellness_session_model.dart';

/// Repository for saving and streaming completed wellness sessions (Meditation, Breathing, etc.)
class FirestoreSessionRepository {
  FirestoreSessionRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String get _currentUid => _auth.currentUser?.uid ?? 'anonymous';

  CollectionReference<Map<String, dynamic>> _userSessionsCol(String userId) =>
      _firestore.collection('users').doc(userId).collection('wellness_sessions');

  DocumentReference<Map<String, dynamic>> _userDoc(String userId) =>
      _firestore.collection('users').doc(userId);

  /// Logs a completed wellness session and updates user aggregate statistics in Firestore.
  Future<void> logSession(WellnessSessionModel session) async {
    final uid = session.userId.isNotEmpty ? session.userId : _currentUid;
    final docRef = _userSessionsCol(uid).doc();
    final id = session.id.isNotEmpty ? session.id : docRef.id;

    final sessionData = WellnessSessionModel(
      id: id,
      userId: uid,
      type: session.type,
      title: session.title,
      durationSeconds: session.durationSeconds,
      completedAt: session.completedAt,
      metadata: session.metadata,
    ).toMap();

    // 1. Save session record
    await _userSessionsCol(uid).doc(id).set(sessionData);

    // 2. Increment user aggregate statistics
    final minutes = (session.durationSeconds / 60).ceil();
    try {
      await _userDoc(uid).set({
        'totalSessionsCompleted': FieldValue.increment(1),
        'totalMindfulMinutes': FieldValue.increment(minutes),
        'lastSessionAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {
      // Best-effort stats aggregation
    }
  }

  /// Streams user's completed wellness sessions in real-time.
  Stream<List<WellnessSessionModel>> streamUserSessions(String userId, {int limit = 30}) {
    return _userSessionsCol(userId)
        .orderBy('completedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => WellnessSessionModel.fromMap(doc.data(), doc.id))
            .toList());
  }
}
