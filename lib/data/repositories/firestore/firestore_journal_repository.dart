import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mind_care_app/data/models/journal_entry.dart';

class FirestoreJournalRepository {
  FirestoreJournalRepository({
    FirebaseFirestore? firestore,
    required this.uid,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  final String uid;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('users').doc(uid).collection('journal_entries');

  Future<void> save(JournalEntry entry) async {
    try {
      await _collection.doc(entry.id).set({
        'id': entry.id,
        'title': entry.title,
        'body': entry.body,
        'createdAt': Timestamp.fromDate(entry.createdAt),
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

  Future<List<JournalEntry>> getAll() async {
    try {
      final snapshot = await _collection.get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return JournalEntry(
          id: data['id'] as String,
          title: data['title'] as String,
          body: data['body'] as String,
          createdAt: (data['createdAt'] as Timestamp).toDate(),
          updatedAt: (data['updatedAt'] as Timestamp).toDate(),
        );
      }).toList();
    } catch (e) {
      rethrow;
    }
  }
}
