import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreResourceRepository {
  FirestoreResourceRepository({
    FirebaseFirestore? firestore,
    required this.uid,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  final String uid;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('users').doc(uid).collection('bookmarks');

  Future<void> save(String resourceId, {required bool bookmarked}) async {
    try {
      await _collection.doc(resourceId).set({
        'bookmarked': bookmarked,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<void> delete(String resourceId) async {
    try {
      await _collection.doc(resourceId).delete();
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, bool>> getAll() async {
    try {
      final snapshot = await _collection.get();
      return {
        for (final doc in snapshot.docs)
          doc.id: (doc.data()['bookmarked'] as bool? ?? false),
      };
    } catch (e) {
      rethrow;
    }
  }
}
