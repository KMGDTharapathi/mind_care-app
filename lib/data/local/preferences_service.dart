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
  static const _keyChatServerUrl = 'chat_server_url';
  static const _keyGameMemoryBest = 'game_memory_best';
  static const _keyGameMemoryStars = 'game_memory_stars';
  static const _keyGameMinesBest = 'game_mines_best';
  static const _keyGameSudokuBest = 'game_sudoku_best';

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

  static Future<String?> getChatServerUrl() async {
    final prefs = await _get();
    return prefs.getString(_keyChatServerUrl);
  }

  static Future<void> setChatServerUrl(String url) async {
    final prefs = await _get();
    await prefs.setString(_keyChatServerUrl, url);
  }

  // ── Game scores & progress ─────────────────────────────────────────────────
  static Future<int> getGameMemoryBest() async =>
      (await _get()).getInt(_keyGameMemoryBest) ?? 0;

  static Future<void> setGameMemoryBest(int value) async {
    final prefs = await _get();
    if (value > (prefs.getInt(_keyGameMemoryBest) ?? 0)) {
      await prefs.setInt(_keyGameMemoryBest, value);
    }
  }

  static Future<String?> getGameMemoryStars() async =>
      (await _get()).getString(_keyGameMemoryStars);

  static Future<void> setGameMemoryStars(String value) async {
    final prefs = await _get();
    await prefs.setString(_keyGameMemoryStars, value);
  }

  static Future<int> getGameMinesBest() async =>
      (await _get()).getInt(_keyGameMinesBest) ?? 0;

  static Future<void> setGameMinesBest(int seconds) async {
    final prefs = await _get();
    final current = prefs.getInt(_keyGameMinesBest) ?? 0;
    if (current == 0 || seconds < current) {
      await prefs.setInt(_keyGameMinesBest, seconds);
    }
  }

  static Future<int> getGameSudokuBest() async =>
      (await _get()).getInt(_keyGameSudokuBest) ?? 0;

  static Future<void> setGameSudokuBest(int seconds) async {
    final prefs = await _get();
    final current = prefs.getInt(_keyGameSudokuBest) ?? 0;
    if (current == 0 || seconds < current) {
      await prefs.setInt(_keyGameSudokuBest, seconds);
    }
  }
}
