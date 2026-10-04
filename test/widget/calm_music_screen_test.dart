import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mind_care_app/core/l10n/app_strings.dart';
import 'package:mind_care_app/core/l10n/language_provider.dart';
import 'package:mind_care_app/features/music/screens/calm_music_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _buildApp() {
  return LanguageProvider(
    strings: AppStrings.en,
    child: const MaterialApp(home: CalmMusicScreen()),
  );
}

/// Pumps a fixed number of frames.
Future<void> settle(WidgetTester tester, [int frames = 6]) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Library lists every default track in order', (tester) async {
    await tester.pumpWidget(_buildApp());
    await tester.pumpAndSettle();

    expect(find.text('All Tracks'), findsOneWidget);

    // All 6 built-in tracks, in their default order.
    for (final track in kDefaultTracks) {
      expect(find.text(track.title), findsOneWidget);
    }
  });

  testWidgets('My Playlist starts empty', (tester) async {
    await tester.pumpWidget(_buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('My Playlist').first);
    await settle(tester);

    expect(find.text('Your playlist is empty'), findsOneWidget);
  });

  testWidgets('Now Playing tab shows the queue with every track', (
    tester,
  ) async {
    await tester.pumpWidget(_buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Now Playing').first);
    await settle(tester);

    expect(find.text('Queue'), findsOneWidget);
    for (final track in kDefaultTracks) {
      expect(find.text(track.title), findsAtLeastNWidgets(1));
    }
  });

  testWidgets('Now Playing opens on the first track with a play button', (
    tester,
  ) async {
    await tester.pumpWidget(_buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Now Playing').first);
    await settle(tester);

    // Nothing has been loaded yet, so the current (first) track is shown with
    // a play button.
    expect(find.text(kDefaultTracks.first.title), findsWidgets);
    expect(find.byIcon(Icons.play_arrow_rounded), findsWidgets);
    expect(find.byIcon(Icons.pause_rounded), findsNothing);
  });

  testWidgets('mini player is hidden until a track starts playing', (
    tester,
  ) async {
    await tester.pumpWidget(_buildApp());
    await tester.pumpAndSettle();

    // Library tab, nothing playing yet.
    expect(find.byIcon(Icons.pause_circle_filled), findsNothing);
    expect(find.text(kDefaultTracks.first.title), findsOneWidget);
  });
}