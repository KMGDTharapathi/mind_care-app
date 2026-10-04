import 'dart:async';
import 'dart:ui';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mind_care_app/core/firebase/firebase_initializer.dart';
import 'package:mind_care_app/core/l10n/app_strings.dart';
import 'package:mind_care_app/core/l10n/language_provider.dart';
import 'package:mind_care_app/core/router/app_router.dart';
import 'package:mind_care_app/core/service_locator.dart';
import 'package:mind_care_app/core/theme/app_theme.dart';
import 'package:mind_care_app/core/widgets/app_loading_view.dart';
import 'package:mind_care_app/data/local/hive_service.dart';
import 'package:mind_care_app/data/local/notification_service.dart';
import 'package:mind_care_app/data/local/preferences_service.dart';
import 'package:mind_care_app/features/auth/bloc/auth_bloc.dart';
import 'package:mind_care_app/features/music/services/calm_audio_handler.dart';
import 'package:mind_care_app/features/settings/bloc/settings_cubit.dart';
import 'package:mind_care_app/services/analytics/analytics_service.dart';
import 'package:mind_care_app/services/analytics/firebase_analytics_service.dart';
import 'package:mind_care_app/services/auth/auth_service.dart';
import 'package:mind_care_app/services/auth/firebase_auth_service.dart';
import 'package:mind_care_app/services/consent/consent_service.dart';
import 'package:mind_care_app/services/crashlytics/crashlytics_service.dart';
import 'package:mind_care_app/services/crashlytics/firebase_crashlytics_service.dart';
import 'package:mind_care_app/services/remote_config/remote_config_service.dart';
import 'package:mind_care_app/services/remote_config/firebase_remote_config_service.dart';
import 'package:mind_care_app/services/auth/auth_service.dart' as auth_models;

/// Global navigator key used by [NotificationService] to navigate on tap.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Global language notifier — updated when user selects a language.
final ValueNotifier<AppStrings> appLanguage = ValueNotifier(AppStrings.en);

/// Global user name notifier — updated when user changes their name.
final ValueNotifier<String?> appUserName = ValueNotifier(null);

/// Completes when Hive + Prefs are ready — splash waits on this before navigating.
final Completer<void> hiveReadyCompleter = Completer<void>();

/// Pre-fetched splash navigation data — set by _heavyInit() so the splash
/// screen never needs to make platform channel calls on the main thread.
String? splashSavedName;
String? splashSavedLang;

/// Whether Firebase came up. False means the app runs fully offline with the
/// NoOp service implementations below.
bool _firebaseReady = false;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialise Firebase before the first frame so the real services can be
  // constructed without a null FirebaseApp. Failures are non-fatal: we fall
  // back to the offline NoOp services and the app still starts.
  _firebaseReady = await FirebaseInitializer.init().then(
    (result) {
      if (!result.success) {
        debugPrint('Firebase init failed: ${result.error}');
      }
      return result.success;
    },
    onError: (Object e) {
      debugPrint('Firebase init error: $e');
      return false;
    },
  );

  // Start the app immediately — router shows /splash at once.
  runApp(
    MindCareApp(
      initFuture: Future.value(const _InitResult(onboardingComplete: false)),
    ),
  );

  // Defer heavy init until after the first frame is painted.
  // Using a microtask + Future.delayed ensures the engine has actually
  // rendered before we touch any platform channels (Hive, SharedPreferences).
  WidgetsBinding.instance.addPostFrameCallback((_) {
    Future.delayed(const Duration(milliseconds: 100), () {
      _heavyInit().catchError((e) {
        debugPrint('_heavyInit error: $e');
        return _InitResult(onboardingComplete: false);
      });
    });
  });
}

