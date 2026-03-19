// lib/services/notification_service.dart
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

final _plugin = FlutterLocalNotificationsPlugin();

class NotificationService {
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    tz.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
      ),
    );

    await _requestPermissions();

    // Schedule static daily reminders
    await scheduleDailyHydrationReminder();
    await scheduleWorkoutReminder();
  }

  static Future<void> _requestPermissions() async {
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  // ─── Channels ──────────────────────────────────────────────────────────────

  static const _membershipChannel = AndroidNotificationDetails(
    'membership_expiry',
    'Membership Expiry',
    channelDescription: 'Alerts before membership expires',
    importance: Importance.high,
    priority: Priority.high,
    icon: '@mipmap/ic_launcher',
  );

  static const _hydrationChannel = AndroidNotificationDetails(
    'hydration_reminder',
    'Hydration Reminder',
    channelDescription: 'Daily water intake reminders',
    importance: Importance.defaultImportance,
    priority: Priority.defaultPriority,
    icon: '@mipmap/ic_launcher',
  );

  static const _workoutChannel = AndroidNotificationDetails(
    'workout_reminder',
    'Workout Reminder',
    channelDescription: 'Daily workout reminders',
    importance: Importance.high,
    priority: Priority.high,
    icon: '@mipmap/ic_launcher',
  );

  // ─── Membership Expiry ─────────────────────────────────────────────────────

  /// Schedules a membership expiry warning 7 days before [expiryDate].
  static Future<void> scheduleMembershipExpiryWarning({
    required DateTime expiryDate,
    required String gymName,
  }) async {
    final warningDate = expiryDate.subtract(const Duration(days: 7));
    if (warningDate.isBefore(DateTime.now())) return;

    await _plugin.zonedSchedule(
      100,
      'Membership Expiring Soon',
      'Your $gymName membership expires in 7 days. Renew now to keep access.',
      tz.TZDateTime.from(warningDate, tz.local),
      const NotificationDetails(android: _membershipChannel),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
    debugPrint('[Notifications] Membership expiry scheduled for $warningDate');
  }

  // ─── Daily Hydration Reminder ──────────────────────────────────────────────

  /// Schedules a daily water reminder at 10 AM.
  static Future<void> scheduleDailyHydrationReminder() async {
    await _plugin.cancel(200);

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, 10);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      200,
      'Stay Hydrated!',
      "Don't forget to drink water. Track your hydration in FitNexora.",
      scheduled,
      const NotificationDetails(android: _hydrationChannel),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
    debugPrint('[Notifications] Daily hydration reminder scheduled at 10 AM');
  }

  // ─── Workout Reminder ──────────────────────────────────────────────────────

  /// Schedules a daily workout reminder at [hour]:[minute].
  static Future<void> scheduleWorkoutReminder({
    int hour = 18,
    int minute = 0,
  }) async {
    await _plugin.cancel(300);

    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      300,
      'Time to Work Out!',
      'Your workout session is waiting. Keep the streak going!',
      scheduled,
      const NotificationDetails(android: _workoutChannel),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
    debugPrint('[Notifications] Workout reminder scheduled at $hour:$minute');
  }

  // ─── Cancel ────────────────────────────────────────────────────────────────

  static Future<void> cancelAll() => _plugin.cancelAll();

  static Future<void> cancelMembershipReminder() => _plugin.cancel(100);
  static Future<void> cancelHydrationReminder() => _plugin.cancel(200);
  static Future<void> cancelWorkoutReminder() => _plugin.cancel(300);
}
