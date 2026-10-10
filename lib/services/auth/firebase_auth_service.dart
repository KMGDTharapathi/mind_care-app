import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'auth_service.dart';

/// Firebase-backed implementation of [AuthService].
///
/// After every [signOut] call the service immediately starts an anonymous
/// session so [authStateChanges] never emits `null`.
class FirebaseAuthService implements AuthService {
  FirebaseAuthService({FirebaseAuth? firebaseAuth, GoogleSignIn? googleSignIn})
    : _auth = firebaseAuth ?? FirebaseAuth.instance,
      _googleSignIn = googleSignIn ?? GoogleSignIn();

  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  // ---------------------------------------------------------------------------
  // AuthService interface
  // ---------------------------------------------------------------------------

  @override
  Stream<AuthUser?> get authStateChanges =>
      _auth.authStateChanges().map(_mapUser);

  @override
  AuthUser? get currentUser => _mapUser(_auth.currentUser);

  @override
  Future<AuthUser> signInAnonymously() async {
    try {
      final result = await _auth.signInAnonymously();
      final user = result.user;
      if (user != null) {
        unawaited(_recordUserLoginInFirestore(user, method: 'anonymous'));
      }
      return _requireUser(user);
    } on FirebaseAuthException catch (e) {
      throw _mapException(e);
    }
  }

  @override
  Future<AuthUser> signInWithEmail(String email, String password) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = result.user;
      if (user != null) {
        unawaited(_recordUserLoginInFirestore(user, method: 'email'));
      }
      return _requireUser(user);
    } on FirebaseAuthException catch (e) {
      throw _mapException(e);
    }
  }

  @override
  Future<AuthUser> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope('profile');
        try {
          final result = await _auth.signInWithPopup(googleProvider);
          final user = result.user;
          if (user != null) {
            unawaited(_recordUserLoginInFirestore(user, method: 'google'));
          }
          return _requireUser(user);
        } on FirebaseAuthException catch (e) {
          if (e.code == 'popup-closed-by-user' || e.code == 'cancelled') {
            final current = _auth.currentUser;
            if (current != null) return _mapUser(current)!;
            return signInAnonymously();
          }
          throw _mapException(e);
        }
      }

      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // User cancelled — return current user (anonymous) without error.
        final current = _auth.currentUser;
        if (current != null) return _mapUser(current)!;
        return signInAnonymously();
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final result = await _auth.signInWithCredential(credential);
      final user = result.user;
      if (user != null) {
        unawaited(_recordUserLoginInFirestore(user, method: 'google'));
      }
      return _requireUser(user);
    } on FirebaseAuthException catch (e) {
      throw _mapException(e);
    }
  }

  @override
  Future<AuthUser> createAccountWithEmail(String email, String password) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = result.user;
      if (user != null) {
        unawaited(_recordUserLoginInFirestore(user, method: 'email_signup'));
      }
      return _requireUser(user);
    } on FirebaseAuthException catch (e) {
      throw _mapException(e);
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _mapException(e);
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {
      // Google sign-out is best-effort; ignore errors.
    }
    await _auth.signOut();
    // Immediately restore an anonymous session so the stream never emits null.
    await signInAnonymously();
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Maps a nullable Firebase [User] to a nullable [AuthUser].
  AuthUser? _mapUser(User? user) {
    if (user == null) return null;
    return AuthUser(
      uid: user.uid,
      email: user.email,
      isAnonymous: user.isAnonymous,
    );
  }

  /// Unwraps a non-null [User], throwing if it is unexpectedly null.
  AuthUser _requireUser(User? user) {
    if (user == null) {
      throw const AuthException(
        AuthErrorType.unknown,
        'Firebase returned a null user after a successful operation.',
      );
    }
    return _mapUser(user)!;
  }

  /// Maps a [FirebaseAuthException] error code to a typed [AuthException].
  AuthException _mapException(FirebaseAuthException e) {
    final type = switch (e.code) {
      'invalid-email' => AuthErrorType.invalidEmail,
      'wrong-password' ||
      'user-not-found' ||
      'invalid-credential' => AuthErrorType.wrongPassword,
      'email-already-in-use' => AuthErrorType.emailInUse,
      'network-request-failed' => AuthErrorType.networkError,
      _ => AuthErrorType.unknown,
    };
    return AuthException(type, e.message ?? e.code);
  }

  /// Updates login timestamp and logs every login session into Firestore.
  Future<void> _recordUserLoginInFirestore(
    User? user, {
    required String method,
  }) async {
    if (user == null) return;
    try {
      final docRef =
          FirebaseFirestore.instance.collection('users').doc(user.uid);

      final docSnap = await docRef.get();

      final updateData = <String, dynamic>{
        'uid': user.uid,
        'email': user.email ?? (user.isAnonymous ? 'anonymous' : ''),
        'displayName': user.displayName ?? '',
        'photoUrl': user.photoURL ?? '',
        'isAnonymous': user.isAnonymous,
        'lastLoginAt': FieldValue.serverTimestamp(),
        'lastLoginMethod': method,
        'loginCount': FieldValue.increment(1),
        'isOnline': true,
      };

      // Record initial createdAt if not present
      if (!docSnap.exists || !(docSnap.data()?.containsKey('createdAt') ?? false)) {
        updateData['createdAt'] = FieldValue.serverTimestamp();
      }

      await docRef.set(updateData, SetOptions(merge: true));

      // Append detailed entry to users/{uid}/logins subcollection
      await docRef.collection('logins').add({
        'timestamp': FieldValue.serverTimestamp(),
        'method': method,
        'email': user.email ?? (user.isAnonymous ? 'anonymous' : ''),
        'displayName': user.displayName ?? '',
      });
    } catch (e) {
      debugPrint('FirebaseAuthService: Failed to record login in Firestore: $e');
    }
  }
}
