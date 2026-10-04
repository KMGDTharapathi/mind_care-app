import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mind_care_app/features/onboarding/screens/onboarding_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    // Use in-memory SharedPreferences for tests
    SharedPreferences.setMockInitialValues({});
  });

  Widget buildOnboardingScreen() {
    final router = GoRouter(
      initialLocation: '/onboarding',
      routes: [
        GoRoute(
          path: '/onboarding',
          builder: (_, __) => const OnboardingScreen(),
        ),
        GoRoute(
          path: '/home',
          builder: (_, __) => const Scaffold(body: Text('Home')),
        ),
        GoRoute(
          path: '/language-select',
          builder: (_, __) => const Scaffold(body: Text('Language')),
        ),
      ],
    );
    return MaterialApp.router(routerConfig: router);
  }

  group('OnboardingScreen widget tests', () {
    testWidgets('initial page shows "MindCare" text', (tester) async {
      await tester.pumpWidget(buildOnboardingScreen());
      await tester.pumpAndSettle();

      expect(find.text('MindCare'), findsOneWidget);
    });

testWidgets('tapping Next moves to the name input page', (tester) async {
    await tester.pumpWidget(buildOnboardingScreen());
    await tester.pumpAndSettle();

    // Navigation is button-driven, so the page advances via the Next button.
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    // Page 2 should show the name prompt
    expect(find.text('Who am I chatting with?'), findsOneWidget);
  });

    testWidgets('"Get Started" button is visible on last page', (tester) async {
      await tester.pumpWidget(buildOnboardingScreen());
      await tester.pumpAndSettle();

      // Go to page 2
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Go to page 3 (name page advances once a name is entered)
      await tester.enterText(find.byType(TextField), 'Test');
      await tester.pump();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // "Get Started" button should be visible
      expect(find.text('Get Started'), findsOneWidget);
      expect(find.text('Find Your Calm'), findsOneWidget);
    });

    testWidgets('"Get Started" button calls setOnboardingComplete', (tester) async {
      await tester.pumpWidget(buildOnboardingScreen());
      await tester.pumpAndSettle();

      // Go to page 2
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Go to page 3
      await tester.enterText(find.byType(TextField), 'Test');
      await tester.pump();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Tap "Get Started"
      await tester.tap(find.text('Get Started'));
      await tester.pumpAndSettle();

      // Verify onboarding complete was set in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('onboarding_complete'), isTrue);
    });
  });
}
