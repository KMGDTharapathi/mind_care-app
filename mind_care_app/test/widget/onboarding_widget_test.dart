import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mind_care_app/core/router/app_router.dart';
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
          builder: (_, _) => const OnboardingScreen(),
        ),
        GoRoute(
          path: AppRouter.languageSelect,
          builder: (_, _) => const Scaffold(body: Text('Language Select')),
        ),
        GoRoute(
          path: '/home',
          builder: (_, _) => const Scaffold(body: Text('Home')),
        ),
      ],
    );
    return MaterialApp.router(routerConfig: router);
  }

  Future<void> goToLastPage(WidgetTester tester) async {
    // Page 1 -> Page 2 (name input)
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    // Enter name and continue to Page 3
    await tester.enterText(find.byType(TextField), 'Alex');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
  }

  group('OnboardingScreen widget tests', () {
    testWidgets('initial page shows "MindCare" text', (tester) async {
      await tester.pumpWidget(buildOnboardingScreen());
      await tester.pumpAndSettle();

      expect(find.text('MindCare'), findsOneWidget);
    });

    testWidgets('Next button advances to the name input page', (tester) async {
      await tester.pumpWidget(buildOnboardingScreen());
      await tester.pumpAndSettle();

      // Swiping is disabled — navigation is button-driven
      await tester.drag(find.byType(PageView), const Offset(-400, 0));
      await tester.pumpAndSettle();
      expect(find.text('MindCare'), findsOneWidget);

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Page 2 should show the name input
      expect(find.text('Who am I chatting with?'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('"Get Started" button is visible on last page', (tester) async {
      await tester.pumpWidget(buildOnboardingScreen());
      await tester.pumpAndSettle();

      await goToLastPage(tester);

      // "Get Started" button should be visible
      expect(find.text('Get Started'), findsOneWidget);
      expect(find.text('Find Your Calm'), findsOneWidget);
    });

    testWidgets('"Get Started" button calls setOnboardingComplete', (
      tester,
    ) async {
      await tester.pumpWidget(buildOnboardingScreen());
      await tester.pumpAndSettle();

      await goToLastPage(tester);

      // Tap "Get Started"
      await tester.tap(find.text('Get Started'));
      await tester.pumpAndSettle();

      // Verify onboarding complete was set in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('onboarding_complete'), isTrue);
    });
  });
}