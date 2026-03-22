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
      settings: const InitializationSettings(
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

  /// Public method to request notification permissions on demand (e.g. from settings).
  static Future<bool> requestPermissions() async {
    await _requestPermissions();
    // Check if the permission was actually granted after requesting
    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl != null) {
      final granted = await androidImpl.areNotificationsEnabled();
      return granted ?? false;
    }
    // On iOS permissions are handled by the OS dialog; assume granted if no error
    return true;
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
      id: 100,
      title: 'Membership Expiring Soon',
      body: 'Your $gymName membership expires in 7 days. Renew now to keep access.',
      scheduledDate: tz.TZDateTime.from(warningDate, tz.local),
      notificationDetails: const NotificationDetails(android: _membershipChannel),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
    debugPrint('[Notifications] Membership expiry scheduled for $warningDate');
  }

  // ─── Daily Hydration Reminder ──────────────────────────────────────────────
  
  /// Schedules a daily water reminder at 10 AM.
  /// If [conditionMet] is true, we cancel the reminder for today and schedule for tomorrow.
  static Future<void> scheduleDailyHydrationReminder({
    bool conditionMet = false,
  }) async {
    const reminderId = 200;
    await _plugin.cancel(id: reminderId);

    if (conditionMet) {
      debugPrint('[Notifications] Hydration goal met for today; suppressing 10 AM push.');
      // Still schedule ahead for tomorrow (recurring daily)
      // Actually, if it's recurring, it will fire tomorrow anyway. 
      // But if we cancel it today, we should RE-SCHEDULE it starting tomorrow.
      final tomorrow = tz.TZDateTime.now(tz.local).add(const Duration(days: 1));
      final scheduled = tz.TZDateTime(tz.local, tomorrow.year, tomorrow.month, tomorrow.day, 10);
      
      await _plugin.zonedSchedule(
        id: reminderId,
        title: 'Stay Hydrated!',
        body: "Don't forget to drink water. Keep your hydration goal on track!",
        scheduledDate: scheduled,
        notificationDetails: const NotificationDetails(android: _hydrationChannel),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      return;
    }

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, 10);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      id: reminderId,
      title: 'Stay Hydrated!',
      body: "Don't forget to drink water. Your goal is still pending!",
      scheduledDate: scheduled,
      notificationDetails: const NotificationDetails(android: _hydrationChannel),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
    debugPrint('[Notifications] Daily hydration reminder scheduled at 10 AM');
  }

  // ─── Workout Reminder ──────────────────────────────────────────────────────

  /// Schedules a daily workout reminder at [hour]:[minute].
  static Future<void> scheduleWorkoutReminder({
    int hour = 18,
    int minute = 0,
    bool enabled = true,
  }) async {
    const reminderId = 300;
    await _plugin.cancel(id: reminderId);
    
    if (!enabled) {
      debugPrint('[Notifications] Workout reminders are disabled.');
      return;
    }

    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      id: reminderId,
      title: 'Time to Work Out!',
      body: 'Your workout session is waiting. Stay consistent!',
      scheduledDate: scheduled,
      notificationDetails: const NotificationDetails(android: _workoutChannel),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
    debugPrint('[Notifications] Workout reminder scheduled at $hour:$minute');
  }

  // ─── Cancel ────────────────────────────────────────────────────────────────
  static Future<void> cancelAll() => _plugin.cancelAll();
  static Future<void> cancelMembershipReminder() => _plugin.cancel(id: 100);
  static Future<void> cancelHydrationReminder() => _plugin.cancel(id: 200);
  static Future<void> cancelWorkoutReminder() => _plugin.cancel(id: 300);
}
