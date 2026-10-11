import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mind_care_app/core/l10n/app_strings.dart';
import 'package:mind_care_app/core/l10n/language_provider.dart';
import 'package:mind_care_app/features/music/models/music_track.dart';
import 'package:mind_care_app/features/music/screens/calm_music_screen.dart';
import 'package:mind_care_app/features/music/services/calm_audio_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _buildApp() {
  return LanguageProvider(
    strings: AppStrings.en,
    child: const MaterialApp(home: CalmMusicScreen()),
  );
}

/// Pumps a fixed number of frames.
///
/// The screen runs an infinite pulse animation while music is playing, so
/// [WidgetTester.pumpAndSettle] would never settle in those tests.
Future<void> settle(WidgetTester tester, [int frames = 6]) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    // The handler is a process-wide singleton; reset it so each test starts
    // from a known "nothing playing" state.
    CalmAudioHandler.instance = null;
  });

  tearDown(() {
    CalmAudioHandler.instance = null;
  });

  testWidgets('Library lists every track in play order with drag handles', (
    tester,
  ) async {
    await tester.pumpWidget(_buildApp());
    await tester.pumpAndSettle();

    expect(find.text('Play Order'), findsOneWidget);
    expect(find.text('Hold & drag to reorder'), findsOneWidget);

    // All 6 built-in tracks, in their default order.
    for (final track in kDefaultTracks) {
      expect(find.text(track.title), findsOneWidget);
    }
    expect(
      find.byType(ReorderableDragStartListener),
      findsNWidgets(kDefaultTracks.length),
    );
  });

  testWidgets('A saved play order is restored and the queue follows it', (
    tester,
  ) async {
    // Save the tracks reversed so the restored order is unambiguous.
    final reversed = kDefaultTracks.reversed.map((t) => t.id).toList();
    SharedPreferences.setMockInitialValues({
      'calm_music_play_order_v1': reversed,
    });

    await tester.pumpWidget(_buildApp());
    await settle(tester);

    expect(CalmAudioHandler.instance!.tracks.first.id, reversed.first);
    expect(
      CalmAudioHandler.instance!.tracks.map((t) => t.id).toList(),
      reversed,
    );
  });

  testWidgets('Reordering persists the new play order', (tester) async {
    await tester.pumpWidget(_buildApp());
    await tester.pumpAndSettle();

    final before = CalmAudioHandler.instance!.tracks.first.id;

    // Drag the first handle down past the second row.
    final first = tester.getTopLeft(
      find.byType(ReorderableDragStartListener).first,
    );
    final second = tester.getTopLeft(
      find.byType(ReorderableDragStartListener).at(1),
    );
    final gesture = await tester.startGesture(first);
    await tester.pump(const Duration(milliseconds: 600));
    await gesture.moveTo(Offset(first.dx, second.dy + 60));
    await tester.pump(const Duration(milliseconds: 600));
    await gesture.up();
    await tester.pumpAndSettle();

    final after = CalmAudioHandler.instance!.tracks.first.id;
    expect(after, isNot(before));

    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('calm_music_play_order_v1');
    expect(saved, isNotNull);
    expect(saved!.first, after);
  });

  testWidgets('Re-entering the screen shows a still-playing track as playing', (
    tester,
  ) async {
    await tester.pumpWidget(_buildApp());
    await tester.pumpAndSettle();

    // Simulate the shared handler reporting a running track — what the screen
    // finds when the user navigates back to it while music keeps playing.
    final handler = CalmAudioHandler.instance!;
    handler
      ..isPlayingValue.value = true
      ..indexNotifier.value = 2
      ..position.value = const Duration(seconds: 42);

    // Leave the feature, then come back to it.
    await tester.pumpWidget(const SizedBox.shrink());
    await settle(tester);
    await tester.pumpWidget(_buildApp());
    await settle(tester);

    // It opens on Now Playing (not the library) showing the running track.
    expect(find.text('00:42'), findsOneWidget);
    expect(find.text(kDefaultTracks[2].title), findsWidgets);
    expect(find.byIcon(Icons.pause_rounded), findsOneWidget);

    // On the Library tab the mini player reflects the same live playback.
    await tester.tap(find.text('Library').first);
    await settle(tester);
    expect(find.byIcon(Icons.pause_circle_filled), findsOneWidget);
    expect(find.text(kDefaultTracks[2].title), findsWidgets);
  });

  testWidgets('Stop is enabled while playing and disabled once stopped', (
    tester,
  ) async {
    await tester.pumpWidget(_buildApp());
    await tester.pumpAndSettle();

    // Nothing loaded yet — stop should be unavailable.
    await tester.tap(find.text('Now Playing').first);
    await tester.pumpAndSettle();
    final stopFinder = find.widgetWithText(TextButton, 'Stop');
    expect(stopFinder, findsOneWidget);
    expect(tester.widget<TextButton>(stopFinder).onPressed, isNull);

    // Now something is playing.
    final handler = CalmAudioHandler.instance!;
    handler
      ..isPlayingValue.value = true
      ..indexNotifier.value = 0
      ..position.value = const Duration(seconds: 10);
    await settle(tester);
    expect(tester.widget<TextButton>(stopFinder).onPressed, isNotNull);

    // Emulate what the handler publishes after a stop.
    handler
      ..isPlayingValue.value = false
      ..position.value = Duration.zero;
    await settle(tester);
    expect(tester.widget<TextButton>(stopFinder).onPressed, isNull);
  });

  testWidgets('Play resumes a paused track without throwing', (tester) async {
    await tester.pumpWidget(_buildApp());
    await tester.pumpAndSettle();

    // Pretend a track is loaded and paused mid-way.
    final handler = CalmAudioHandler.instance!;
    handler
      ..isPlayingValue.value = false
      ..indexNotifier.value = 1
      ..position.value = const Duration(seconds: 30);
    await settle(tester);

    await tester.tap(find.text('Now Playing').first);
    await settle(tester);

    expect(find.text('00:30'), findsOneWidget);
    expect(find.byIcon(Icons.play_arrow_rounded), findsWidgets);

    // Tapping play must not throw even though there is no platform player.
    await tester.tap(find.byIcon(Icons.play_arrow_rounded).first);
    await settle(tester);
    expect(tester.takeException(), isNull);
  });
}
