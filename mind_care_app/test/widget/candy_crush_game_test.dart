import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mind_care_app/core/l10n/app_strings.dart';
import 'package:mind_care_app/core/l10n/language_provider.dart';
import 'package:mind_care_app/features/games/screens/candy_crush_game.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _buildApp() {
  return LanguageProvider(
    strings: AppStrings.en,
    child: const MaterialApp(home: CandyCrushGame()),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Candy Crush game renders the board, HUD and survives taps',
      (tester) async {
    await tester.pumpWidget(_buildApp());
    await tester.pumpAndSettle();

    // HUD labels render
    expect(find.text('Level 1'), findsOneWidget);
    expect(find.text('Target: 800'), findsOneWidget);
    expect(find.text('Score'), findsOneWidget);
    expect(find.text('Moves'), findsOneWidget);

    // Board is an 8x8 grid of candies
    expect(find.byType(GridView), findsOneWidget);
    final grid = tester.widget<GridView>(find.byType(GridView));
    expect(grid.gridDelegate, isA<SliverGridDelegateWithFixedCrossAxisCount>());
    expect(
      (grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount)
          .crossAxisCount,
      8,
    );

    // Tapping around the board must not throw.
    for (var i = 0; i < 8; i++) {
      await tester.tapAt(const Offset(120, 300));
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('Best score persists across games', (tester) async {
    SharedPreferences.setMockInitialValues({'candy_crush_best': 1234});
    await tester.pumpWidget(_buildApp());
    await tester.pumpAndSettle();

    expect(find.text('1234'), findsOneWidget);
  });
}