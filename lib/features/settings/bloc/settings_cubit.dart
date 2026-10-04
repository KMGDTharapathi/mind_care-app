import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mind_care_app/core/service_locator.dart';
import 'package:mind_care_app/data/local/notification_service.dart';
import 'package:mind_care_app/data/local/preferences_service.dart';
import 'package:mind_care_app/services/auth/auth_service.dart';

part 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit() : super(const SettingsState());

  /// Pushes the current settings bundle to the cloud so a re-login restores it.
  Future<void> pushSettings() async {
    final sync = ServiceLocator.syncService;
    if (sync == null) return;
    final prefs = await PreferencesService.getSharedPreferences();
    final userName = prefs.getString('user_name');
    final appLang = prefs.getString('app_language') ?? 'en';
    final time = state.notificationTime;
    await sync.enqueueSettings({
      'theme_mode': state.themeMode == ThemeMode.dark ? 'dark' : 'light',
      'chat_theme': state.chatTheme,
      'chat_font': state.chatFont,
      'notifications_enabled': state.notificationsEnabled,
      if (time != null)
        'notification_time':
            '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
      'repeat_days': state.repeatDays.toList(),
      'reminder_message': state.reminderMessage,
      if (userName != null && userName.isNotEmpty) 'user_name': userName,
      if (appLang.isNotEmpty) 'app_language': appLang,
    });
  }

  Future<void> loadSettings() async {
    final prefs = await PreferencesService.getSharedPreferences();
    final themeModeStr = prefs.getString('theme_mode') ?? 'light';
    // Reconcile the stored preference with the real OS permission so the
    // toggle never claims notifications are on when the OS has revoked access.
    final osAllowed = await NotificationService.areNotificationsEnabled();
    final notificationsEnabled = osAllowed
        ? (prefs.getBool('notifications_enabled') ?? false)
        : false;
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
      chatTheme: prefs.getString('chat_theme') ?? 'spring',
      chatFont: prefs.getString('chat_font') ?? 'normal',
    ));
  }

  Future<void> setChatTheme(String themeId) async {
    final prefs = await PreferencesService.getSharedPreferences();
    await prefs.setString('chat_theme', themeId);
    emit(state.copyWith(chatTheme: themeId));
    await pushSettings();
  }

  Future<void> setChatFont(String fontId) async {
    final prefs = await PreferencesService.getSharedPreferences();
    await prefs.setString('chat_font', fontId);
    emit(state.copyWith(chatFont: fontId));
    await pushSettings();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await PreferencesService.setThemeMode(
        mode == ThemeMode.dark ? 'dark' : 'light');
    emit(state.copyWith(themeMode: mode));
    await pushSettings();
  }

  Future<bool> setNotificationsEnabled(
    bool enabled, {
    Future<bool> Function()? onShowExplanation,
    VoidCallback? onPermissionDenied,
  }) async {
    if (!enabled) {
      await NotificationService.cancelAll();
      await PreferencesService.setNotificationsEnabled(false);
      emit(state.copyWith(notificationsEnabled: false));
      await pushSettings();
      return true;
    }

    // Already granted at the OS level? Enable without prompting the user.
    if (await NotificationService.areNotificationsEnabled()) {
      await PreferencesService.setNotificationsEnabled(true);
      emit(state.copyWith(notificationsEnabled: true));
      await _reschedule();
      await pushSettings();
      return true;
    }

    // Not granted yet — explain why, then ask the OS for permission.
    if (onShowExplanation != null) {
      final proceed = await onShowExplanation();
      if (!proceed) return false;
    }

    final granted = await NotificationService.requestPermissions();
    if (!granted) {
      // The system dialog was dismissed/denied (possibly permanently).
      // Notify the UI so it can point the user to the OS settings.
      onPermissionDenied?.call();
      return false;
    }

    await PreferencesService.setNotificationsEnabled(true);
    emit(state.copyWith(notificationsEnabled: true));
    await _reschedule();
    await pushSettings();
    return true;
  }

  Future<void> setNotificationTime(TimeOfDay time) async {
    final timeStr =
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    await PreferencesService.setNotificationTime(timeStr);
    emit(state.copyWith(notificationTime: time));
    if (state.notificationsEnabled) await _reschedule();
    await pushSettings();
  }

  Future<void> setRepeatDays(Set<int> days) async {
    final prefs = await PreferencesService.getSharedPreferences();
    await prefs.setStringList(
        'repeat_days', days.map((d) => d.toString()).toList());
    emit(state.copyWith(repeatDays: days));
    if (state.notificationsEnabled) await _reschedule();
    await pushSettings();
  }

  Future<void> setReminderMessage(String message) async {
    final prefs = await PreferencesService.getSharedPreferences();
    await prefs.setString('reminder_message', message);
    emit(state.copyWith(reminderMessage: message));
    if (state.notificationsEnabled) await _reschedule();
    await pushSettings();
  }

  Future<void> _reschedule() async {
    try {
      await NotificationService.cancelAll();
      final time = state.notificationTime ?? const TimeOfDay(hour: 9, minute: 0);
      await NotificationService.scheduleReminder(
        time: time,
        repeatDays: state.repeatDays,
        message: state.reminderMessage,
      );
    } catch (e) {
      debugPrint('Reminder reschedule failed: $e');
    }
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
