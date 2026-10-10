import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mind_care_app/data/models/mood_entry.dart';
import 'package:mind_care_app/data/repositories/mood_repository.dart';
import 'package:mind_care_app/features/mood/bloc/mood_bloc.dart';
import 'package:mind_care_app/features/mood/screens/mood_tracker_screen.dart';

// ── Mock ──────────────────────────────────────────────────────────────────────

class MockMoodRepository extends Mock implements MoodRepository {}

// ── Helpers ───────────────────────────────────────────────────────────────────

Widget buildMoodTrackerScreen(MoodRepository repository) {
  final router = GoRouter(
    initialLocation: '/home',
    routes: [
      GoRoute(
        path: '/home',
        builder: (_, _) => const Scaffold(body: Text('Home')),
        routes: [
          GoRoute(
            path: 'mood',
            builder: (_, _) => BlocProvider(
              create: (_) => MoodBloc(repository: repository),
              child: const MoodTrackerScreen(),
            ),
          ),
        ],
      ),
    ],
  );
  return MaterialApp.router(routerConfig: router);
}

void main() {
  late MockMoodRepository mockRepository;

  setUp(() {
    mockRepository = MockMoodRepository();
  });

  setUpAll(() {
    registerFallbackValue(
      MoodEntry(id: 'fallback', mood: MoodType.calm, timestamp: DateTime.now()),
    );
  });

  group('MoodTrackerScreen widget tests', () {
    testWidgets('submitting without selecting mood shows validation error', (
      tester,
    ) async {
      await tester.pumpWidget(buildMoodTrackerScreen(mockRepository));
      await tester.pumpAndSettle();

      // Navigate to mood screen
      tester
          .element(find.text('Home'))
          .findAncestorWidgetOfExactType<Scaffold>();
      final context = tester.element(find.text('Home'));
      GoRouter.of(context).go('/home/mood');
      await tester.pumpAndSettle();

      // Scroll down to make "Log Mood" button visible
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -300),
      );
      await tester.pump();

      // Tap "Log Mood" without selecting a mood
      await tester.tap(find.text('Log Mood'), warnIfMissed: false);
      await tester.pump();

      // Validation error should appear
      expect(find.text('Please select a mood'), findsOneWidget);
    });

    testWidgets('selecting a mood and submitting calls saveMoodEntry', (
      tester,
    ) async {
      when(() => mockRepository.saveMoodEntry(any())).thenAnswer((_) async {});

      await tester.pumpWidget(buildMoodTrackerScreen(mockRepository));
      await tester.pumpAndSettle();

      // Navigate to mood screen
      final context = tester.element(find.text('Home'));
      GoRouter.of(context).go('/home/mood');
      await tester.pumpAndSettle();

      // Select "Happy" mood
      await tester.tap(find.text('Happy'));
      await tester.pump();

      // Scroll down to make "Log Mood" button visible
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -300),
      );
      await tester.pump();

      // Tap "Log Mood"
      await tester.tap(find.text('Log Mood'), warnIfMissed: false);
      await tester.pump();

      // saveMoodEntry should have been called
      verify(() => mockRepository.saveMoodEntry(any())).called(1);
    });

    testWidgets('selecting a mood clears validation error', (tester) async {
      await tester.pumpWidget(buildMoodTrackerScreen(mockRepository));
      await tester.pumpAndSettle();

      // Navigate to mood screen
      final context = tester.element(find.text('Home'));
      GoRouter.of(context).go('/home/mood');
      await tester.pumpAndSettle();

      // Scroll to and tap "Log Mood" to trigger validation error
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -300),
      );
      await tester.pump();
      await tester.tap(find.text('Log Mood'), warnIfMissed: false);
      await tester.pump();
      expect(find.text('Please select a mood'), findsOneWidget);

      // Select a mood
      await tester.tap(find.text('Calm'));
      await tester.pump();

      // Validation error should be gone
      expect(find.text('Please select a mood'), findsNothing);
    });
  });
}
