import 'package:flutter_riverpod/flutter_riverpod.dart';

class ScheduledExercise {
  final String name;
  final int sets;
  final int reps;
  final double weightKg;

  const ScheduledExercise({
    required this.name,
    required this.sets,
    required this.reps,
    required this.weightKg,
  });

  ScheduledExercise copyWith({
    String? name,
    int? sets,
    int? reps,
    double? weightKg,
  }) =>
      ScheduledExercise(
        name: name ?? this.name,
        sets: sets ?? this.sets,
        reps: reps ?? this.reps,
        weightKg: weightKg ?? this.weightKg,
      );
}

class ScheduledWorkout {
  final DateTime date;
  final List<ScheduledExercise> exercises;

  const ScheduledWorkout({required this.date, required this.exercises});

  ScheduledWorkout copyWith({
    DateTime? date,
    List<ScheduledExercise>? exercises,
  }) =>
      ScheduledWorkout(
        date: date ?? this.date,
        exercises: exercises ?? this.exercises,
      );
}

String _dateKey(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

class WorkoutCalendarNotifier
    extends StateNotifier<Map<String, ScheduledWorkout>> {
  WorkoutCalendarNotifier() : super(_seedWorkouts());

  static Map<String, ScheduledWorkout> _seedWorkouts() {
    final now = DateTime.now();
    final seeded = <String, ScheduledWorkout>{};

    final days = [1, 3, 5, 8, 10];
    final plans = [
      [
        const ScheduledExercise(name: 'Bench Press', sets: 4, reps: 8, weightKg: 80),
        const ScheduledExercise(name: 'Incline DB Press', sets: 3, reps: 12, weightKg: 30),
        const ScheduledExercise(name: 'Cable Fly', sets: 3, reps: 15, weightKg: 15),
      ],
      [
        const ScheduledExercise(name: 'Squat', sets: 4, reps: 6, weightKg: 100),
        const ScheduledExercise(name: 'Leg Press', sets: 3, reps: 12, weightKg: 150),
        const ScheduledExercise(name: 'Leg Curl', sets: 3, reps: 12, weightKg: 50),
      ],
      [
        const ScheduledExercise(name: 'Pull-Up', sets: 4, reps: 8, weightKg: 0),
        const ScheduledExercise(name: 'Barbell Row', sets: 4, reps: 8, weightKg: 70),
        const ScheduledExercise(name: 'Lat Pulldown', sets: 3, reps: 12, weightKg: 60),
      ],
      [
        const ScheduledExercise(name: 'OHP', sets: 4, reps: 8, weightKg: 55),
        const ScheduledExercise(name: 'Lateral Raise', sets: 3, reps: 15, weightKg: 12),
      ],
      [
        const ScheduledExercise(name: 'Deadlift', sets: 3, reps: 5, weightKg: 120),
        const ScheduledExercise(name: 'Romanian DL', sets: 3, reps: 10, weightKg: 80),
      ],
    ];

    for (var i = 0; i < days.length; i++) {
      final date = DateTime(now.year, now.month, days[i]);
      final key = _dateKey(date);
      seeded[key] = ScheduledWorkout(date: date, exercises: plans[i]);
    }

    return seeded;
  }

  void addExercise(DateTime date, String name) {
    final key = _dateKey(date);
    final existing = state[key];
    final newExercise =
        ScheduledExercise(name: name, sets: 3, reps: 10, weightKg: 0);
    if (existing != null) {
      state = {
        ...state,
        key: existing.copyWith(
            exercises: [...existing.exercises, newExercise]),
      };
    } else {
      state = {
        ...state,
        key: ScheduledWorkout(date: date, exercises: [newExercise]),
      };
    }
  }

  void removeExercise(DateTime date, String name) {
    final key = _dateKey(date);
    final existing = state[key];
    if (existing == null) return;
    final updated = existing.exercises.where((e) => e.name != name).toList();
    if (updated.isEmpty) {
      final newState = Map<String, ScheduledWorkout>.from(state);
      newState.remove(key);
      state = newState;
    } else {
      state = {...state, key: existing.copyWith(exercises: updated)};
    }
  }

  void updateExercise(DateTime date, ScheduledExercise exercise) {
    final key = _dateKey(date);
    final existing = state[key];
    if (existing == null) return;
    final updated = existing.exercises
        .map((e) => e.name == exercise.name ? exercise : e)
        .toList();
    state = {...state, key: existing.copyWith(exercises: updated)};
  }

  List<ScheduledWorkout> getWorkoutsForMonth(int year, int month) {
    return state.values
        .where((w) => w.date.year == year && w.date.month == month)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }
}

final workoutCalendarProvider =
    StateNotifierProvider.autoDispose<WorkoutCalendarNotifier, Map<String, ScheduledWorkout>>(
  (ref) => WorkoutCalendarNotifier(),
);
