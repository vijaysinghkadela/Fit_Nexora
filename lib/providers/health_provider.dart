import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ─── Steps ────────────────────────────────────────────────────────────────────

class StepsState {
  final int stepsToday;
  final int dailyGoal;
  final List<int> weeklySteps; // Mon–Sun
  final int monthlyGoal;
  final bool isLoading;

  const StepsState({
    required this.stepsToday,
    required this.dailyGoal,
    required this.weeklySteps,
    required this.monthlyGoal,
    this.isLoading = false,
  });

  StepsState copyWith({
    int? stepsToday,
    int? dailyGoal,
    List<int>? weeklySteps,
    int? monthlyGoal,
    bool? isLoading,
  }) =>
      StepsState(
        stepsToday: stepsToday ?? this.stepsToday,
        dailyGoal: dailyGoal ?? this.dailyGoal,
        weeklySteps: weeklySteps ?? this.weeklySteps,
        monthlyGoal: monthlyGoal ?? this.monthlyGoal,
        isLoading: isLoading ?? this.isLoading,
      );
}

class StepsNotifier extends StateNotifier<StepsState> {
  final SupabaseClient _supabase;

  StepsNotifier(this._supabase)
      : super(const StepsState(
          stepsToday: 0,
          dailyGoal: 10000,
          weeklySteps: [0, 0, 0, 0, 0, 0, 0],
          monthlyGoal: 300000,
          isLoading: true,
        )) {
    _loadSteps();
  }

  Future<void> _loadSteps() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        state = state.copyWith(isLoading: false);
        return;
      }

      final todayStr = DateTime.now().toIso8601String().split('T')[0];

      // Load week
      final weekAgo = DateTime.now()
          .subtract(const Duration(days: 7))
          .toIso8601String()
          .split('T')[0];

      final res = await _supabase
          .from('step_logs')
          .select()
          .eq('user_id', user.id)
          .gte('date', weekAgo);

      int stepsToday = 0;
      int dailyGoal = 10000;
      List<int> weekly = [0, 0, 0, 0, 0, 0, 0];

      for (var row in res) {
        final date = DateTime.parse(row['date']);
        if (row['date'] == todayStr) {
          stepsToday = row['steps'] as int;
          dailyGoal = row['daily_goal'] as int;
        }

        // This week calculation logic (assuming Mon=1, Sun=7)
        if (date.isAfter(DateTime.now().subtract(const Duration(days: 7)))) {
          final weekday = date.weekday;
          weekly[weekday - 1] = row['steps'] as int;
        }
      }

      state = state.copyWith(
        stepsToday: stepsToday,
        dailyGoal: dailyGoal,
        weeklySteps: weekly,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> logSteps(int steps) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final todayStr = DateTime.now().toIso8601String().split('T')[0];
      final newSteps = state.stepsToday + steps;

      // Optimistic
      final updated = List<int>.from(state.weeklySteps);
      updated[DateTime.now().weekday - 1] = newSteps;
      state = state.copyWith(
        stepsToday: newSteps,
        weeklySteps: updated,
      );

      await _supabase.from('step_logs').upsert({
        'user_id': user.id,
        'date': todayStr,
        'steps': newSteps,
        'daily_goal': state.dailyGoal,
      });
    } catch (e) {
      // Refresh on error
      _loadSteps();
    }
  }

  Future<void> setGoal(int goal) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      state = state.copyWith(dailyGoal: goal);
      final todayStr = DateTime.now().toIso8601String().split('T')[0];

      await _supabase.from('step_logs').upsert({
        'user_id': user.id,
        'date': todayStr,
        'steps': state.stepsToday,
        'daily_goal': goal,
      });
    } catch (e) {
      // noop
    }
  }
}

final stepsProvider =
    StateNotifierProvider.autoDispose<StepsNotifier, StepsState>(
  (ref) => StepsNotifier(Supabase.instance.client),
);

// ─── Sleep ────────────────────────────────────────────────────────────────────

class SleepEntry {
  final String id;
  final DateTime date;
  final double hoursSlept;
  final String quality; // 'poor' | 'fair' | 'good' | 'excellent'
  final String bedtime;
  final String wakeTime;

  const SleepEntry({
    required this.id,
    required this.date,
    required this.hoursSlept,
    required this.quality,
    required this.bedtime,
    required this.wakeTime,
  });

  factory SleepEntry.fromMap(Map<String, dynamic> map) {
    return SleepEntry(
      id: map['id'],
      date: DateTime.parse(map['date']),
      hoursSlept: (map['hours_slept'] as num).toDouble(),
      quality: map['quality'] as String,
      bedtime: map['bedtime'] as String,
      wakeTime: map['wake_time'] as String,
    );
  }
}

class SleepState {
  final List<SleepEntry> entries;
  final String viewMode; // 'week' | 'month'
  final bool isLoading;

  const SleepState({
    required this.entries,
    required this.viewMode,
    this.isLoading = false,
  });

  SleepState copyWith(
          {List<SleepEntry>? entries, String? viewMode, bool? isLoading}) =>
      SleepState(
        entries: entries ?? this.entries,
        viewMode: viewMode ?? this.viewMode,
        isLoading: isLoading ?? this.isLoading,
      );
}

class SleepNotifier extends StateNotifier<SleepState> {
  final SupabaseClient _supabase;

  SleepNotifier(this._supabase)
      : super(const SleepState(
          viewMode: 'week',
          entries: [],
          isLoading: true,
        )) {
    _loadSleep();
  }

  Future<void> _loadSleep() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        state = state.copyWith(isLoading: false);
        return;
      }

      final res = await _supabase
          .from('sleep_logs')
          .select()
          .eq('user_id', user.id)
          .order('date', ascending: false)
          .limit(30);

      final entries = res.map((m) => SleepEntry.fromMap(m)).toList();
      state = state.copyWith(entries: entries, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> logSleep({
    required double hoursSlept,
    required String quality,
    required String bedtime,
    required String wakeTime,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final todayStr = DateTime.now().toIso8601String().split('T')[0];

      final res = await _supabase
          .from('sleep_logs')
          .upsert({
            'user_id': user.id,
            'date': todayStr,
            'hours_slept': hoursSlept,
            'quality': quality,
            'bedtime': bedtime,
            'wake_time': wakeTime,
          })
          .select()
          .single();

      final newEntry = SleepEntry.fromMap(res);

      // Update state optimistically/with result
      final existingIndex = state.entries.indexWhere(
          (e) => e.date.toIso8601String().split('T')[0] == todayStr);
      final newEntries = List<SleepEntry>.from(state.entries);
      if (existingIndex >= 0) {
        newEntries[existingIndex] = newEntry;
      } else {
        newEntries.insert(0, newEntry);
      }

      state = state.copyWith(entries: newEntries);
    } catch (e) {
      _loadSleep();
    }
  }

  void toggleView() {
    state = state.copyWith(
      viewMode: state.viewMode == 'week' ? 'month' : 'week',
    );
  }
}

final sleepProvider =
    StateNotifierProvider.autoDispose<SleepNotifier, SleepState>(
  (ref) => SleepNotifier(Supabase.instance.client),
);