/// All heavy init — called after first frame is painted.
Future<_InitResult> _heavyInit() async {
  // Yield immediately so the first frame renders before any heavy work
  await Future.delayed(const Duration(milliseconds: 50));

  final consentService = ConsentService();
  // Only report to Crashlytics once Firebase is up; before that the channel
  // would throw on every error.
  final crashlyticsService = _firebaseReady
      ? FirebaseCrashlyticsService(consentService: consentService)
      : NoOpCrashlyticsService();

  FlutterError.onError = (details) {
    if (_firebaseReady) {
      unawaited(
        crashlyticsService.recordError(
          details.exception,
          details.stack,
          fatal: true,
        ),
      );
    }
    FlutterError.presentError(details);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    if (_firebaseReady) {
      unawaited(crashlyticsService.recordError(error, stack, fatal: true));
    }
    return true;
  };

  final remoteConfig = _firebaseReady
      ? FirebaseRemoteConfigService(crashlyticsService: crashlyticsService)
      : NoOpRemoteConfigService();

  // Warm up SharedPreferences cache FIRST — single platform channel call that
  // all subsequent reads (PreferencesService, ConsentService, etc.) will reuse
  // as synchronous cache hits, preventing concurrent getInstance() calls that
  // can block the main isolate.
  // Guarded: a transient channel error here must not abort the rest of init.
  try {
    await PreferencesService.warmUp().timeout(const Duration(seconds: 3));
  } catch (e) {
    debugPrint('Prefs warmup failed: $e');
  }

  // Hive and Preferences run in parallel — both are needed before we can
  // determine onboardingComplete.
  // Yield to the event loop first so the UI stays responsive.
  await Future.delayed(Duration.zero);
  final prefsResult = await Future.wait<dynamic>([
    HiveService.init().timeout(const Duration(seconds: 4)).catchError((e) {
      debugPrint('Hive failed: $e');
    }),
    PreferencesService.isOnboardingComplete()
        .timeout(const Duration(seconds: 3))
        .catchError((e) {
          debugPrint('Prefs failed: $e');
          return false;
        }),
  ]);

  // Pre-fetch name + language while still in _heavyInit so the splash screen
  // can read them from globals (zero platform calls on the main thread).
  // Guarded — if prefs are hard-down, splash falls back to onboarding defaults.
  final navResults = await Future.wait<String?>([
    PreferencesService.getUserName()
        .timeout(const Duration(seconds: 3))
        .catchError((_) => null),
    PreferencesService.getAppLanguage()
        .timeout(const Duration(seconds: 3))
        .catchError((_) => null),
  ]);
  splashSavedName = navResults[0];
  splashSavedLang = navResults[1];

  // Restore saved language into the global notifier immediately so all
  // screens reflect the correct language from the very first frame.
  if (splashSavedLang == 'si') {
    appLanguage.value = AppStrings.si;
  }

  // Signal splash screen that Hive + nav data are ready — safe to navigate now.
  // ServiceLocator is initialised first so every route builder and bloc below
  // reads the real (or gracefully no-op) services instead of null references.
  try {
    await ServiceLocator.init(
      auth: _firebaseReady ? FirebaseAuthService() : NoOpAuthService(),
      remoteConfig: remoteConfig,
      analytics: _firebaseReady
          ? FirebaseAnalyticsService(consentService: consentService)
          : NoOpAnalyticsService(consentService: consentService),
      crashlytics: crashlyticsService,
    ).timeout(const Duration(seconds: 5));
  } catch (e) {
    debugPrint('ServiceLocator init failed (continuing with no-ops): $e');
  }
  if (!hiveReadyCompleter.isCompleted) hiveReadyCompleter.complete();

  final onboardingComplete = (prefsResult[1] as bool?) ?? false;

  // Notifications first (must create the HIGH-importance music channel before
  // audio_service binds to it), then the platform media session (media
  // notification + lock screen controls + foreground service so music keeps
  // playing in the background). All fire-and-forget; they don't block startup.
  //
  // These are chained so the channel exists before audio_service binds, but a
  // failure in one must not skip the other — a silent skip here left the media
  // controls missing with no visible cause.
  unawaited(
    NotificationService.init(navigatorKey: navigatorKey)
        .catchError((e) => debugPrint('Notifications failed: $e'))
        .whenComplete(_initAudioService),
  );

  unawaited(
    consentService.hasConsentBeenDecided().then((decided) {
      if (!decided) consentService.setAnalyticsConsent(true);
    }),
  );

  return _InitResult(onboardingComplete: onboardingComplete);
}

/// Initializes the OS media session used by the Calm Music player.
///
/// audio_service runs a foreground service on Android/iOS so the playback
/// survives backgrounding and exposes media controls (notification + lock
/// screen). On platforms without media-session support, playback still works,
/// just without lock-screen controls.
Future<void> _initAudioService() async {
  try {
    final handler = await AudioService.init(
      // Return the SAME shared instance the music screen uses — builder only
      // runs here, so identity is preserved if a screen opened first.
      builder: () => CalmAudioHandler.instance ??= CalmAudioHandler(),
      config: const AudioServiceConfig(
        // Must match NotificationService._musicChannelId, which creates it at
        // HIGH importance before this runs.
        androidNotificationChannelId: 'mindcare_playback',
        androidNotificationChannelName: 'Now Playing',
        androidNotificationOngoing: true,
        androidStopForegroundOnPause: true,
      ),
    );
    CalmAudioHandler.instance ??= handler;
  } catch (e) {
    // No media session on this platform — CalmMusicScreen already falls back
    // to playing through the local handler without lock-screen controls.
    debugPrint('AudioService init skipped: $e');
  }
}

class _InitResult {
  final bool onboardingComplete;
  const _InitResult({this.onboardingComplete = false});
}

class MindCareApp extends StatefulWidget {
  final Future<_InitResult> initFuture;
  const MindCareApp({super.key, required this.initFuture});

  @override
  State<MindCareApp> createState() => _MindCareAppState();
}

