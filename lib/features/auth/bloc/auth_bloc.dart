import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../services/analytics/analytics_service.dart';
import '../../../services/auth/auth_service.dart';
import '../../../services/crashlytics/crashlytics_service.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({
    required AuthService authService,
    AnalyticsService? analyticsService,
    CrashlyticsService? crashlyticsService,
  })  : _authService = authService,
        _analyticsService = analyticsService,
        _crashlyticsService = crashlyticsService,
        super(const AuthInitial()) {
    on<AuthStarted>(_onAuthStarted);
    on<AuthSignInWithEmail>(_onSignInWithEmail);
    on<AuthSignInWithGoogle>(_onSignInWithGoogle);
    on<AuthSignInAnonymously>(_onSignInAnonymously);
    on<AuthSignOut>(_onSignOut);
    on<AuthCreateAccount>(_onCreateAccount);
    on<AuthSendPasswordReset>(_onSendPasswordReset);
  }

  final AuthService _authService;
  final AnalyticsService? _analyticsService;
  final CrashlyticsService? _crashlyticsService;
  StreamSubscription<AuthUser?>? _authSubscription;

  // ---------------------------------------------------------------------------
  // Event handlers
  // ---------------------------------------------------------------------------

  Future<void> _onAuthStarted(
    AuthStarted event,
    Emitter<AuthState> emit,
  ) async {
    await _authSubscription?.cancel();
    await emit.forEach<AuthUser?>(
      _authService.authStateChanges,
      onData: (user) {
        if (user == null) {
          // Should not happen per contract, but guard defensively.
          return const AuthInitial();
        }
        if (user.isAnonymous) {
          _analyticsService?.setUserId(null);
          _crashlyticsService?.setUserId(null);
          return AuthAnonymous(user);
        }
        _analyticsService?.setUserId(user.uid);
        _crashlyticsService?.setUserId(user.uid);
        _analyticsService?.logEvent(
          'sign_in',
          parameters: {'method': 'email'},
        );
        return AuthAuthenticated(user);
      },
    );
  }

  Future<void> _onSignInWithEmail(
    AuthSignInWithEmail event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final user =
          await _authService.signInWithEmail(event.email, event.password);
      await _analyticsService?.setUserId(user.uid);
      await _crashlyticsService?.setUserId(user.uid);
      await _analyticsService?.logEvent(
        'sign_in',
        parameters: {'method': 'email'},
      );
      emit(AuthAuthenticated(user));
    } catch (e) {
      final msg = e is AuthException ? e.message : e.toString();
      final type = e is AuthException ? e.type : AuthErrorType.unknown;
      emit(AuthError(message: msg, type: type));
    }
  }

  Future<void> _onSignInWithGoogle(
    AuthSignInWithGoogle event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final user = await _authService.signInWithGoogle();
      if (!user.isAnonymous) {
        await _analyticsService?.setUserId(user.uid);
        await _crashlyticsService?.setUserId(user.uid);
        await _analyticsService?.logEvent(
          'sign_in',
          parameters: {'method': 'google'},
        );
      } else {
        await _crashlyticsService?.setUserId(null);
      }
      emit(user.isAnonymous ? AuthAnonymous(user) : AuthAuthenticated(user));
    } catch (e) {
      final msg = e is AuthException ? e.message : e.toString();
      final type = e is AuthException ? e.type : AuthErrorType.unknown;
      emit(AuthError(message: msg, type: type));
    }
  }

  Future<void> _onSignInAnonymously(
    AuthSignInAnonymously event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final user = await _authService.signInAnonymously();
      await _analyticsService?.setUserId(null);
      await _crashlyticsService?.setUserId(null);
      emit(AuthAnonymous(user));
    } catch (e) {
      final msg = e is AuthException ? e.message : e.toString();
      final type = e is AuthException ? e.type : AuthErrorType.unknown;
      emit(AuthError(message: msg, type: type));
    }
  }

  Future<void> _onSignOut(
    AuthSignOut event,
    Emitter<AuthState> emit,
  ) async {
    // signOut() immediately restores an anonymous session; the authStateChanges
    // stream (subscribed via AuthStarted) will emit the new anonymous user.
    await _analyticsService?.setUserId(null);
    await _crashlyticsService?.setUserId(null);
    await _authService.signOut();
  }

  Future<void> _onCreateAccount(
    AuthCreateAccount event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final user = await _authService.createAccountWithEmail(
          event.email, event.password);
      await _analyticsService?.setUserId(user.uid);
      await _crashlyticsService?.setUserId(user.uid);
      await _analyticsService?.logEvent(
        'sign_in',
        parameters: {'method': 'email'},
      );
      emit(AuthAuthenticated(user));
    } catch (e) {
      final msg = e is AuthException ? e.message : e.toString();
      final type = e is AuthException ? e.type : AuthErrorType.unknown;
      emit(AuthError(message: msg, type: type));
    }
  }

  Future<void> _onSendPasswordReset(
    AuthSendPasswordReset event,
    Emitter<AuthState> emit,
  ) async {
    try {
      await _authService.sendPasswordResetEmail(event.email);
    } on AuthException catch (e) {
      emit(AuthError(message: e.message, type: e.type));
    }
  }

  // ---------------------------------------------------------------------------

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}
