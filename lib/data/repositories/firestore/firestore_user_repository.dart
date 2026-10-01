import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../models/user_model.dart';

/// Repository for Cloud Firestore `users/{uid}` collection and Firebase Storage avatars.
class FirestoreUserRepository {
  FirestoreUserRepository({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _usersCol =>
      _firestore.collection('users');

  /// Ensures user document exists in Firestore and updates `lastLoginAt`.
  Future<void> syncUser({
    required String uid,
    required String email,
    String? displayName,
    String? photoUrl,
  }) async {
    try {
      final docRef = _usersCol.doc(uid);
      final snap = await docRef.get();
      if (!snap.exists) {
        await docRef.set({
          'uid': uid,
          'email': email,
          'displayName': displayName ?? '',
          'photoUrl': ?photoUrl,
          'role': 'student',
          'language': 'en',
          'createdAt': FieldValue.serverTimestamp(),
          'lastLoginAt': FieldValue.serverTimestamp(),
        });
      } else {
        await docRef.update({
          'lastLoginAt': FieldValue.serverTimestamp(),
          if (displayName != null && displayName.isNotEmpty)
            'displayName': displayName,
          if (photoUrl != null && photoUrl.isNotEmpty) 'photoUrl': photoUrl,
        });
      }
    } catch (e) {
      // Best-effort: failures must not break login flow
    }
  }

  /// Fetches the user profile document once.
  Future<UserModel?> getUser(String uid) async {
    try {
      final snap = await _usersCol.doc(uid).get();
      if (snap.exists && snap.data() != null) {
        return UserModel.fromMap(snap.data()!, uid);
      }
    } catch (_) {}
    return null;
  }

  /// Real-time stream of the user profile document.
  Stream<UserModel?> userStream(String uid) {
    return _usersCol.doc(uid).snapshots().map((snap) {
      if (snap.exists && snap.data() != null) {
        return UserModel.fromMap(snap.data()!, uid);
      }
      return null;
    });
  }

  /// Updates profile metadata (display name, phone, student year, etc.).
  Future<void> updateProfile(
    String uid, {
    String? displayName,
    String? photoUrl,
    String? phone,
    String? studentYear,
  }) async {
    final updates = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (displayName != null) updates['displayName'] = displayName;
    if (photoUrl != null) updates['photoUrl'] = photoUrl;
    if (phone != null) updates['phone'] = phone;
    if (studentYear != null) updates['studentYear'] = studentYear;

    await _usersCol.doc(uid).set(updates, SetOptions(merge: true));

    if (displayName != null) {
      await _auth.currentUser?.updateDisplayName(displayName);
    }
    if (photoUrl != null) {
      await _auth.currentUser?.updatePhotoURL(photoUrl);
    }
  }

  /// Uploads avatar image bytes to Firebase Storage and links the download URL.
  Future<String> uploadProfileImage(String uid, Uint8List imageBytes) async {
    final ref = _storage.ref('users/$uid/profile.jpg');
    final metadata = SettableMetadata(contentType: 'image/jpeg');

    await ref.putData(imageBytes, metadata);
    final downloadUrl = await ref.getDownloadURL();

    await updateProfile(uid, photoUrl: downloadUrl);
    return downloadUrl;
  }
}
