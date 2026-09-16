import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:go_router/go_router.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

class NotificationService {
  static const _channelId = 'mindcare_daily';
  static const _channelName = 'Reminders';
  static const _baseId = 100; // IDs 100-106 for Mon-Sun

  static Future<void> init({
    required GlobalKey<NavigatorState> navigatorKey,
  }) async {
    // Resolve the device timezone so tz.local is NOT left at the UTC default.
    // Retry a few times: the platform channel may not be ready on cold start.
    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        tz.initializeTimeZones();
        final tzName = await FlutterTimezone.getLocalTimezone();
        tz.setLocalLocation(tz.getLocation(tzName));
        break;
      } catch (e) {
        debugPrint('Timezone init failed: $e');
        if (attempt == 2) break;
        await Future<void>.delayed(const Duration(milliseconds: 200));
      }
    }

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await flutterLocalNotificationsPlugin.initialize(
      const InitializationSettings(
          android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        final context = navigatorKey.currentContext;
        if (context != null) GoRouter.of(context).go('/home');
      },
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(const AndroidNotificationChannel(
          _channelId,
          _channelName,
          importance: Importance.high,
        ));
  }

  static Future<bool> requestPermissions() async {
    final androidPlugin = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      final granted =
          await androidPlugin.requestNotificationsPermission() ?? false;
      if (!granted) return false;

      // Android 12+ requires a separate exact-alarm permission. On Android 14+
      // it is denied by default, so scheduling with exactAllowWhileIdle without
      // it throws. Request it here so reminders actually fire on time.
      if (!(await androidPlugin.canScheduleExactNotifications() ?? false)) {
        await androidPlugin.requestExactAlarmsPermission();
      }
      return true;
    }
    final iosPlugin = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    if (iosPlugin != null) {
      return await iosPlugin.requestPermissions(
              alert: true, badge: true, sound: true) ??
          false;
    }
    return true;
  }

  /// Schedule reminders.
  /// [repeatDays] empty = every day (1=Mon … 7=Sun).
  static Future<void> scheduleReminder({
    required TimeOfDay time,
    Set<int> repeatDays = const {},
    String message = 'Time for your daily wellness check-in 🌿',
  }) async {
    await cancelAll();

    // Choose scheduling mode up front: exact alarms need a separate permission
    // (denied by default since Android 14). Fall back to inexact if unavailable
    // so reminders still fire — just possibly a few minutes late.
    final androidPlugin = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    final canScheduleExact =
        await androidPlugin?.canScheduleExactNotifications() ?? false;
    final scheduleMode = canScheduleExact
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;

    final days = repeatDays.isEmpty ? {1, 2, 3, 4, 5, 6, 7} : repeatDays;

    for (final day in days) {
      final notifId = _baseId + day;
      final scheduledDate = _nextOccurrence(time, day);

      // Map 1-7 to Day enum
      final dayComponent = _dayComponent(day);

      try {
        await flutterLocalNotificationsPlugin.zonedSchedule(
          notifId,
          'MindCare 🌿',
          message,
          scheduledDate,
          NotificationDetails(
            android: AndroidNotificationDetails(
              _channelId,
              _channelName,
              importance: Importance.high,
              priority: Priority.high,
              styleInformation: BigTextStyleInformation(message),
            ),
            iOS: const DarwinNotificationDetails(),
          ),
          androidScheduleMode: scheduleMode,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: dayComponent,
        );
      } catch (e) {
        debugPrint('Failed to schedule reminder for day $day: $e');
      }
    }
  }

  /// Legacy alias kept for compatibility.
  static Future<void> scheduleDailyNotification(TimeOfDay time) =>
      scheduleReminder(time: time);

  static Future<void> cancelAll() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  /// Returns the next [tz.TZDateTime] for the given weekday (1=Mon…7=Sun).
  static tz.TZDateTime _nextOccurrence(TimeOfDay time, int weekday) {
    final now = tz.TZDateTime.now(tz.local);
    // Dart weekday: 1=Mon…7=Sun — same as our convention
    var candidate = tz.TZDateTime(
        tz.local, now.year, now.month, now.day, time.hour, time.minute);

    // Advance until we hit the right weekday
    while (candidate.weekday != weekday || candidate.isBefore(now)) {
      candidate = candidate.add(const Duration(days: 1));
    }
    return candidate;
  }

  /// Maps weekday int to [DateTimeComponents] for weekly repeat.
  static DateTimeComponents _dayComponent(int weekday) {
    // We always use weekly repeat per day so the notification fires
    // on the same weekday every week.
    return DateTimeComponents.dayOfWeekAndTime;
  }
}
