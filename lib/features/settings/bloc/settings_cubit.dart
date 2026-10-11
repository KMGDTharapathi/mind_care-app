import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mind_care_app/core/l10n/app_strings.dart';
import 'package:mind_care_app/data/local/notification_service.dart';
import 'package:mind_care_app/data/local/preferences_service.dart';
import 'package:mind_care_app/services/auth/auth_service.dart';

part 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit() : super(const SettingsState());

  Future<void> loadSettings() async {
    final prefs = await PreferencesService.getSharedPreferences();
    final themeModeStr = prefs.getString('theme_mode') ?? 'light';
    final notificationsEnabled =
        prefs.getBool('notifications_enabled') ?? false;
    final timeStr = prefs.getString('notification_time');
    final repeatList = prefs.getStringList('repeat_days') ?? [];
    final presetIndex =
        int.tryParse(prefs.getString('reminder_preset_index') ?? '');
    var message = prefs.getString('reminder_message');

    // A saved preset is tracked by index so the selected message survives a
    // language switch (preset texts are localized and would otherwise never
    // match in the other language). Re-derive the text in the saved language.
    if (presetIndex != null) {
      final lang = prefs.getString('app_language') ?? 'en';
      final presets = lang == 'si'
          ? AppStrings.si.reminderPresets
          : AppStrings.en.reminderPresets;
      if (presetIndex >= 0 && presetIndex < presets.length) {
        message = presets[presetIndex];
      }
    }
    message ??= 'Time for your daily wellness check-in 🌿';

    TimeOfDay? notificationTime;
    if (timeStr != null) {
      final parts = timeStr.split(':');
      if (parts.length == 2) {
        notificationTime = TimeOfDay(
          hour: int.tryParse(parts[0]) ?? 9,
          minute: int.tryParse(parts[1]) ?? 0,
        );
      }
    }

    emit(
      state.copyWith(
        themeMode: themeModeStr == 'dark' ? ThemeMode.dark : ThemeMode.light,
        notificationsEnabled: notificationsEnabled,
        notificationTime: notificationTime,
        repeatDays: repeatList.map((e) => int.tryParse(e) ?? 0).toSet()
          ..remove(0),
        reminderMessage: message,
        reminderPresetIndex: presetIndex,
      ),
    );
    unawaited(_syncReminderToFirestore());
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await PreferencesService.setThemeMode(
      mode == ThemeMode.dark ? 'dark' : 'light',
    );
    emit(state.copyWith(themeMode: mode));
  }

  Future<bool> setNotificationsEnabled(
    bool enabled, {
    Future<bool> Function()? onShowExplanation,
  }) async {
    if (enabled) {
      if (onShowExplanation != null) {
        final proceed = await onShowExplanation();
        if (!proceed) return false;
      }
      final granted = await NotificationService.requestPermissions();
      if (!granted) return false;

      await PreferencesService.setNotificationsEnabled(true);
      emit(state.copyWith(notificationsEnabled: true));
      await _reschedule();
      unawaited(_syncReminderToFirestore());
      return true;
    } else {
      await NotificationService.cancelAll();
      await PreferencesService.setNotificationsEnabled(false);
      emit(state.copyWith(notificationsEnabled: false));
      unawaited(_syncReminderToFirestore());
      return true;
    }
  }

  Future<void> setNotificationTime(TimeOfDay time) async {
    final timeStr =
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    await PreferencesService.setNotificationTime(timeStr);
    emit(state.copyWith(notificationTime: time));
    if (state.notificationsEnabled) await _reschedule();
    unawaited(_syncReminderToFirestore());
  }

  Future<void> setRepeatDays(Set<int> days) async {
    final prefs = await PreferencesService.getSharedPreferences();
    await prefs.setStringList(
      'repeat_days',
      days.map((d) => d.toString()).toList(),
    );
    emit(state.copyWith(repeatDays: days));
    if (state.notificationsEnabled) await _reschedule();
    unawaited(_syncReminderToFirestore());
  }

  Future<void> setReminderMessage(String message, {int? presetIndex}) async {
    final prefs = await PreferencesService.getSharedPreferences();
    await prefs.setString('reminder_message', message);
    if (presetIndex != null) {
      await prefs.setString('reminder_preset_index', presetIndex.toString());
    } else {
      // A custom (user-typed) message is not tied to a localized preset, so
      // clear the stored index to stop it being overwritten on the next load.
      await prefs.remove('reminder_preset_index');
    }
    emit(
      state.copyWith(
        reminderMessage: message,
        reminderPresetIndex: presetIndex,
        clearReminderPresetIndex: presetIndex == null,
      ),
    );
    if (state.notificationsEnabled) await _reschedule();
    unawaited(_syncReminderToFirestore());
  }

  Future<void> _reschedule() async {
    await NotificationService.cancelAll();
    final time = state.notificationTime ?? const TimeOfDay(hour: 9, minute: 0);
    await NotificationService.scheduleReminder(
      time: time,
      repeatDays: state.repeatDays,
      message: state.reminderMessage,
    );
  }

  /// Syncs current reminder preferences to Firebase Firestore under the user's document.
  Future<void> _syncReminderToFirestore() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final uid = user?.uid ?? await PreferencesService.getUserId();
      if (uid == null || uid.isEmpty) return;

      final time = state.notificationTime ?? const TimeOfDay(hour: 9, minute: 0);
      final timeStr =
          '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

      final reminderData = {
        'reminderEnabled': state.notificationsEnabled,
        'reminderTime': timeStr,
        'reminderRepeatDays': state.repeatDays.toList(),
        'reminderMessage': state.reminderMessage,
        'reminderUpdatedAt': FieldValue.serverTimestamp(),
      };

      // 1. Update the main user document directly (users/{uid}) so it shows in the Firestore Console table
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set(reminderData, SetOptions(merge: true));

      // 2. Also keep settings/preferences subcollection in sync
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('settings')
          .doc('preferences')
          .set(reminderData, SetOptions(merge: true));
    } catch (e) {
      debugPrint('SettingsCubit: Reminder sync to Firestore failed (non-fatal): $e');
    }
  }

  void updateAuthState(AuthUser? user) {
    if (user == null || user.isAnonymous) {
      emit(state.copyWith(isAuthenticated: false, clearUserEmail: true));
    } else {
      emit(state.copyWith(isAuthenticated: true, userEmail: user.email));
      unawaited(_syncReminderToFirestore());
    }
  }

  void updateAnalyticsConsent(bool value) {
    emit(state.copyWith(analyticsConsent: value));
  }
}
