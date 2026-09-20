import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mind_care_app/core/l10n/app_strings.dart';
import 'package:mind_care_app/core/l10n/language_provider.dart';
import 'package:mind_care_app/features/meditation/screens/meditation_list_screen.dart';
import 'package:mind_care_app/features/meditation/screens/meditation_session_screen.dart';

const _meditation = MeditationData(
  id: 'auto-advance-test',
  name: 'Test Med',
  pali: 'පරීක්ෂණ භාවනාව',
  description: 'description',
  emoji: '🧘',
  gradient: [
    Color(0xFF4FC3F7),
    Color(0xFF0288D1),
    Color(0xFF01579B),
  ],
  duration: '2 min',
  level: 'Beginner',
  techniques: ['Technique'],
  goals: ['Goal'],
  steps: [
    MeditationStep(
      title: 'First',
      instruction: 'Breathe in and out.',
      durationSeconds: 1,
      emoji: '💨',
      color: Color(0xFF4FC3F7),
    ),
    MeditationStep(
      title: 'Second',
      instruction: 'Sit in stillness.',
      durationSeconds: 1,
      emoji: '🧘',
      color: Color(0xFF4FC3F7),
    ),
  ],
);

Widget _wrap() {
  return LanguageProvider(
    strings: AppStrings.en,
    child: const MaterialApp(
      home: MeditationSessionScreen(meditation: _meditation),
    ),
  );
}

void main() {
  testWidgets(
      'Countdown auto-advances to the next step and keeps it running',
      (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();

    // Intro → start the session.
    await tester.tap(find.text('Begin Meditation'));
    await tester.pumpAndSettle();
    expect(find.text('Step 1: First'), findsOneWidget);

    // Start step 1's timer. Its 1s countdown finishes almost immediately.
    await tester.tap(find.byIcon(Icons.play_arrow_rounded));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    // Next step appears AND its timer has auto-started (pause icon shown).
    expect(find.text('Step 2: Second'), findsOneWidget);
    expect(find.byIcon(Icons.pause_rounded), findsOneWidget);

    // Step 2 is the last step → session finishes on its own.
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.text('Well Done!'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Manual skip still works as before (no auto-start)',
      (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Begin Meditation'));
    await tester.pumpAndSettle();
    expect(find.text('Step 1: First'), findsOneWidget);

    // Tapping the skip button moves on, but does not start the timer.
    await tester.tap(find.text('Skip this step →'));
    await tester.pumpAndSettle();
    expect(find.text('Step 2: Second'), findsOneWidget);
    expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}