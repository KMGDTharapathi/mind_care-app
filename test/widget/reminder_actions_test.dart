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

  testWidgets('edit and delete are visible without any prior tap once the '
      'reminder is enabled', (tester) async {
    await tester.pumpWidget(_buildApp(notificationsOn: true));
    await tester.pumpAndSettle();

    await _scrollToPicker(tester);

    // These used to require tapping the message row first, so they read as
    // missing. They must already be on screen.
    expect(find.byIcon(Icons.edit_rounded), findsOneWidget);
    expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);
  });

  testWidgets('tapping edit reveals the save button', (tester) async {
    await tester.pumpWidget(_buildApp(notificationsOn: true));
    await tester.pumpAndSettle();

    await _scrollToPicker(tester);
    await tester.ensureVisible(find.byIcon(Icons.edit_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.edit_rounded));
    await _pumpBriefly(tester);

    expect(find.byIcon(Icons.save_rounded), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'tapping delete enters the editor so the message can be retyped',
    (tester) async {
      await tester.pumpWidget(_buildApp(notificationsOn: true));
      await tester.pumpAndSettle();

      await _scrollToPicker(tester);
      await tester.ensureVisible(find.byIcon(Icons.delete_outline_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.delete_outline_rounded));
      await _pumpBriefly(tester);

      expect(find.byIcon(Icons.save_rounded), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
