import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mind_care_app/core/service_locator.dart';
import 'package:mind_care_app/data/repositories/journal_repository.dart';
import 'package:mind_care_app/data/repositories/mood_repository.dart';
import 'package:mind_care_app/data/repositories/firestore/firestore_mood_repository.dart';
import 'package:mind_care_app/data/repositories/resource_repository.dart';
import 'package:mind_care_app/features/breathing/screens/breathing_list_screen.dart';
import 'package:mind_care_app/features/breathing/screens/breathing_only_screen.dart';
import 'package:mind_care_app/features/breathing/screens/breathing_session_screen.dart';
import 'package:mind_care_app/features/home/screens/home_screen.dart';
import 'package:mind_care_app/features/journal/bloc/journal_bloc.dart';
import 'package:mind_care_app/features/journal/screens/journal_entry_screen.dart';
import 'package:mind_care_app/features/journal/screens/journal_list_screen.dart';
import 'package:mind_care_app/features/mood/bloc/mood_bloc.dart';
import 'package:mind_care_app/features/mood/screens/mood_history_screen.dart';
import 'package:mind_care_app/features/mood/screens/mood_checkin_screen.dart';
import 'package:mind_care_app/features/mood/screens/mood_tracker_screen.dart';
import 'package:mind_care_app/features/onboarding/screens/onboarding_screen.dart';
import 'package:mind_care_app/features/resources/bloc/resource_bloc.dart';
import 'package:mind_care_app/features/resources/screens/resource_detail_screen.dart';
import 'package:mind_care_app/features/resources/screens/resource_library_screen.dart';
import 'package:mind_care_app/features/resources/screens/saved_screen.dart';
import 'package:mind_care_app/features/settings/screens/settings_screen.dart';
import 'package:mind_care_app/features/auth/screens/forgot_password_screen.dart';
import 'package:mind_care_app/features/auth/screens/sign_in_screen.dart';
import 'package:mind_care_app/features/auth/screens/sign_up_screen.dart';
import 'package:mind_care_app/core/l10n/app_strings.dart';
import 'package:mind_care_app/core/l10n/language_provider.dart';
import 'package:mind_care_app/features/language/screens/language_select_screen.dart';
import 'package:mind_care_app/features/games/screens/games_screen.dart';
import 'package:mind_care_app/features/meditation/screens/meditation_list_screen.dart';
import 'package:mind_care_app/features/music/screens/calm_music_screen.dart';
import 'package:mind_care_app/features/motivational/screens/motivational_screen.dart';
import 'package:mind_care_app/features/counsellor/screens/counsellor_call_screen.dart';
import 'package:mind_care_app/features/chat/screens/sinhala_chat_screen.dart';
import 'package:mind_care_app/features/reminders/screens/daily_reminders_screen.dart';
import 'package:mind_care_app/features/painting/screens/painting_screen.dart';
import 'package:mind_care_app/features/splash/splash_screen.dart';
import 'package:mind_care_app/features/chat/screens/willow_chat_screen.dart';
import 'package:mind_care_app/main.dart' show appLanguage;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:mind_care_app/features/find_doctor/cubit/doctor_search_cubit.dart';
import 'package:mind_care_app/features/find_doctor/screens/find_doctor_screen.dart';
import 'package:mind_care_app/features/find_doctor/services/firestore_doctor_service.dart';
import 'package:mind_care_app/features/find_doctor/services/geocoder_service.dart';
import 'package:mind_care_app/features/find_doctor/services/location_service.dart';
import 'package:mind_care_app/features/find_doctor/services/overpass_service.dart';

class AppRouter {
  // Named route constants
  static const String splash = '/splash';
  static const String languageSelect = '/language-select';
  static const String onboarding = '/onboarding';
  static const String moodCheckin = '/mood-checkin';
  static const String home = '/home';
  static const String moodTracker = '/mood-tracker';
  static const String moodHistory = '/mood-history';
  static const String breathing = '/breathing';
  static const String breathingSession = '/breathing/:patternId';
  static const String journal = '/journal';
  static const String journalNew = '/journal/new';
  static const String journalEntry = '/journal/:entryId';
  static const String resources = '/resources';
  static const String resourcesSaved = '/resources/saved';
  static const String resourceDetail = '/resources/:resourceId';
  static const String settings = '/settings';
  static const String games = '/games';
  static const String calmMusic = '/calm-music';
  static const String meditation = '/meditation';
  static const String signIn = '/sign-in';
  static const String signUp = '/sign-up';
  static const String forgotPassword = '/forgot-password';
  static const String painting = '/painting';
  static const String breathingExercises = '/breathing-exercises';
  static const String motivational = '/motivational';
  static const String counsellorCall = '/counsellor-call';
  static const String dailyReminders = '/daily-reminders';
  static const String sinhalaChatRoute = '/sinhala-chat';
  static const String willowChat = '/willow-chat';
  static const String findDoctor = '/find-doctor';

  /// Creates a router with a redirect guard ensuring users are logged in
  /// before accessing app screens.
  static GoRouter createRouter(bool onboardingComplete) {
    return GoRouter(
      initialLocation: splash,
      routes: _routes,
      redirect: (context, state) {
        final path = state.uri.path;
        final loggedIn = FirebaseAuth.instance.currentUser != null;

        final isAuthScreen = path == signIn ||
            path == signUp ||
            path == forgotPassword ||
            path == splash ||
            path == languageSelect ||
            path == onboarding;

        if (!loggedIn && !isAuthScreen) {
          return signIn;
        }
        return null;
      },
    );
  }

