import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mind_care_app/core/l10n/app_strings.dart';
import 'package:mind_care_app/core/l10n/language_provider.dart';
import 'package:mind_care_app/features/reminders/screens/daily_reminders_screen.dart';
import 'package:mind_care_app/features/settings/bloc/settings_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The push tab renders the message editor only when
/// `state.notificationsEnabled` is true, so the cubit has to start in that
/// state. Driving the real `setNotificationsEnabled` would call
/// `flutter_local_notifications` platform channels, which fail in tests.
class _NotificationsOnCubit extends SettingsCubit {
  _NotificationsOnCubit() : super() {
    emit(const SettingsState(notificationsEnabled: true));
  }
}

Widget _buildApp({required bool notificationsOn}) {
  return LanguageProvider(
    strings: AppStrings.en,
    child: BlocProvider<SettingsCubit>(
      create: (_) =>
          notificationsOn ? _NotificationsOnCubit() : SettingsCubit(),
      child: const MaterialApp(home: DailyRemindersScreen()),
    ),
  );
}

/// The editor uses an autofocused TextField, so its blinking cursor stops the
/// tree from ever settling. Pump a fixed window instead of pumpAndSettle.
Future<void> _pumpBriefly(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

/// The message picker sits below the fold in the push tab's lazy ListView, so
/// it is not built until it is scrolled into view.
Future<void> _scrollToPicker(WidgetTester tester) async {
  final list = find.byType(ListView).first;
  for (var i = 0; i < 20; i++) {
    if (tester.any(find.byIcon(Icons.edit_rounded))) return;
    await tester.drag(list, const Offset(0, -200));
    await tester.pumpAndSettle();
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('message editor is hidden while reminders are turned off', (
    tester,
  ) async {
    await tester.pumpWidget(_buildApp(notificationsOn: false));
    await tester.pumpAndSettle();

    expect(find.byType(DailyRemindersScreen), findsOneWidget);

    // The whole block is gated behind the notifications toggle, so nothing in
    // it exists in the tree yet.
    await _scrollToPicker(tester);
    expect(find.byIcon(Icons.edit_rounded), findsNothing);
    expect(find.byIcon(Icons.delete_outline_rounded), findsNothing);
  });

  testWidgets('the message editor is on screen once the reminder is enabled', (
    tester,
  ) async {
    await tester.pumpWidget(_buildApp(notificationsOn: true));
    await tester.pumpAndSettle();

    await _scrollToPicker(tester);

    // The editor card and its preset message list are visible.
    expect(find.text(AppStrings.en.reminderMessage), findsOneWidget);
    expect(find.byIcon(Icons.radio_button_off), findsWidgets);
  });

  testWidgets('tapping a preset message selects it', (tester) async {
    await tester.pumpWidget(_buildApp(notificationsOn: true));
    await tester.pumpAndSettle();

    await _scrollToPicker(tester);
    final firstPreset = AppStrings.en.reminderPresets.first;
    // .last targets the preset row (the editable display box above may show
    // the same text as the currently-selected message).
    await tester.ensureVisible(find.text(firstPreset).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text(firstPreset).last);
    await _pumpBriefly(tester);

    expect(find.byIcon(Icons.radio_button_checked), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tapping a different preset switches the selection', (
    tester,
  ) async {
    await tester.pumpWidget(_buildApp(notificationsOn: true));
    await tester.pumpAndSettle();

    await _scrollToPicker(tester);
    final presets = AppStrings.en.reminderPresets;
    await tester.ensureVisible(find.text(presets[0]).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text(presets[0]).last);
    await _pumpBriefly(tester);
    expect(find.byIcon(Icons.radio_button_checked), findsOneWidget);

    await tester.ensureVisible(find.text(presets[1]).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text(presets[1]).last);
    await _pumpBriefly(tester);

    // Still exactly one selected; the checked state moved to the new preset.
    expect(find.byIcon(Icons.radio_button_checked), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
