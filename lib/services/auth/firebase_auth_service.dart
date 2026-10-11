import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:mind_care_app/data/local/preferences_service.dart';
import 'package:mind_care_app/data/repositories/firestore/firestore_user_repository.dart';
import 'package:mind_care_app/main.dart' show appUserName;
import 'package:url_launcher/url_launcher.dart';

import 'auth_service.dart';

/// Firebase-backed implementation of [AuthService].
///
/// After every [signOut] call the service immediately starts an anonymous
/// session so [authStateChanges] never emits `null`.
class FirebaseAuthService implements AuthService {
  FirebaseAuthService({
    FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
    FirestoreUserRepository? userRepo,
  })  : _auth = firebaseAuth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ??
            (kIsWeb
                ? null
                : GoogleSignIn(
                    serverClientId:
                        '384910835517-ge9peqbi87so7e63nf2jofnueh98g424.apps.googleusercontent.com',
                  )),
        _userRepo = userRepo ?? FirestoreUserRepository();

  final FirebaseAuth _auth;
  final GoogleSignIn? _googleSignIn;
  final FirestoreUserRepository _userRepo;

  static const String _nativeOAuthClientId =
      '384910835517-8inlm7mueqpbtv6v53isj8tltcb3r7hh.apps.googleusercontent.com';
  static const String _nativeOAuthRedirectUri =
      'com.googleusercontent.apps.384910835517-8inlm7mueqpbtv6v53isj8tltcb3r7hh:/oauth2redirect';
  static const MethodChannel _oauthChannel =
      MethodChannel('com.mindcare.app/oauth');

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
      final user = _requireUser(result.user);
      unawaited(_userRepo.syncUser(
        uid: user.uid,
        email: 'anonymous',
        displayName: 'Anonymous User',
      ));
      return user;
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
      final user = _requireUser(result.user);
      final displayName = result.user?.displayName;
      if (displayName != null && displayName.trim().isNotEmpty) {
        unawaited(PreferencesService.setUserName(displayName.trim()));
        appUserName.value = displayName.trim();
      }
      unawaited(_userRepo.syncUser(
        uid: user.uid,
        email: user.email ?? email,
        displayName: displayName,
        photoUrl: result.user?.photoURL,
      ));
      return user;
    } on FirebaseAuthException catch (e) {
      throw _mapException(e);
    }
  }

  @override
  Future<AuthUser> signInWithGoogle() async {
    try {
      UserCredential result;
      if (kIsWeb) {
        final googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope('profile');
        googleProvider.setCustomParameters({'prompt': 'select_account'});
        try {
          result = await _auth.signInWithPopup(googleProvider);
        } on FirebaseAuthException catch (e) {
          if (e.code == 'popup-closed-by-user' ||
              e.code == 'cancelled-popup-request' ||
              e.code == 'cancelled') {
            throw const AuthException(
              AuthErrorType.unknown,
              'Google sign-in was cancelled.',
            );
          }
          rethrow;
        }
      } else {
        try {
          final googleUser = await _googleSignIn?.signIn();
          if (googleUser == null) {
            throw const AuthException(
              AuthErrorType.unknown,
              'Google sign-in was cancelled.',
            );
          }

          final googleAuth = await googleUser.authentication;
          final credential = GoogleAuthProvider.credential(
            accessToken: googleAuth.accessToken,
            idToken: googleAuth.idToken,
          );

          result = await _auth.signInWithCredential(credential);
        } on AuthException {
          rethrow;
        } catch (_) {
          // Fallback to browser OAuth 2.0 flow — works on any Android phone/PC
          // even when the developer's debug.keystore SHA-1 is not registered
          // in Firebase Console (ApiException: 10).
          result = await _signInWithBrowserOAuth();
        }
      }

      final user = _requireUser(result.user);
      final displayName = result.user?.displayName;
      if (displayName != null && displayName.trim().isNotEmpty) {
        unawaited(PreferencesService.setUserName(displayName.trim()));
        appUserName.value = displayName.trim();
      }
      unawaited(_userRepo.syncUser(
        uid: user.uid,
        email: user.email ?? result.user?.email ?? '',
        displayName: displayName,
        photoUrl: result.user?.photoURL,
      ));
      return user;
    } on AuthException {
      rethrow;
    } on FirebaseAuthException catch (e) {
      throw _mapException(e);
    } catch (e) {
      throw AuthException(AuthErrorType.unknown, e.toString());
    }
  }

  /// Launches Google OAuth 2.0 in the system browser using the public native
  /// OAuth client (which does not check Android SHA-1) and exchanges the
  /// authorization code for Firebase credentials.
  Future<UserCredential> _signInWithBrowserOAuth() async {
    final completer = Completer<String>();

    void completeWithUri(String? uriString) {
      if (uriString != null &&
          uriString.isNotEmpty &&
          !completer.isCompleted) {
        completer.complete(uriString);
      }
    }

    _oauthChannel.setMethodCallHandler((call) async {
      if (call.method == 'onOAuthRedirect') {
        completeWithUri(call.arguments as String?);
      }
    });

    final lifecycleObserver = _OAuthLifecycleObserver(
      onResumed: () async {
        try {
          final pending = await _oauthChannel
              .invokeMethod<String>('getPendingOAuthRedirect');
          if (pending != null && pending.isNotEmpty) {
            completeWithUri(pending);
          } else {
            // Give onNewIntent a brief moment to arrive; if user returned
            // without completing sign-in, cancel cleanly.
            await Future<void>.delayed(const Duration(milliseconds: 1200));
            final retry = await _oauthChannel
                .invokeMethod<String>('getPendingOAuthRedirect');
            if (retry != null && retry.isNotEmpty) {
              completeWithUri(retry);
            } else if (!completer.isCompleted) {
              completer.completeError(
                const AuthException(
                  AuthErrorType.unknown,
                  'Google sign-in was cancelled.',
                ),
              );
            }
          }
        } catch (_) {}
      },
    );
    WidgetsBinding.instance.addObserver(lifecycleObserver);

    try {
      final authUrl = Uri.https('accounts.google.com', '/o/oauth2/v2/auth', {
        'client_id': _nativeOAuthClientId,
        'redirect_uri': _nativeOAuthRedirectUri,
        'response_type': 'code',
        'scope': 'openid email profile',
        'prompt': 'select_account',
      });

      final launched = await launchUrl(
        authUrl,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        throw const AuthException(
          AuthErrorType.unknown,
          'Could not open browser for Google sign-in.',
        );
      }

      final redirectUriString =
          await completer.future.timeout(const Duration(minutes: 3));
      final redirectUri = Uri.parse(redirectUriString);
      final error = redirectUri.queryParameters['error'];
      if (error != null) {
        throw AuthException(
          AuthErrorType.unknown,
          'Google sign-in cancelled ($error).',
        );
      }

      final code = redirectUri.queryParameters['code'];
      if (code == null || code.isEmpty) {
        throw const AuthException(
          AuthErrorType.unknown,
          'No authorization code received from Google.',
        );
      }

      final tokenResponse = await http.post(
        Uri.parse('https://oauth2.googleapis.com/token'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'client_id': _nativeOAuthClientId,
          'code': code,
          'grant_type': 'authorization_code',
          'redirect_uri': _nativeOAuthRedirectUri,
        },
      );

      if (tokenResponse.statusCode != 200) {
        throw AuthException(
          AuthErrorType.unknown,
          'Failed to exchange Google auth code: ${tokenResponse.body}',
        );
      }

      final tokenData =
          jsonDecode(tokenResponse.body) as Map<String, dynamic>;
      final idToken = tokenData['id_token'] as String?;
      final accessToken = tokenData['access_token'] as String?;

      final credential = GoogleAuthProvider.credential(
        accessToken: accessToken,
        idToken: idToken,
      );
      return await _auth.signInWithCredential(credential);
    } finally {
      WidgetsBinding.instance.removeObserver(lifecycleObserver);
      _oauthChannel.setMethodCallHandler(null);
    }
  }

  @override
  Future<AuthUser> createAccountWithEmail(
    String email,
    String password, {
    String? displayName,
  }) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (displayName != null && displayName.trim().isNotEmpty) {
        await result.user?.updateDisplayName(displayName.trim());
      }
      final user = _requireUser(result.user);
      unawaited(_userRepo.syncUser(
        uid: user.uid,
        email: email,
        displayName: displayName ?? result.user?.displayName,
        photoUrl: result.user?.photoURL,
      ));
      return user;
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
      if (!kIsWeb) {
        await _googleSignIn?.signOut();
      }
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
      displayName: user.displayName,
      photoUrl: user.photoURL,
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

class _OAuthLifecycleObserver extends WidgetsBindingObserver {
  _OAuthLifecycleObserver({required this.onResumed});

  final VoidCallback onResumed;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      onResumed();
    }
  }
}