  static final List<RouteBase> _routes = [
      GoRoute(
        path: splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: languageSelect,
        builder: (context, state) => const LanguageSelectScreen(),
      ),
      GoRoute(
        path: onboarding,
        builder: (context, state) {
          final returning = state.uri.queryParameters['returning'] == 'true';
          return OnboardingScreen(returning: returning);
        },
      ),
      GoRoute(
        path: moodCheckin,
        builder: (context, state) {
          final lang = state.uri.queryParameters['lang'] ?? 'en';
          return MoodCheckinScreen(lang: lang);
        },
      ),
      GoRoute(
        path: home,
        builder: (context, state) {
          final lang = state.uri.queryParameters['lang'] ?? 'en';
          return HomeScreen(lang: lang);
        },
      ),
      GoRoute(
        path: moodTracker,
        builder: (context, state) => BlocProvider(
          create: (_) => MoodBloc(
            repository: FirestoreMoodRepository(),
            syncService: ServiceLocator.syncService,
            analyticsService: ServiceLocator.analyticsService,
          ),
          child: const MoodTrackerScreen(),
        ),
      ),
      GoRoute(
        path: moodHistory,
        builder: (context, state) =>
            MoodHistoryScreen(repository: FirestoreMoodRepository()),
      ),
      GoRoute(
        path: breathing,
        builder: (context, state) => const BreathingListScreen(),
        routes: [
          GoRoute(
            path: ':patternId',
            builder: (context, state) => BreathingSessionScreen(
              patternId: state.pathParameters['patternId']!,
              analyticsService: ServiceLocator.analyticsService,
            ),
          ),
        ],
      ),
      GoRoute(
        path: journal,
        builder: (context, state) => BlocProvider(
          create: (_) => JournalBloc(
            repository: HiveJournalRepository(),
            syncService: ServiceLocator.syncService,
            remoteConfigService: ServiceLocator.remoteConfigService,
            analyticsService: ServiceLocator.analyticsService,
          ),
          child: const JournalListScreen(),
        ),
        routes: [
          GoRoute(
            path: 'new',
            builder: (context, state) => BlocProvider(
              create: (_) => JournalBloc(
                repository: HiveJournalRepository(),
                syncService: ServiceLocator.syncService,
                remoteConfigService: ServiceLocator.remoteConfigService,
                analyticsService: ServiceLocator.analyticsService,
              ),
              child: const JournalEntryScreen(entryId: null),
            ),
          ),
          GoRoute(
            path: ':entryId',
            builder: (context, state) => BlocProvider(
              create: (_) => JournalBloc(
                repository: HiveJournalRepository(),
                syncService: ServiceLocator.syncService,
                remoteConfigService: ServiceLocator.remoteConfigService,
                analyticsService: ServiceLocator.analyticsService,
              ),
              child: JournalEntryScreen(
                entryId: state.pathParameters['entryId'],
              ),
            ),
          ),
        ],
      ),
      GoRoute(
        path: resources,
        builder: (context, state) => BlocProvider(
          create: (_) => ResourceBloc(
            repository: ResourceRepository(),
            analyticsService: ServiceLocator.analyticsService,
          ),
          child: const ResourceLibraryScreen(),
        ),
        routes: [
          GoRoute(
            path: 'saved',
            builder: (context, state) => const SavedScreen(),
          ),
          GoRoute(
            path: ':resourceId',
            builder: (context, state) {
              final resourceId = state.pathParameters['resourceId']!;
              return ResourceDetailScreen(resourceId: resourceId);
            },
          ),
        ],
      ),
      GoRoute(
        path: settings,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: games,
        builder: (context, state) => const GamesScreen(),
      ),
      GoRoute(
        path: calmMusic,
        builder: (context, state) => const CalmMusicScreen(),
      ),
      GoRoute(
        path: meditation,
        builder: (context, state) => const MeditationListScreen(),
      ),
      GoRoute(
        path: signIn,
        builder: (context, state) => const SignInScreen(),
      ),
      GoRoute(
        path: signUp,
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: painting,
        builder: (context, state) => const PaintingScreen(),
      ),
      GoRoute(
        path: breathingExercises,
        builder: (context, state) => const BreathingOnlyScreen(),
      ),
      GoRoute(
        path: motivational,
        builder: (context, state) => const MotivationalScreen(),
      ),
      GoRoute(
        path: counsellorCall,
        builder: (context, state) => const CounsellorCallScreen(),
      ),
      GoRoute(
        path: dailyReminders,
        builder: (context, state) => const DailyRemindersScreen(),
      ),
      GoRoute(
        path: sinhalaChatRoute,
        builder: (context, state) => const SinhalaChatScreen(),
      ),
      GoRoute(
        path: willowChat,
        builder: (context, state) {
          final lang = state.uri.queryParameters['lang'] ?? 'en';
          return WillowChatScreen(lang: lang);
        },
      ),
      GoRoute(
        path: AppRouter.findDoctor,
        builder: (context, state) => BlocProvider(
          create: (_) => DoctorSearchCubit(
            firestoreService: FirestoreDoctorService(),
            locationService: LocationService(),
            geocoderService: GeocoderService(),
            overpassService: OverpassService(),
            connectivity: Connectivity(),
          )..init(),
          child: const FindDoctorScreen(),
        ),
      ),
    ];
}

