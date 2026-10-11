part of 'settings_cubit.dart';

class SettingsState extends Equatable {
  final ThemeMode themeMode;
  final bool notificationsEnabled;
  final TimeOfDay? notificationTime;
  final Set<int> repeatDays; // 1=Mon … 7=Sun, empty = every day
  final String reminderMessage;
  final String? userEmail;
  final bool isAuthenticated;
  final bool analyticsConsent;
  final String chatTheme; // ChatThemeId id
  final String chatFont; // ChatFontId id

  const SettingsState({
    this.themeMode = ThemeMode.light,
    this.notificationsEnabled = false,
    this.notificationTime,
    this.repeatDays = const {},
    this.reminderMessage = 'Time for your daily wellness check-in 🌿',
    this.userEmail,
    this.isAuthenticated = false,
    this.analyticsConsent = false,
    this.chatTheme = 'spring',
    this.chatFont = 'normal',
  });

  SettingsState copyWith({
    ThemeMode? themeMode,
    bool? notificationsEnabled,
    TimeOfDay? notificationTime,
    Set<int>? repeatDays,
    String? reminderMessage,
    String? userEmail,
    bool? isAuthenticated,
    bool? analyticsConsent,
    String? chatTheme,
    String? chatFont,
    bool clearUserEmail = false,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      notificationTime: notificationTime ?? this.notificationTime,
      repeatDays: repeatDays ?? this.repeatDays,
      reminderMessage: reminderMessage ?? this.reminderMessage,
      userEmail: clearUserEmail ? null : (userEmail ?? this.userEmail),
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      analyticsConsent: analyticsConsent ?? this.analyticsConsent,
      chatTheme: chatTheme ?? this.chatTheme,
      chatFont: chatFont ?? this.chatFont,
    );
  }

  /// Human-readable repeat label
  String get repeatLabel {
    if (repeatDays.isEmpty) return 'Every day';
    const names = {1: 'Mon', 2: 'Tue', 3: 'Wed', 4: 'Thu', 5: 'Fri', 6: 'Sat', 7: 'Sun'};
    final sorted = repeatDays.toList()..sort();
    if (sorted.length == 5 && !sorted.contains(6) && !sorted.contains(7)) {
      return 'Weekdays';
    }
    if (sorted.length == 2 && sorted.contains(6) && sorted.contains(7)) {
      return 'Weekends';
    }
    return sorted.map((d) => names[d]!).join(', ');
  }

  @override
  List<Object?> get props => [
        themeMode,
        notificationsEnabled,
        notificationTime,
        repeatDays,
        reminderMessage,
        userEmail,
        isAuthenticated,
        analyticsConsent,
        chatTheme,
        chatFont,
      ];
}
