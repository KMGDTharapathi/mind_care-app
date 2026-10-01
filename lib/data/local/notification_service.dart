import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:go_router/go_router.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:url_launcher/url_launcher.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

/// Callbacks invoked from the now-playing notification's media controls.
class MediaPlayerHooks {
  VoidCallback? onPlayPause;
  VoidCallback? onNext;
  VoidCallback? onPrevious;
}

/// Global hooks wired up by the music player while it is active.
final MediaPlayerHooks mediaPlayerHooks = MediaPlayerHooks();

class NotificationService {
  static const _channelId = 'mindcare_daily';
  static const _channelName = 'Reminders';
  static const _baseId = 100; // IDs 100-106 for Mon-Sun

  // Music player notification
  static const _musicChannelId = 'mindcare_music';
  static const _musicChannelName = 'Now Playing';
  static const _nowPlayingId = 9001;

  // Calendar confirmation notification
  static const _calendarChannelId = 'mindcare_calendar';
  static const _calendarChannelName = 'Calendar';
  static const _calendarNotifId = 500;

  // Brand accent used to colorize reminders on Android.
  static const _accentColor = Color(0xFF5BA8A0);

  // Media action ids (matched against NotificationResponse.actionId)
  static const _actionPlayPause = 'media_play_pause';
  static const _actionNext = 'media_next';
  static const _actionPrevious = 'media_previous';

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

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await flutterLocalNotificationsPlugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Media controls take priority over plain taps.
        switch (response.actionId) {
          case _actionPlayPause:
            mediaPlayerHooks.onPlayPause?.call();
            return;
          case _actionNext:
            mediaPlayerHooks.onNext?.call();
            return;
          case _actionPrevious:
            mediaPlayerHooks.onPrevious?.call();
            return;
        }
        final context = navigatorKey.currentContext;
        if (context != null) GoRouter.of(context).go('/home');
      },
    );

    final androidPlugin = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId,
        _channelName,
        importance: Importance.high,
      ),
    );

    // A channel's importance is fixed once created: an earlier install created
    // 'mindcare_music' at LOW, and Android ignores later upgrades. Delete and
    // recreate it so a media notification actually surfaces (heads-up + shade).
    await androidPlugin?.deleteNotificationChannel(_musicChannelId);
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        _musicChannelId,
        _musicChannelName,
        description:
            'Controls the currently playing calm music from the notification shade',
        importance: Importance.high,
        enableVibration: false,
        playSound: false,
      ),
    );

    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        _calendarChannelId,
        _calendarChannelName,
        description: 'Confirms when a wellness event is added to your calendar',
        importance: Importance.high,
      ),
    );
  }

  /// Returns `true` when the OS-level notification permission is currently
  /// granted (or no permission is needed on the running platform).
  static Future<bool> areNotificationsEnabled() async {
    final androidPlugin = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidPlugin != null) {
      return await androidPlugin.areNotificationsEnabled() ?? false;
    }
    final iosPlugin = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (iosPlugin != null) {
      final opts = await iosPlugin.checkPermissions();
      return opts?.isEnabled ?? opts?.isProvisionalEnabled ?? false;
    }
    // Desktop / web: notifications are assumed to be allowed.
    return true;
  }

  /// Requests notification permission (Android 13+). Returns true when granted
  /// or not required. Unlike [requestPermissions] it does NOT prompt for exact
  /// alarms — used by the music player so its media notification can show.
  static Future<bool> requestMediaPermission() async {
    final androidPlugin = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidPlugin != null) {
      return await androidPlugin.requestNotificationsPermission() ?? false;
    }
    return true;
  }

  /// Opens the OS "app notification settings" page so the user can manually
  /// re-enable notifications after denying the permission dialog.
  static Future<bool> openNotificationsSettings() async {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return launchUrl(
        Uri.parse('package:${'com.example.mindcare_app'}'),
        mode: LaunchMode.externalApplication,
      );
    }
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      return launchUrl(
        Uri.parse('app-settings:'),
        mode: LaunchMode.externalApplication,
      );
    }
    return false;
  }

  static Future<bool> requestPermissions() async {
    final androidPlugin = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
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
          IOSFlutterLocalNotificationsPlugin
        >();
    if (iosPlugin != null) {
      return await iosPlugin.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }
    return true;
  }

  // ── Now-playing notification ──────────────────────────────────────────────

  /// Shows (or updates) the media notification for the active track.
  static Future<void> showNowPlaying({
    required String title,
    required String artist,
    bool isPlaying = true,
  }) async {
    final actionIcon = DrawableResourceAndroidBitmap('ic_stat_music');
    await flutterLocalNotificationsPlugin.show(
      _nowPlayingId,
      title,
      artist,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _musicChannelId,
          _musicChannelName,
          channelDescription: 'Shows the currently playing song with controls',
          importance: Importance.low,
          priority: Priority.low,
          playSound: false,
          enableVibration: false,
          showWhen: false,
          autoCancel: true,
          actions: [
            AndroidNotificationAction(
              _actionPrevious,
              'Previous',
              icon: actionIcon,
              showsUserInterface: false,
              cancelNotification: false,
            ),
            AndroidNotificationAction(
              _actionPlayPause,
              isPlaying ? 'Pause' : 'Play',
              icon: actionIcon,
              showsUserInterface: false,
              cancelNotification: false,
            ),
            AndroidNotificationAction(
              _actionNext,
              'Next',
              icon: actionIcon,
              showsUserInterface: false,
              cancelNotification: false,
            ),
          ],
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: 'now_playing',
    );
  }

  /// Removes the now-playing notification (call when playback stops).
  static Future<void> cancelNowPlaying() async {
    await flutterLocalNotificationsPlugin.cancel(_nowPlayingId);
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
          AndroidFlutterLocalNotificationsPlugin
        >();
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
              color: _accentColor,
              colorized: true,
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

  /// Shows a one-off confirmation that a wellness event was added to the
  /// user's chosen calendar (e.g. Google Calendar).
  static Future<void> showEventAddedNotification({
    required String eventTitle,
    required String provider,
  }) async {
    await flutterLocalNotificationsPlugin.show(
      _calendarNotifId,
      'MindCare 🌿',
      'Added "$eventTitle" to $provider',
      NotificationDetails(
        android: AndroidNotificationDetails(
          _calendarChannelId,
          _calendarChannelName,
          channelDescription:
              'Confirms when a wellness event is added to your calendar',
          importance: Importance.high,
          priority: Priority.high,
          color: const Color(0xFF7986CB),
          colorized: true,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  /// Returns the next [tz.TZDateTime] for the given weekday (1=Mon…7=Sun).
  static tz.TZDateTime _nextOccurrence(TimeOfDay time, int weekday) {
    final now = tz.TZDateTime.now(tz.local);
    // Dart weekday: 1=Mon…7=Sun — same as our convention
    var candidate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

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