class _MindCareAppState extends State<MindCareApp> {
  // Router is cached here — never recreated on state changes.
  GoRouter? _router;

  GoRouter _getRouter(bool onboardingComplete) {
    return _router ??= AppRouter.createRouter(onboardingComplete);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_InitResult>(
      future: widget.initFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const _EarlySplash();
        }

        final result = snapshot.data!;

        return MultiBlocProvider(
          providers: [
            BlocProvider<AuthBloc>(
              lazy: true,
              create: (_) => AuthBloc(
                authService: ServiceLocator.authService ?? NoOpAuthService(),
                analyticsService: ServiceLocator.analyticsService,
                crashlyticsService: ServiceLocator.crashlyticsService,
                syncService: ServiceLocator.syncService,
              ),
            ),
            BlocProvider<SettingsCubit>(
              lazy: false,
              create: (_) {
                final cubit = SettingsCubit();
                WidgetsBinding.instance.addPostFrameCallback(
                  (_) => cubit.loadSettings(),
                );
                return cubit;
              },
            ),
          ],
          child: BlocBuilder<SettingsCubit, SettingsState>(
            // Only rebuild MaterialApp when themeMode changes — not on every
            // settings state change (e.g. notification toggle).
            buildWhen: (prev, next) => prev.themeMode != next.themeMode,
            builder: (context, settings) {
              return MaterialApp.router(
                title: 'MindCare',
                theme: AppTheme.lightTheme,
                darkTheme: AppTheme.darkTheme,
                themeMode: settings.themeMode,
                routerConfig: _getRouter(result.onboardingComplete),
                builder: (context, child) {
                  return ValueListenableBuilder<AppStrings>(
                    valueListenable: appLanguage,
                    builder: (context, strings, _) =>
                        LanguageProvider(strings: strings, child: child!),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}

/// Shown for the brief moment before Hive finish loading.
/// Uses the same [AppLoadingView] as the `/splash` route, so the very first
/// frame is visually identical to what replaces it a moment later.
class _EarlySplash extends StatelessWidget {
  const _EarlySplash();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AppLoadingView(),
    );
  }
}

/// No-op implementations for Firebase services when running without Firebase
class NoOpCrashlyticsService implements CrashlyticsService {
  @override
  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    String? reason,
    bool fatal = false,
  }) async {
    debugPrint('NoOpCrashlytics: $error');
  }

  @override
  Future<void> setUserId(String? uid) async {}
}

class NoOpRemoteConfigService implements RemoteConfigService {
  @override
  Future<void> fetchAndActivate() async {}

  @override
  bool getBool(String key) => true;

  @override
  String getString(String key) => '';

  @override
  int getInt(String key) => 0;
}

class NoOpAnalyticsService implements AnalyticsService {
  final ConsentService consentService;

  NoOpAnalyticsService({required this.consentService});

  @override
  Future<void> logEvent(String name, {Map<String, Object>? parameters}) async {}

  @override
  Future<void> setUserId(String? uid) async {}
}

class NoOpAuthService implements AuthService {
  final _controller = StreamController<auth_models.AuthUser?>.broadcast();

  NoOpAuthService() {
    // Emit an anonymous guest immediately to satisfy the interface contract.
    // Guest mode is legitimately local-only — real accounts are not available
    // while Firebase is down, and attempting one should fail loudly, not fake
    // a signed-in user.
    _controller.add(
      auth_models.AuthUser(uid: 'anonymous', email: null, isAnonymous: true),
    );
  }

  @override
  Stream<auth_models.AuthUser?> get authStateChanges => _controller.stream;

  @override
  auth_models.AuthUser? get currentUser =>
      auth_models.AuthUser(uid: 'anonymous', email: null, isAnonymous: true);

  /// Throws on any explicit account sign-in because there is no backend to
  /// honour it. UI surfaces [AuthError] instead of a phantom success.
  Never _unavailable() => throw AuthException(
        AuthErrorType.networkError,
        'Sign-in is unavailable while Firebase is offline. '
            'You are using the app as a local guest.',
      );

  @override
  Future<auth_models.AuthUser> signInAnonymously() async {
    await Future<void>.delayed(Duration.zero);
    return currentUser!;
  }

  @override
  Future<auth_models.AuthUser> signInWithEmail(
    String email,
    String password,
  ) {
    throw _unavailable();
  }

  @override
  Future<auth_models.AuthUser> signInWithGoogle() {
    throw _unavailable();
  }

  @override
  Future<auth_models.AuthUser> createAccountWithEmail(
    String email,
    String password,
  ) {
    throw _unavailable();
  }

  @override
  Future<void> sendPasswordResetEmail(String email) {
    throw _unavailable();
  }

  @override
  Future<void> signOut() async {
    // Keep the guest session — nothing to sign out of locally.
  }
}
