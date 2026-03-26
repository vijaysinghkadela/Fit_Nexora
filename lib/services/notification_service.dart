import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin
      _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  static bool _isInitialized = false;

  static Future<void> init() async {
    if (_isInitialized) return;

    tz.initializeTimeZones();
    try {
      final String timeZoneName = DateTime.now().timeZoneName;
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      debugPrint('Could not set local timezone: $e');
    }

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('Notification clicked: ${response.payload}');
      },
    );

    _isInitialized = true;
  }

  static Future<bool> requestPermissions() async {
    bool? result = false;
    if (Platform.isIOS) {
      result = await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
    } else if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _flutterLocalNotificationsPlugin
              .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin>();

      result = await androidImplementation?.requestNotificationsPermission();
      await androidImplementation?.requestExactAlarmsPermission();
    }
    return result ?? false;
  }

  static Future<void> scheduleMembershipExpiryWarning({
    required DateTime expiryDate,
    required String gymName,
  }) async {
    final warningDate = expiryDate.subtract(const Duration(days: 7));
    if (warningDate.isBefore(DateTime.now())) return;

    await _scheduleNotification(
      id: 1001,
      title: 'Membership Expiring Soon',
      body: 'Your gym membership at $gymName expires in 7 days. Renew now!',
      scheduledDate: warningDate,
    );
  }

  static Future<void> scheduleDailyHydrationReminder({
    required bool conditionMet,
  }) async {
    if (conditionMet) {
      await cancelHydrationReminder();
      return;
    }

    await _scheduleDailyNotification(
      id: 1002,
      title: 'Hydration Check 💧',
      body: 'Time to drink some water! Keep your hydration levels up.',
      hour: 10,
      minute: 0,
    );
  }

  static Future<void> cancelHydrationReminder() async {
    await _flutterLocalNotificationsPlugin.cancel(id: 1002);
  }

  static Future<void> scheduleWorkoutReminder({
    required int hour,
    required int minute,
    bool enabled = true,
  }) async {
    if (!enabled) {
      await _flutterLocalNotificationsPlugin.cancel(id: 1003);
      return;
    }
    await _scheduleDailyNotification(
      id: 1003,
      title: 'Workout Time 💪',
      body: 'It\'s time for your daily workout. Let\'s crush those goals!',
      hour: hour,
      minute: minute,
    );
  }

  static Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    final tz.TZDateTime tzDate = tz.TZDateTime.from(scheduledDate, tz.local);

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tzDate,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'gymos_ai_reminders',
          'Reminders',
          channelDescription: 'Important reminders',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  static Future<void> _scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'gymos_ai_daily_reminders',
          'Daily Reminders',
          channelDescription: 'Daily reminders',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }
}
