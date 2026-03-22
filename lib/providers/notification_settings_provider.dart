import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationSettings {
  final bool hydrationEnabled;
  final bool workoutEnabled;
  final TimeOfDay workoutTime;

  const NotificationSettings({
    this.hydrationEnabled = true,
    this.workoutEnabled = true,
    this.workoutTime = const TimeOfDay(hour: 18, minute: 0),
  });

  NotificationSettings copyWith({
    bool? hydrationEnabled,
    bool? workoutEnabled,
    TimeOfDay? workoutTime,
  }) {
    return NotificationSettings(
      hydrationEnabled: hydrationEnabled ?? this.hydrationEnabled,
      workoutEnabled: workoutEnabled ?? this.workoutEnabled,
      workoutTime: workoutTime ?? this.workoutTime,
    );
  }
}

class NotificationSettingsNotifier extends StateNotifier<NotificationSettings> {
  NotificationSettingsNotifier() : super(const NotificationSettings()) {
    _loadSettings();
  }

  static const _kHydrationKey = 'notif_hydration_enabled';
  static const _kWorkoutEnabledKey = 'notif_workout_enabled';
  static const _kWorkoutHourKey = 'notif_workout_hour';
  static const _kWorkoutMinuteKey = 'notif_workout_minute';

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    state = NotificationSettings(
      hydrationEnabled: prefs.getBool(_kHydrationKey) ?? true,
      workoutEnabled: prefs.getBool(_kWorkoutEnabledKey) ?? true,
      workoutTime: TimeOfDay(
        hour: prefs.getInt(_kWorkoutHourKey) ?? 18,
        minute: prefs.getInt(_kWorkoutMinuteKey) ?? 0,
      ),
    );
  }

  Future<void> setHydrationEnabled(bool enabled) async {
    state = state.copyWith(hydrationEnabled: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kHydrationKey, enabled);
  }

  Future<void> setWorkoutEnabled(bool enabled) async {
    state = state.copyWith(workoutEnabled: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kWorkoutEnabledKey, enabled);
  }

  Future<void> setWorkoutTime(TimeOfDay time) async {
    state = state.copyWith(workoutTime: time);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kWorkoutHourKey, time.hour);
    await prefs.setInt(_kWorkoutMinuteKey, time.minute);
  }
}

final notificationSettingsProvider =
    StateNotifierProvider<NotificationSettingsNotifier, NotificationSettings>(
        (ref) => NotificationSettingsNotifier());
