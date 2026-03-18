// lib/providers/water_tracker_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/water_log_model.dart';

const _kWaterGoalKey = 'water_daily_goal_ml';

class WaterTrackerNotifier extends StateNotifier<WaterTrackerState> {
  WaterTrackerNotifier() : super(const WaterTrackerState(isLoading: true)) {
    _init();
  }

  final _client = Supabase.instance.client;
  static const _table = 'water_logs';

  String? get _userId => _client.auth.currentUser?.id;

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final savedGoal = prefs.getInt(_kWaterGoalKey) ?? 2500;
    state = state.copyWith(dailyGoalMl: savedGoal, isLoading: false);
    await loadToday();
  }

  Future<void> loadToday() async {
    final uid = _userId;
    if (uid == null) return;

    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    final end = start.add(const Duration(days: 1));

    try {
      final rows = await _client
          .from(_table)
          .select()
          .eq('user_id', uid)
          .gte('logged_at', start.toIso8601String())
          .lt('logged_at', end.toIso8601String())
          .order('logged_at', ascending: false);

      state = state.copyWith(
        todayLogs: (rows as List).map((r) => WaterLog.fromMap(r)).toList(),
      );
    } catch (_) {
      // Fail silently — local state still works
    }
  }

  Future<void> logWater(int amountMl) async {
    final uid = _userId;
    if (uid == null) return;

    final log = WaterLog(
      id: const Uuid().v4(),
      userId: uid,
      amountMl: amountMl,
      loggedAt: DateTime.now(),
    );

    // Optimistic
    state = state.copyWith(todayLogs: [log, ...state.todayLogs]);

    try {
      await _client.from(_table).insert(log.toMap());
    } catch (_) {
      // Rollback
      state = state.copyWith(
        todayLogs: state.todayLogs.where((l) => l.id != log.id).toList(),
      );
      rethrow;
    }
  }

  Future<void> removeLog(String id) async {
    final prev = state.todayLogs;
    state = state.copyWith(
      todayLogs: prev.where((l) => l.id != id).toList(),
    );
    try {
      await _client.from(_table).delete().eq('id', id);
    } catch (_) {
      state = state.copyWith(todayLogs: prev);
      rethrow;
    }
  }

  Future<void> setDailyGoal(int goalMl) async {
    state = state.copyWith(dailyGoalMl: goalMl);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kWaterGoalKey, goalMl);
  }
}

final waterTrackerProvider =
    StateNotifierProvider<WaterTrackerNotifier, WaterTrackerState>(
  (ref) => WaterTrackerNotifier(),
);
