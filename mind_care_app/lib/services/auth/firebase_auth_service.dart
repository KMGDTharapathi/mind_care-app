import 'dart:async';

import 'auth_service.dart';

/// No-op implementation when running without Firebase.
/// Provides a local-only auth experience.
class FirebaseAuthService implements AuthService {
  final _controller = StreamController<AuthUser>.broadcast();
  
  FirebaseAuthService() {
    // Emit an anonymous user immediately to satisfy the interface contract
    _controller.add(AuthUser(
      uid: 'anonymous',
      email: null,
      isAnonymous: true,
    ));
  }

  @override
  Stream<AuthUser?> get authStateChanges => _controller.stream;

  @override
  AuthUser? get currentUser => AuthUser(
    uid: 'anonymous',
    email: null,
    isAnonymous: true,
  );

  @override
  Future<AuthUser> signInAnonymously() async {
    return currentUser!;
  }

  @override
  Future<AuthUser> signInWithEmail(String email, String password) async {
    // For local mode, just return the anonymous user
    // In a real implementation, this would validate credentials locally
    return currentUser!;
  }

  @override
  Future<AuthUser> signInWithGoogle() async {
    // Not available without Firebase
    return currentUser!;
  }

  @override
  Future<AuthUser> createAccountWithEmail(String email, String password) async {
    // Not available without Firebase
    return currentUser!;
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    // Not available without Firebase
  }

  @override
  Future<void> signOut() async {
    // Just emit the anonymous user again
    _controller.add(currentUser!);
  }
}