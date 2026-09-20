part of 'auth_bloc.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Initial state before any auth check has been performed.
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// Auth operation in progress (sign-in, sign-up, etc.).
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// A real (non-anonymous) user is signed in.
class AuthAuthenticated extends AuthState {
  const AuthAuthenticated(this.user);

  final AuthUser user;

  @override
  List<Object?> get props => [user.uid, user.email, user.isAnonymous];
}

/// An anonymous session is active (no real account).
class AuthAnonymous extends AuthState {
  const AuthAnonymous(this.user);

  final AuthUser user;

  @override
  List<Object?> get props => [user.uid];
}

/// An auth operation failed.
class AuthError extends AuthState {
  const AuthError({required this.message, required this.type});

  final String message;
  final AuthErrorType type;

  @override
  List<Object?> get props => [message, type];
}
