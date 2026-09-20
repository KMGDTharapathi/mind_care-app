import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mind_care_app/core/l10n/app_strings.dart';
import 'package:mind_care_app/core/l10n/language_provider.dart';
import 'package:mind_care_app/data/local/preferences_service.dart';
import 'package:mind_care_app/features/auth/bloc/auth_bloc.dart';
import 'package:mind_care_app/features/settings/bloc/settings_cubit.dart';
import 'package:mind_care_app/features/settings/screens/settings_screen.dart';
import 'package:mind_care_app/main.dart' show appUserName;
import 'package:mind_care_app/services/auth/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Minimal fake auth service that never emits null (per the AuthService
/// contract). Avoids any Firebase plugin channel calls in the test env.
class _FakeAuthService implements AuthService {
  @override
  Stream<AuthUser?> get authStateChanges async* {
    yield const AuthUser(uid: 'anon-test', isAnonymous: true);
  }

  @override
  AuthUser? get currentUser =>
      const AuthUser(uid: 'anon-test', isAnonymous: true);

  @override
  Future<AuthUser> createAccountWithEmail(String email, String password) async =>
      const AuthUser(uid: 'anon-test', isAnonymous: true);

  @override
  Future<AuthUser> signInAnonymously() async =>
      const AuthUser(uid: 'anon-test', isAnonymous: true);

  @override
  Future<AuthUser> signInWithEmail(String email, String password) async =>
      const AuthUser(uid: 'anon-test', isAnonymous: true);

  @override
  Future<AuthUser> signInWithGoogle() async =>
      const AuthUser(uid: 'anon-test', isAnonymous: true);

  @override
  Future<void> sendPasswordResetEmail(String email) async {}

  @override
  Future<void> signOut() async {}
}

/// Mimics HomeScreen's reaction to a name change: it listens to the global
/// [appUserName] notifier and re-renders the greeting so the same build path
/// (and any latent crash) runs when the notifier fires.
class _HomeHarness extends StatefulWidget {
  const _HomeHarness();

  @override
  State<_HomeHarness> createState() => _HomeHarnessState();
}

class _HomeHarnessState extends State<_HomeHarness> {
  void _onUserNameChanged() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    appUserName.addListener(_onUserNameChanged);
    if (appUserName.value == null) {
      PreferencesService.getUserName().then((name) {
        if (mounted) appUserName.value = name;
      });
    }
  }

  @override
  void dispose() {
    appUserName.removeListener(_onUserNameChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final name = (appUserName.value != null && appUserName.value!.isNotEmpty)
        ? appUserName.value!
        : null;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(name != null ? 'Hello, $name' : 'Not set yet'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
              child: const Text('Open Settings'),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _buildApp(_FakeAuthService authService) {
  return LanguageProvider(
    strings: AppStrings.en,
    child: MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (_) => AuthBloc(authService: authService),
        ),
        BlocProvider<SettingsCubit>(create: (_) => SettingsCubit()),
      ],
      child: MaterialApp(
        home: const _HomeHarness(),
      ),
    ),
  );
}

void main() {
  late _FakeAuthService authService;

  setUp(() {
    SharedPreferences.setMockInitialValues({'user_name': 'Old Name'});
    authService = _FakeAuthService();
  });

  tearDown(() {
    appUserName.value = null;
  });

  testWidgets('Changing the name in settings does not crash the widget tree',
      (tester) async {
    await tester.pumpWidget(_buildApp(authService));
    await tester.pumpAndSettle();

    // Greeting shows the current name
    expect(find.text('Hello, Old Name'), findsOneWidget);

    // Open settings and change the name
    await tester.tap(find.text('Open Settings'));
    await tester.pumpAndSettle();
    expect(find.byType(SettingsScreen), findsOneWidget);

    await tester.tap(find.text('Your Name'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'New Name');
    await tester.pump();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    // No Flutter red error screen anywhere in this frame sequence
    expect(tester.takeException(), isNull);

    // Name persisted and reflected in the settings subtitle
    expect(find.text('New Name'), findsWidgets);

    // Pop back to the "home" harness — same rebuild path HomeScreen runs
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Hello, New Name'), findsOneWidget);
  });
}