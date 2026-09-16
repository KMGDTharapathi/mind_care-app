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
          builder: (_, _) => const OnboardingScreen(),
        ),
        GoRoute(
          path: '/home',
          builder: (_, _) => const Scaffold(body: Text('Home')),
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

    testWidgets('swiping to page 2 updates dot indicator', (tester) async {
      await tester.pumpWidget(buildOnboardingScreen());
      await tester.pumpAndSettle();

      // Swipe left to go to page 2
      await tester.drag(find.byType(PageView), const Offset(-400, 0));
      await tester.pumpAndSettle();

      // Page 2 should show "Track Your Mood"
      expect(find.text('Track Your Mood'), findsOneWidget);
    });

    testWidgets('"Get Started" button is visible on last page', (tester) async {
      await tester.pumpWidget(buildOnboardingScreen());
      await tester.pumpAndSettle();

      // Swipe to page 2
      await tester.drag(find.byType(PageView), const Offset(-400, 0));
      await tester.pumpAndSettle();

      // Swipe to page 3
      await tester.drag(find.byType(PageView), const Offset(-400, 0));
      await tester.pumpAndSettle();

      // "Get Started" button should be visible
      expect(find.text('Get Started'), findsOneWidget);
      expect(find.text('Find Your Calm'), findsOneWidget);
    });

    testWidgets('"Get Started" button calls setOnboardingComplete', (
      tester,
    ) async {
      await tester.pumpWidget(buildOnboardingScreen());
      await tester.pumpAndSettle();

      // Navigate to last page
      await tester.drag(find.byType(PageView), const Offset(-400, 0));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(PageView), const Offset(-400, 0));
      await tester.pumpAndSettle();

      // Tap "Get Started"
      await tester.tap(find.text('Get Started'));
      await tester.pump();

      // Verify onboarding complete was set in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('onboarding_complete'), isTrue);
    });
  });
}
