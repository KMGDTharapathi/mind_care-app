/// Domain model representing an authenticated (or anonymous) Firebase user.
class AuthUser {
  const AuthUser({
    required this.uid,
    this.email,
    required this.isAnonymous,
  });

  final String uid;
  final String? email;
  final bool isAnonymous;
}

/// Typed error categories surfaced by [AuthService] implementations.
enum AuthErrorType {
  invalidEmail,
  wrongPassword,
  emailInUse,
  networkError,
  unknown,
}

/// Typed exception thrown by [AuthService] implementations on failure.
class AuthException implements Exception {
  const AuthException(this.type, this.message);

  final AuthErrorType type;
  final String message;

  @override
  String toString() => 'AuthException(${type.name}): $message';
}

/// Abstract interface for Firebase Authentication operations.
///
/// The stream [authStateChanges] must never emit `null`; after sign-out the
/// implementation is expected to immediately start an anonymous session so the
/// stream always carries a valid [AuthUser].
abstract class AuthService {
  /// Emits the current user whenever the auth state changes.
  /// Never emits `null` — anonymous sessions are used as the fallback.
  Stream<AuthUser?> get authStateChanges;

  /// Returns the currently signed-in user, or `null` if not yet initialised.
  AuthUser? get currentUser;

  /// Signs in anonymously and returns the resulting [AuthUser].
  Future<AuthUser> signInAnonymously();

  /// Signs in with [email] and [password].
  ///
  /// Throws [AuthException] with an appropriate [AuthErrorType] on failure.
  Future<AuthUser> signInWithEmail(String email, String password);

  /// Signs in via Google Sign-In.
  ///
  /// Throws [AuthException] on failure. Returns silently if the user cancels.
  Future<AuthUser> signInWithGoogle();

  /// Creates a new email/password account.
  ///
  /// Throws [AuthException] with [AuthErrorType.emailInUse] if the address is
  /// already registered.
  Future<AuthUser> createAccountWithEmail(String email, String password);

  /// Sends a password-reset email to [email].
  ///
  /// Throws [AuthException] with [AuthErrorType.invalidEmail] for a malformed
  /// address.
  Future<void> sendPasswordResetEmail(String email);

  /// Signs out the current user and immediately starts an anonymous session so
  /// [authStateChanges] never emits `null`.
  Future<void> signOut();
}
