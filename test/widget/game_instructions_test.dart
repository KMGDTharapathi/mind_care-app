import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mind_care_app/core/l10n/app_strings.dart';
import 'package:mind_care_app/core/l10n/language_provider.dart';
import 'package:mind_care_app/features/games/widgets/game_assistant.dart';
import 'package:mind_care_app/features/games/widgets/game_instructions_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _wrap(Widget child) {
  return LanguageProvider(
    strings: AppStrings.en,
    child: MaterialApp(home: child),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Instructions screen shows short steps and Start runs onStart',
      (tester) async {
    var started = false;
    await tester.pumpWidget(
      _wrap(
        Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => showGameInstructions(
                  context,
                  emoji: '🍬',
                  title: 'Candy Crush',
                  steps: const ['Swap adjacent candies', 'Line up 3 same'],
                  accentColor: const Color(0xFFEC407A),
                  onStart: () => started = true,
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('How to Play'), findsOneWidget);
    expect(find.text('Candy Crush'), findsOneWidget);
    expect(find.text('Swap adjacent candies'), findsOneWidget);
    expect(find.text('Line up 3 same'), findsOneWidget);

    await tester.tap(find.text('PLAY ▶'));
    await tester.pumpAndSettle();
    expect(started, isTrue);
  });

  testWidgets('Game assistant opens a bottom sheet with tips', (tester) async {
    await tester.pumpWidget(
      _wrap(
        Scaffold(
          body: Center(
            child: GameAssistant(
              emoji: '🧠',
              title: 'Candy Crush',
              tips: const ['Match 4+ to create specials'],
              accentColor: const Color(0xFFEC407A),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(GameAssistant));
    await tester.pumpAndSettle();

    expect(find.text('Game Assistant'), findsOneWidget);
    expect(find.text('Match 4+ to create specials'), findsOneWidget);

    await tester.tap(find.text('Got it!'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}