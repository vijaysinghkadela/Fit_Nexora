import 'package:equatable/equatable.dart';

/// A single progress check-in entry for a client.
class ProgressCheckIn extends Equatable {
  final String id;
  final String gymId;
  final String clientId;
  final String? trainerId;
  final DateTime checkInDate;

  // Body metrics
  final double? weightKg;
  final double? bodyFatPercent;
  final double? chestCm;
  final double? waistCm;
  final double? hipsCm;
  final double? armCm;
  final double? thighCm;

  // Self-reported
  final String? sleepQuality; // poor, fair, good, excellent
  final String? energyLevel;
  final String? sorenessLevel;
  final int? adherencePercent;
  final String? mood;
  final String? notes;

  // Photos (Supabase Storage paths)
  final String? frontPhotoUrl;
  final String? sidePhotoUrl;
  final String? backPhotoUrl;

  final DateTime createdAt;

  const ProgressCheckIn({
    required this.id,
    required this.gymId,
    required this.clientId,
    this.trainerId,
    required this.checkInDate,
    this.weightKg,
    this.bodyFatPercent,
    this.chestCm,
    this.waistCm,
    this.hipsCm,
    this.armCm,
    this.thighCm,
    this.sleepQuality,
    this.energyLevel,
    this.sorenessLevel,
    this.adherencePercent,
    this.mood,
    this.notes,
    this.frontPhotoUrl,
    this.sidePhotoUrl,
    this.backPhotoUrl,
    required this.createdAt,
  });

  /// Weight change from previous check-in.
  double? weightChange(ProgressCheckIn? previous) {
    if (previous == null || weightKg == null || previous.weightKg == null) {
      return null;
    }
    return weightKg! - previous.weightKg!;
  }

  /// Build a summary for AI analysis.
  String toAiSummary() {
    final parts = <String>[];
    parts.add('Date: ${checkInDate.toIso8601String().split('T').first}');
    if (weightKg != null) parts.add('Weight: $weightKg kg');
    if (bodyFatPercent != null) parts.add('Body Fat: $bodyFatPercent%');
    if (waistCm != null) parts.add('Waist: $waistCm cm');
    if (sleepQuality != null) parts.add('Sleep: $sleepQuality');
    if (energyLevel != null) parts.add('Energy: $energyLevel');
    if (adherencePercent != null) parts.add('Adherence: $adherencePercent%');
    if (mood != null) parts.add('Mood: $mood');
    if (notes != null && notes!.isNotEmpty) parts.add('Notes: $notes');
    return parts.join(' | ');
  }

  factory ProgressCheckIn.fromJson(Map<String, dynamic> json) {
    return ProgressCheckIn(
      id: json['id'] as String,
      gymId: json['gym_id'] as String,
      clientId: json['client_id'] as String,
      trainerId: json['trainer_id'] as String?,
      checkInDate: DateTime.parse(json['checkin_date'] as String),
      weightKg: (json['weight_kg'] as num?)?.toDouble(),
      bodyFatPercent: (json['body_fat_percent'] as num?)?.toDouble(),
      chestCm: (json['chest_cm'] as num?)?.toDouble(),
      waistCm: (json['waist_cm'] as num?)?.toDouble(),
      hipsCm: (json['hips_cm'] as num?)?.toDouble(),
      armCm: (json['arm_cm'] as num?)?.toDouble(),
      thighCm: (json['thigh_cm'] as num?)?.toDouble(),
      sleepQuality: json['sleep_quality'] as String?,
      energyLevel: json['energy_level'] as String?,
      sorenessLevel: json['soreness_level'] as String?,
      adherencePercent: json['adherence_percent'] as int?,
      mood: json['mood'] as String?,
      notes: json['notes'] as String?,
      frontPhotoUrl: json['front_photo_url'] as String?,
      sidePhotoUrl: json['side_photo_url'] as String?,
      backPhotoUrl: json['back_photo_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'gym_id': gymId,
        'client_id': clientId,
        'trainer_id': trainerId,
        'checkin_date': checkInDate.toIso8601String().split('T').first,
        'weight_kg': weightKg,
        'body_fat_percent': bodyFatPercent,
        'chest_cm': chestCm,
        'waist_cm': waistCm,
        'hips_cm': hipsCm,
        'arm_cm': armCm,
        'thigh_cm': thighCm,
        'sleep_quality': sleepQuality,
        'energy_level': energyLevel,
        'soreness_level': sorenessLevel,
        'adherence_percent': adherencePercent,
        'mood': mood,
        'notes': notes,
        'front_photo_url': frontPhotoUrl,
        'side_photo_url': sidePhotoUrl,
        'back_photo_url': backPhotoUrl,
        'created_at': createdAt.toIso8601String(),
      };

  @override
  List<Object?> get props => [id, clientId, checkInDate];
}
