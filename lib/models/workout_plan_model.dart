import 'package:equatable/equatable.dart';

/// A complete workout plan assigned to a client.
class WorkoutPlan extends Equatable {
  final String id;
  final String gymId;
  final String? clientId;
  final String? trainerId;

  // Plan metadata
  final String name;
  final String? description;
  final String goal; // fat_loss, muscle_gain, etc.
  final int durationWeeks;
  final int currentWeek;
  final String phase; // e.g., "Hypertrophy", "Strength", "Deload"
  final String athleteType; // e.g., "General", "Powerlifting", "Bodybuilding", "Arm Wrestling"

  // Training days
  final List<TrainingDay> days;

  // Status
  final PlanStatus status;
  final bool isTemplate;

  final DateTime createdAt;
  final DateTime updatedAt;

  const WorkoutPlan({
    required this.id,
    required this.gymId,
    this.clientId,
    this.trainerId,
    required this.name,
    this.description,
    this.goal = 'general_fitness',
    this.durationWeeks = 8,
    this.currentWeek = 1,
    this.phase = 'Phase 1',
    this.athleteType = 'General',
    this.days = const [],
    this.status = PlanStatus.active,
    this.isTemplate = false,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Total exercises across all days.
  int get totalExercises => days.fold(0, (sum, d) => sum + d.exercises.length);

  /// Total training days.
  int get trainingDaysCount => days.length;

  factory WorkoutPlan.fromJson(Map<String, dynamic> json) {
    final daysJson = json['days'] as List<dynamic>? ?? [];
    return WorkoutPlan(
      id: json['id'] as String,
      gymId: json['gym_id'] as String,
      clientId: json['client_id'] as String?,
      trainerId: json['trainer_id'] as String?,
      name: json['name'] as String,
      description: json['description'] as String?,
      goal: json['goal'] as String? ?? 'general_fitness',
      durationWeeks: json['duration_weeks'] as int? ?? 8,
      currentWeek: json['current_week'] as int? ?? 1,
      phase: json['phase'] as String? ?? 'Phase 1',
      athleteType: json['athlete_type'] as String? ?? 'General',
      days: daysJson
          .map((d) => TrainingDay.fromJson(d as Map<String, dynamic>))
          .toList(),
      status: PlanStatus.fromString(json['status'] as String? ?? 'active'),
      isTemplate: json['is_template'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'gym_id': gymId,
        'client_id': clientId,
        'trainer_id': trainerId,
        'name': name,
        'description': description,
        'goal': goal,
        'duration_weeks': durationWeeks,
        'current_week': currentWeek,
        'phase': phase,
        'athlete_type': athleteType,
        'days': days.map((d) => d.toJson()).toList(),
        'status': status.value,
        'is_template': isTemplate,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  @override
  List<Object?> get props => [id, name, gymId];
}

/// A single training day within a workout plan.
class TrainingDay {
  final String dayName; // e.g., "Day 1 — Chest & Triceps"
  final String muscleGroup; // e.g., "chest_triceps"
  final int dayIndex; // 0-based
  final List<Exercise> exercises;
  final String? notes;

  const TrainingDay({
    required this.dayName,
    this.muscleGroup = '',
    required this.dayIndex,
    this.exercises = const [],
    this.notes,
  });

  factory TrainingDay.fromJson(Map<String, dynamic> json) {
    final exJson = json['exercises'] as List<dynamic>? ?? [];
    return TrainingDay(
      dayName: json['day_name'] as String,
      muscleGroup: json['muscle_group'] as String? ?? '',
      dayIndex: json['day_index'] as int? ?? 0,
      exercises: exJson
          .map((e) => Exercise.fromJson(e as Map<String, dynamic>))
          .toList(),
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'day_name': dayName,
        'muscle_group': muscleGroup,
        'day_index': dayIndex,
        'exercises': exercises.map((e) => e.toJson()).toList(),
        'notes': notes,
      };
}

/// A single exercise within a training day.
class Exercise {
  final String name;
  final int sets;
  final String reps; // "8-12" or "10" or "30s"
  final int restSeconds;
  final String? setTime; // duration string representing time under tension per set
  final int? rpe; // 1-10 rate of perceived exertion
  final String? supersetGroupId; // "A", "B", etc. to group exercises
  final String? intensity; // "Low", "Medium", "High"
  final String? tempo; // e.g., "3-1-2-0"
  final String? equipment;
  final String? cue; // one key coaching cue
  final String? substitute; // alternative exercise name
  final int orderIndex;

  const Exercise({
    required this.name,
    this.sets = 3,
    this.reps = '10',
    this.restSeconds = 60,
    this.setTime,
    this.rpe,
    this.supersetGroupId,
    this.intensity,
    this.tempo,
    this.equipment,
    this.cue,
    this.substitute,
    this.orderIndex = 0,
  });

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      name: json['name'] as String,
      sets: json['sets'] as int? ?? 3,
      reps: json['reps'] as String? ?? '10',
      restSeconds: json['rest_seconds'] as int? ?? 60,
      setTime: json['set_time'] as String?,
      rpe: json['rpe'] as int?,
      supersetGroupId: json['superset_group_id'] as String?,
      intensity: json['intensity'] as String?,
      tempo: json['tempo'] as String?,
      equipment: json['equipment'] as String?,
      cue: json['cue'] as String?,
      substitute: json['substitute'] as String?,
      orderIndex: json['order_index'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'sets': sets,
        'reps': reps,
        'rest_seconds': restSeconds,
        'set_time': setTime,
        'rpe': rpe,
        'superset_group_id': supersetGroupId,
        'intensity': intensity,
        'tempo': tempo,
        'equipment': equipment,
        'cue': cue,
        'substitute': substitute,
        'order_index': orderIndex,
      };
}

/// Plan status.
enum PlanStatus {
  active('active', 'Active'),
  paused('paused', 'Paused'),
  completed('completed', 'Completed'),
  archived('archived', 'Archived');

  const PlanStatus(this.value, this.label);
  final String value;
  final String label;

  static PlanStatus fromString(String value) {
    return PlanStatus.values.firstWhere(
      (s) => s.value == value,
      orElse: () => PlanStatus.active,
    );
  }
}
