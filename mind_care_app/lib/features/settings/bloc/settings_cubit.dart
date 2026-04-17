import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mind_care_app/data/local/notification_service.dart';
import 'package:mind_care_app/data/local/preferences_service.dart';
import 'package:mind_care_app/services/auth/auth_service.dart';

part 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit() : super(const SettingsState());

  Future<void> loadSettings() async {
    final prefs = await PreferencesService.getSharedPreferences();
    final themeModeStr = prefs.getString('theme_mode') ?? 'light';
    final notificationsEnabled = prefs.getBool('notifications_enabled') ?? false;
    final timeStr = prefs.getString('notification_time');
    final repeatList = prefs.getStringList('repeat_days') ?? [];
    final message = prefs.getString('reminder_message') ??
        'Time for your daily wellness check-in 🌿';

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

    emit(state.copyWith(
      themeMode: themeModeStr == 'dark' ? ThemeMode.dark : ThemeMode.light,
      notificationsEnabled: notificationsEnabled,
      notificationTime: notificationTime,
      repeatDays: repeatList.map((e) => int.tryParse(e) ?? 0).toSet()
        ..remove(0),
      reminderMessage: message,
    ));
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await PreferencesService.setThemeMode(
        mode == ThemeMode.dark ? 'dark' : 'light');
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
      return true;
    } else {
      await NotificationService.cancelAll();
      await PreferencesService.setNotificationsEnabled(false);
      emit(state.copyWith(notificationsEnabled: false));
      return true;
    }
  }

  Future<void> setNotificationTime(TimeOfDay time) async {
    final timeStr =
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    await PreferencesService.setNotificationTime(timeStr);
    emit(state.copyWith(notificationTime: time));
    if (state.notificationsEnabled) await _reschedule();
  }

  Future<void> setRepeatDays(Set<int> days) async {
    final prefs = await PreferencesService.getSharedPreferences();
    await prefs.setStringList(
        'repeat_days', days.map((d) => d.toString()).toList());
    emit(state.copyWith(repeatDays: days));
    if (state.notificationsEnabled) await _reschedule();
  }

  Future<void> setReminderMessage(String message) async {
    final prefs = await PreferencesService.getSharedPreferences();
    await prefs.setString('reminder_message', message);
    emit(state.copyWith(reminderMessage: message));
    if (state.notificationsEnabled) await _reschedule();
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

  void updateAuthState(AuthUser? user) {
    if (user == null || user.isAnonymous) {
      emit(state.copyWith(isAuthenticated: false, clearUserEmail: true));
    } else {
      emit(state.copyWith(isAuthenticated: true, userEmail: user.email));
    }
  }

  void updateAnalyticsConsent(bool value) {
    emit(state.copyWith(analyticsConsent: value));
  }
}
