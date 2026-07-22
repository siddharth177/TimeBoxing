import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

abstract final class NotificationIds {
  /// Block reminders use `blockId.hashCode.abs() % 100000` (range 0–99999).
  static const insightReady = 900001;
  static const streakWarning = 900002;
  static const weeklyDigest = 900003;
}

class NotificationService {
  NotificationService._();

  static final _plugin = FlutterLocalNotificationsPlugin();

  static const _channelId = 'timebox_reminders';
  static const _channelName = 'Task Reminders';
  static const _channelDesc = 'Reminders for your scheduled time blocks';

  static Future<void> init() async {
    if (kIsWeb) return;
    tz_data.initializeTimeZones();
    final tzInfo = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(tzInfo.identifier));

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false, // ask explicitly via requestPermissions()
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      settings: const InitializationSettings(android: android, iOS: ios),
    );
  }

  static Future<bool> requestPermissions() async {
    if (kIsWeb) return false;
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final iosGranted =
        await ios?.requestPermissions(alert: true, badge: true, sound: true) ??
        false;
    final androidGranted =
        await android?.requestNotificationsPermission() ?? false;
    return iosGranted || androidGranted;
  }

  static Future<void> scheduleBlockReminder({
    required String blockId,
    required String title,
    required DateTime startTime,
    int minutesBefore = 0,
  }) async {
    if (kIsWeb) return;
    final notifyAt = startTime.subtract(Duration(minutes: minutesBefore));
    if (notifyAt.isBefore(DateTime.now())) return;

    final id = blockId.hashCode.abs() % 100000;
    final body = minutesBefore == 0
        ? '"$title" starts now'
        : '"$title" starts in ${minutesBefore}m';

    await _plugin.zonedSchedule(
      id: id,
      title: '⏱ TimeBox',
      body: body,
      scheduledDate: tz.TZDateTime.from(notifyAt, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  static Future<void> showNow({
    required int id,
    required String title,
    required String body,
  }) async {
    if (kIsWeb) return;
    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  static Future<void> cancelBlock(String blockId) async {
    if (kIsWeb) return;
    await _plugin.cancel(id: blockId.hashCode.abs() % 100000);
  }

  static Future<void> cancelAll() async {
    if (kIsWeb) return;
    await _plugin.cancelAll();
  }

  static Future<void> scheduleStreakWarning({int streak = 0}) async {
    if (kIsWeb) return;
    final body = streak > 0
        ? "Don't break your $streak-day streak! Log today's review."
        : "Log today's review to start a streak!";
    await _plugin.zonedSchedule(
      id: NotificationIds.streakWarning,
      title: '🔥 TimeBox Review',
      body: body,
      scheduledDate: _nextInstanceOfTime(21, 0),
      notificationDetails: _notifDetails(),
      androidScheduleMode: AndroidScheduleMode.inexact,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static Future<void> cancelStreakWarning() async {
    if (kIsWeb) return;
    await _plugin.cancel(id: NotificationIds.streakWarning);
  }

  static Future<void> scheduleWeeklyDigest() async {
    if (kIsWeb) return;
    await _plugin.zonedSchedule(
      id: NotificationIds.weeklyDigest,
      title: '📊 Your week in TimeBox',
      body: 'How did your week go? Tap to see your completion rate and streak.',
      scheduledDate: _nextInstanceOfWeekday(DateTime.sunday, 20, 0),
      notificationDetails: _notifDetails(),
      androidScheduleMode: AndroidScheduleMode.inexact,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  static NotificationDetails _notifDetails() => const NotificationDetails(
    android: AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(),
  );

  static tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduled.isBefore(now))
      scheduled = scheduled.add(const Duration(days: 1));
    return scheduled;
  }

  static tz.TZDateTime _nextInstanceOfWeekday(
    int weekday,
    int hour,
    int minute,
  ) {
    var scheduled = _nextInstanceOfTime(hour, minute);
    while (scheduled.weekday != weekday) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
