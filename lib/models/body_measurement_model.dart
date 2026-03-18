// lib/models/body_measurement_model.dart
import 'package:equatable/equatable.dart';

class BodyMeasurement extends Equatable {
  final String id;
  final String userId;
  final double? weightKg;
  final double? heightCm;
  final double? bodyFatPercent;
  final double? muscleMassKg;
  final double? waistCm;
  final double? chestCm;
  final double? armCm;
  final double? thighCm;
  final double? hipCm;
  final String? notes;
  final DateTime recordedAt;

  const BodyMeasurement({
    required this.id,
    required this.userId,
    this.weightKg,
    this.heightCm,
    this.bodyFatPercent,
    this.muscleMassKg,
    this.waistCm,
    this.chestCm,
    this.armCm,
    this.thighCm,
    this.hipCm,
    this.notes,
    required this.recordedAt,
  });

  double? get bmi {
    if (weightKg == null || heightCm == null || heightCm! <= 0) return null;
    final hm = heightCm! / 100.0;
    return weightKg! / (hm * hm);
  }

  String get bmiCategory {
    final b = bmi;
    if (b == null) return '—';
    if (b < 18.5) return 'Underweight';
    if (b < 25.0) return 'Normal';
    if (b < 30.0) return 'Overweight';
    return 'Obese';
  }

  factory BodyMeasurement.fromMap(Map<String, dynamic> map) {
    return BodyMeasurement(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      weightKg: (map['weight_kg'] as num?)?.toDouble(),
      heightCm: (map['height_cm'] as num?)?.toDouble(),
      bodyFatPercent: (map['body_fat_percent'] as num?)?.toDouble(),
      muscleMassKg: (map['muscle_mass_kg'] as num?)?.toDouble(),
      waistCm: (map['waist_cm'] as num?)?.toDouble(),
      chestCm: (map['chest_cm'] as num?)?.toDouble(),
      armCm: (map['arm_cm'] as num?)?.toDouble(),
      thighCm: (map['thigh_cm'] as num?)?.toDouble(),
      hipCm: (map['hip_cm'] as num?)?.toDouble(),
      notes: map['notes'] as String?,
      recordedAt: DateTime.parse(map['recorded_at'] as String),
    );
  }

  Map<String, dynamic> toMap() => {
        'user_id': userId,
        if (weightKg != null) 'weight_kg': weightKg,
        if (heightCm != null) 'height_cm': heightCm,
        if (bodyFatPercent != null) 'body_fat_percent': bodyFatPercent,
        if (muscleMassKg != null) 'muscle_mass_kg': muscleMassKg,
        if (waistCm != null) 'waist_cm': waistCm,
        if (chestCm != null) 'chest_cm': chestCm,
        if (armCm != null) 'arm_cm': armCm,
        if (thighCm != null) 'thigh_cm': thighCm,
        if (hipCm != null) 'hip_cm': hipCm,
        if (notes != null) 'notes': notes,
        'recorded_at': recordedAt.toIso8601String(),
      };

  @override
  List<Object?> get props => [id, userId, recordedAt];
}
