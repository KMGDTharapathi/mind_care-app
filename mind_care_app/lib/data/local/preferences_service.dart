import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const _keyOnboardingComplete = 'onboarding_complete';
  static const _keyThemeMode = 'theme_mode';
  static const _keyNotificationsEnabled = 'notifications_enabled';
  static const _keyNotificationTime = 'notification_time';
  static const _keyStreakCount = 'streak_count';
  static const _keyLastActiveDate = 'last_active_date';
  static const _keyUserName = 'user_name';
  static const _keyAppLanguage = 'app_language';
  static const _keyUserId = 'user_id';

  // Cached instance — avoids repeated platform channel calls on every read/write
  static SharedPreferences? _prefs;
  static Future<SharedPreferences> _get() async =>
      _prefs ??= await SharedPreferences.getInstance();

  /// Pre-warms the SharedPreferences cache. Call once at startup (before
  /// any other PreferencesService method) so all subsequent reads are
  /// synchronous cache hits and never block the main isolate.
  static Future<void> warmUp() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Exposes the cached [SharedPreferences] instance for use by other services.
  static Future<SharedPreferences> getSharedPreferences() => _get();

  static Future<bool> isOnboardingComplete() async {
    final prefs = await _get();
    return prefs.getBool(_keyOnboardingComplete) ?? false;
  }

  static Future<void> setOnboardingComplete(bool value) async {
    final prefs = await _get();
    await prefs.setBool(_keyOnboardingComplete, value);
  }

  static Future<String> getThemeMode() async {
    final prefs = await _get();
    return prefs.getString(_keyThemeMode) ?? 'light';
  }

  static Future<void> setThemeMode(String mode) async {
    final prefs = await _get();
    await prefs.setString(_keyThemeMode, mode);
  }

  static Future<bool> isNotificationsEnabled() async {
    final prefs = await _get();
    return prefs.getBool(_keyNotificationsEnabled) ?? false;
  }

  static Future<void> setNotificationsEnabled(bool value) async {
    final prefs = await _get();
    await prefs.setBool(_keyNotificationsEnabled, value);
  }

  static Future<String?> getNotificationTime() async {
    final prefs = await _get();
    return prefs.getString(_keyNotificationTime);
  }

  static Future<void> setNotificationTime(String time) async {
    final prefs = await _get();
    await prefs.setString(_keyNotificationTime, time);
  }

  static Future<int> getStreakCount() async {
    final prefs = await _get();
    return prefs.getInt(_keyStreakCount) ?? 0;
  }

  static Future<void> setStreakCount(int count) async {
    final prefs = await _get();
    await prefs.setInt(_keyStreakCount, count);
  }

  static Future<String?> getLastActiveDate() async {
    final prefs = await _get();
    return prefs.getString(_keyLastActiveDate);
  }

  static Future<void> setLastActiveDate(String date) async {
    final prefs = await _get();
    await prefs.setString(_keyLastActiveDate, date);
  }

  static Future<String?> getUserName() async {
    final prefs = await _get();
    return prefs.getString(_keyUserName);
  }

  static Future<void> setUserName(String name) async {
    final prefs = await _get();
    await prefs.setString(_keyUserName, name);
  }

  static Future<String?> getAppLanguage() async {
    final prefs = await _get();
    return prefs.getString(_keyAppLanguage);
  }

  static Future<void> setAppLanguage(String lang) async {
    final prefs = await _get();
    await prefs.setString(_keyAppLanguage, lang);
  }

  static Future<String?> getUserId() async {
    final prefs = await _get();
    return prefs.getString(_keyUserId);
  }

  static Future<void> setUserId(String id) async {
    final prefs = await _get();
    await prefs.setString(_keyUserId, id);
  }
}
