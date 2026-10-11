import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:mind_care_app/firebase_options.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mind_care_app/core/firebase/firebase_error_screen.dart';
import 'package:mind_care_app/core/firebase/firebase_initializer.dart';
import 'package:mind_care_app/core/l10n/app_strings.dart';
import 'package:mind_care_app/core/l10n/language_provider.dart';
import 'package:mind_care_app/core/router/app_router.dart';
import 'package:mind_care_app/core/service_locator.dart';
import 'package:mind_care_app/core/theme/app_theme.dart';
import 'package:mind_care_app/data/local/hive_service.dart';
import 'package:mind_care_app/data/local/notification_service.dart';
import 'package:mind_care_app/data/local/preferences_service.dart';
import 'package:mind_care_app/features/auth/bloc/auth_bloc.dart';
import 'package:mind_care_app/features/onboarding/screens/consent_prompt_screen.dart';
import 'package:mind_care_app/features/settings/bloc/settings_cubit.dart';
import 'package:mind_care_app/services/auth/firebase_auth_service.dart';
import 'package:mind_care_app/services/consent/consent_service.dart';
import 'package:mind_care_app/services/analytics/firebase_analytics_service.dart';
import 'package:mind_care_app/services/crashlytics/firebase_crashlytics_service.dart';
import 'package:mind_care_app/services/remote_config/firebase_remote_config_service.dart';

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

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  bool firebaseOk = true;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
    firebaseOk = false;
  }

  // Start the app immediately — router shows /splash at once.
  runApp(MindCareApp(
    initFuture: Future.value(_InitResult(firebaseOk: firebaseOk)),
  ));

  // Defer heavy init until after the first frame is painted.
  // Using a microtask + Future.delayed ensures the engine has actually
  // rendered before we touch any platform channels (Hive, SharedPreferences).
  WidgetsBinding.instance.addPostFrameCallback((_) {
    Future.delayed(const Duration(milliseconds: 100), () {
      _heavyInit(firebaseOk).catchError((e) => debugPrint('_heavyInit error: $e'));
    });
  });
}

/// All heavy init — called after first frame is painted.
Future<_InitResult> _heavyInit(bool firebaseOk) async {
  // Yield immediately so the first frame renders before any heavy work
  await Future.delayed(const Duration(milliseconds: 50));

  final consentService = ConsentService();
  final crashlyticsService =
      FirebaseCrashlyticsService(consentService: consentService);

  bool _firebaseReady = false;

  FlutterError.onError = (details) {
    if (_firebaseReady) {
      crashlyticsService.recordError(details.exception, details.stack, fatal: true);
    } else {
      FlutterError.presentError(details);
    }
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    if (_firebaseReady) {
      crashlyticsService.recordError(error, stack, fatal: true);
    }
    return true;
  };

  final remoteConfig = FirebaseRemoteConfigService(
    crashlyticsService: crashlyticsService,
  );

  // Warm up SharedPreferences cache FIRST — single platform channel call that
  // all subsequent reads (PreferencesService, ConsentService, etc.) will reuse
  // as synchronous cache hits, preventing concurrent getInstance() calls that
  // can block the main isolate.
  await PreferencesService.warmUp();

  // Hive and Preferences run in parallel — both are needed before we can
  // determine onboardingComplete.
  // Yield to the event loop first so the UI stays responsive.
  await Future.delayed(Duration.zero);
  final prefsResult = await Future.wait<dynamic>([
    HiveService.init()
        .timeout(const Duration(seconds: 4))
        .catchError((e) { debugPrint('Hive failed: $e'); }),
    PreferencesService.isOnboardingComplete()
        .timeout(const Duration(seconds: 3))
        .catchError((e) { debugPrint('Prefs failed: $e'); return false; }),
  ]);

  // Pre-fetch name + language while still in _heavyInit so the splash screen
  // can read them from globals (zero platform calls on the main thread).
  final navResults = await Future.wait([
    PreferencesService.getUserName(),
    PreferencesService.getAppLanguage(),
  ]);
  splashSavedName = navResults[0];
  splashSavedLang = navResults[1];

  // Restore saved language into the global notifier immediately so all
  // screens reflect the correct language from the very first frame.
  if (splashSavedLang == 'si') {
    appLanguage.value = AppStrings.si;
  }

  // Signal splash screen that Hive + nav data are ready — safe to navigate now.
  if (!hiveReadyCompleter.isCompleted) hiveReadyCompleter.complete();

  final onboardingComplete = (prefsResult[1] as bool?) ?? false;

  // Firebase is already initialized synchronously.
  if (firebaseOk) {
    unawaited(ServiceLocator.init(
      remoteConfig: remoteConfig,
      analytics: FirebaseAnalyticsService(consentService: consentService),
      crashlytics: crashlyticsService,
    ).catchError((e) => debugPrint('ServiceLocator failed: $e')));
  }

  unawaited(NotificationService.init(navigatorKey: navigatorKey)
      .catchError((e) => debugPrint('Notifications failed: $e')));

  unawaited(consentService.hasConsentBeenDecided().then((decided) {
    if (!decided) consentService.setAnalyticsConsent(true);
  }));

  return _InitResult(firebaseOk: firebaseOk, onboardingComplete: onboardingComplete);
}

class _InitResult {
  final bool firebaseOk;
  final bool onboardingComplete;
  const _InitResult({required this.firebaseOk, this.onboardingComplete = false});
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
        if (!result.firebaseOk) {
          return const FirebaseErrorScreen();
        }

        return MultiBlocProvider(
          providers: [
            BlocProvider<AuthBloc>(
              lazy: true,
              create: (_) => AuthBloc(
                authService: ServiceLocator.authService ?? FirebaseAuthService(),
                analyticsService: ServiceLocator.analyticsService,
                crashlyticsService: ServiceLocator.crashlyticsService,
              ),
            ),
            BlocProvider<SettingsCubit>(
              lazy: true,
              create: (_) {
                final cubit = SettingsCubit();
                WidgetsBinding.instance
                    .addPostFrameCallback((_) => cubit.loadSettings());
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
                    builder: (context, strings, _) => LanguageProvider(
                      strings: strings,
                      child: child!,
                    ),
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

/// Shown for the brief moment before Firebase/Hive finish loading.
/// Identical look to the real SplashScreen but needs zero dependencies.
class _EarlySplash extends StatelessWidget {
  const _EarlySplash();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFFB2DFDB),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFB2DFDB), Color(0xFF80CBC4), Color(0xFF4DB6AC)],
            ),
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.eco_rounded, size: 72, color: Color(0xFF004D40)),
                SizedBox(height: 20),
                Text('MindCare',
                    style: TextStyle(
                        fontSize: 34, fontWeight: FontWeight.bold,
                        color: Color(0xFF004D40), letterSpacing: 0.5)),
                SizedBox(height: 12),
                SizedBox(
                  width: 24, height: 24,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.5, color: Color(0xFF004D40)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
