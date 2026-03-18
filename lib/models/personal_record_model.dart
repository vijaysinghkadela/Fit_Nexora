// lib/models/personal_record_model.dart
import 'package:equatable/equatable.dart';

class PersonalRecord extends Equatable {
  final String id;
  final String userId;
  final String exerciseName;
  final double weightKg;
  final int reps;
  final DateTime achievedAt;
  final String? notes;

  const PersonalRecord({
    required this.id,
    required this.userId,
    required this.exerciseName,
    required this.weightKg,
    required this.reps,
    required this.achievedAt,
    this.notes,
  });

  /// Epley one-rep-max estimate.
  double get estimatedOneRepMax {
    if (reps == 1) return weightKg;
    return weightKg * (1 + reps / 30.0);
  }

  String get displayWeight =>
      weightKg == weightKg.roundToDouble()
          ? '${weightKg.round()} kg'
          : '${weightKg.toStringAsFixed(1)} kg';

  factory PersonalRecord.fromMap(Map<String, dynamic> map) => PersonalRecord(
        id: map['id'] as String,
        userId: map['user_id'] as String,
        exerciseName: map['exercise_name'] as String,
        weightKg: (map['weight_kg'] as num).toDouble(),
        reps: (map['reps'] as num).toInt(),
        achievedAt: DateTime.parse(map['achieved_at'] as String),
        notes: map['notes'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'user_id': userId,
        'exercise_name': exerciseName,
        'weight_kg': weightKg,
        'reps': reps,
        'achieved_at': achievedAt.toIso8601String(),
        if (notes != null) 'notes': notes,
      };

  @override
  List<Object?> get props => [id, userId, exerciseName, achievedAt];
}
