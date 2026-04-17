import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'auth_service.dart';

/// Firebase-backed implementation of [AuthService].
///
/// After every [signOut] call the service immediately starts an anonymous
/// session so [authStateChanges] never emits `null`.
class FirebaseAuthService implements AuthService {
  FirebaseAuthService({
    FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
  })  : _auth = firebaseAuth ?? FirebaseAuth.instance,
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
      return _requireUser(result.user);
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
      return _requireUser(result.user);
    } on FirebaseAuthException catch (e) {
      throw _mapException(e);
    }
  }

  @override
  Future<AuthUser> signInWithGoogle() async {
    try {
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
      return _requireUser(result.user);
    } on FirebaseAuthException catch (e) {
      throw _mapException(e);
    }
  }

  @override
  Future<AuthUser> createAccountWithEmail(
      String email, String password) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return _requireUser(result.user);
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
      'invalid-credential' =>
        AuthErrorType.wrongPassword,
      'email-already-in-use' => AuthErrorType.emailInUse,
      'network-request-failed' => AuthErrorType.networkError,
      _ => AuthErrorType.unknown,
    };
    return AuthException(type, e.message ?? e.code);
  }
}
