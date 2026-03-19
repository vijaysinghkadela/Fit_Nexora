import 'package:flutter_riverpod/flutter_riverpod.dart';

// ─── Steps ────────────────────────────────────────────────────────────────────

class StepsState {
  final int stepsToday;
  final int dailyGoal;
  final List<int> weeklySteps; // Mon–Sun
  final int monthlyGoal;

  const StepsState({
    required this.stepsToday,
    required this.dailyGoal,
    required this.weeklySteps,
    required this.monthlyGoal,
  });

  StepsState copyWith({
    int? stepsToday,
    int? dailyGoal,
    List<int>? weeklySteps,
    int? monthlyGoal,
  }) =>
      StepsState(
        stepsToday: stepsToday ?? this.stepsToday,
        dailyGoal: dailyGoal ?? this.dailyGoal,
        weeklySteps: weeklySteps ?? this.weeklySteps,
        monthlyGoal: monthlyGoal ?? this.monthlyGoal,
      );
}

class StepsNotifier extends StateNotifier<StepsState> {
  StepsNotifier()
      : super(const StepsState(
          stepsToday: 8420,
          dailyGoal: 10000,
          weeklySteps: [9200, 7800, 10400, 8420, 6100, 11200, 5400],
          monthlyGoal: 300000,
        ));

  void logSteps(int steps) {
    final updated = List<int>.from(state.weeklySteps);
    updated[DateTime.now().weekday - 1] = state.stepsToday + steps;
    state = state.copyWith(
      stepsToday: state.stepsToday + steps,
      weeklySteps: updated,
    );
  }

  void setGoal(int goal) {
    state = state.copyWith(dailyGoal: goal);
  }
}

final stepsProvider = StateNotifierProvider.autoDispose<StepsNotifier, StepsState>(
  (ref) => StepsNotifier(),
);

// ─── Sleep ────────────────────────────────────────────────────────────────────

class SleepEntry {
  final DateTime date;
  final double hoursSlept;
  final String quality; // 'poor' | 'fair' | 'good'
  final String bedtime;
  final String wakeTime;

  const SleepEntry({
    required this.date,
    required this.hoursSlept,
    required this.quality,
    required this.bedtime,
    required this.wakeTime,
  });
}

class SleepState {
  final List<SleepEntry> entries;
  final String viewMode; // 'week' | 'month'

  const SleepState({required this.entries, required this.viewMode});

  SleepState copyWith({List<SleepEntry>? entries, String? viewMode}) =>
      SleepState(
        entries: entries ?? this.entries,
        viewMode: viewMode ?? this.viewMode,
      );
}

class SleepNotifier extends StateNotifier<SleepState> {
  SleepNotifier()
      : super(SleepState(
          viewMode: 'week',
          entries: _mockEntries(),
        ));

  static List<SleepEntry> _mockEntries() {
    final now = DateTime.now();
    return List.generate(28, (i) {
      final date = now.subtract(Duration(days: 27 - i));
      final hours = [5.5, 6.0, 7.5, 8.0, 6.5, 7.0, 7.5, 5.0, 6.8, 7.2,
                     8.1, 7.8, 6.2, 7.3, 7.5, 8.2, 6.0, 7.1, 7.8, 5.5,
                     6.9, 7.4, 8.0, 7.6, 6.3, 7.0, 7.3, 7.5][i];
      final quality = hours >= 7.0 ? 'good' : hours >= 6.0 ? 'fair' : 'poor';
      return SleepEntry(
        date: date,
        hoursSlept: hours,
        quality: quality,
        bedtime: '10:30 PM',
        wakeTime: '${(6 + hours ~/ 1).toInt()}:${hours % 1 >= 0.5 ? '30' : '00'} AM',
      );
    });
  }

  void logSleep(SleepEntry entry) {
    state = state.copyWith(entries: [...state.entries, entry]);
  }

  void toggleView() {
    state = state.copyWith(
      viewMode: state.viewMode == 'week' ? 'month' : 'week',
    );
  }
}

final sleepProvider = StateNotifierProvider.autoDispose<SleepNotifier, SleepState>(
  (ref) => SleepNotifier(),
);
