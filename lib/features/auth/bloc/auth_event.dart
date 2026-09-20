part of 'auth_bloc.dart';

abstract class AuthEvent {}

/// Fired on app startup to subscribe to auth state changes.
class AuthStarted extends AuthEvent {}

/// Sign in with email and password.
class AuthSignInWithEmail extends AuthEvent {
  AuthSignInWithEmail({required this.email, required this.password});

  final String email;
  final String password;
}

/// Sign in via Google Sign-In.
class AuthSignInWithGoogle extends AuthEvent {}

/// Sign out the current user (stream will emit the new anonymous state).
class AuthSignOut extends AuthEvent {}

/// Create a new account with email and password.
class AuthCreateAccount extends AuthEvent {
  AuthCreateAccount({required this.email, required this.password});

  final String email;
  final String password;
}

/// Send a password-reset email to the given address.
class AuthSendPasswordReset extends AuthEvent {
  AuthSendPasswordReset({required this.email});

  final String email;
}
