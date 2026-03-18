/// Member fitness profile for AI agent analysis.
class FitnessProfile {
  final String? id;
  final String memberId;
  final String gymId;

  // Body metrics
  final double? heightCm;
  final double? weightKg;
  final double? bodyFatPct;
  final double? muscleMassKg;
  final double? bmi;
  final int? age;
  final String? gender;

  // Fitness context
  final String? fitnessLevel;
  final String? primaryGoal;
  final String? secondaryGoal;
  final List<String> injuries;
  final int availableDays;

  // Diet context
  final String? dietType;
  final List<String> foodAllergies;
  final int? calorieTarget;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  const FitnessProfile({
    this.id,
    required this.memberId,
    required this.gymId,
    this.heightCm,
    this.weightKg,
    this.bodyFatPct,
    this.muscleMassKg,
    this.bmi,
    this.age,
    this.gender,
    this.fitnessLevel,
    this.primaryGoal,
    this.secondaryGoal,
    this.injuries = const [],
    this.availableDays = 5,
    this.dietType,
    this.foodAllergies = const [],
    this.calorieTarget,
    this.createdAt,
    this.updatedAt,
  });

  factory FitnessProfile.fromJson(Map<String, dynamic> json) {
    return FitnessProfile(
      id: json['id'] as String?,
      memberId: json['member_id'] as String,
      gymId: json['gym_id'] as String,
      heightCm: (json['height_cm'] as num?)?.toDouble(),
      weightKg: (json['weight_kg'] as num?)?.toDouble(),
      bodyFatPct: (json['body_fat_pct'] as num?)?.toDouble(),
      muscleMassKg: (json['muscle_mass_kg'] as num?)?.toDouble(),
      bmi: (json['bmi'] as num?)?.toDouble(),
      age: json['age'] as int?,
      gender: json['gender'] as String?,
      fitnessLevel: json['fitness_level'] as String?,
      primaryGoal: json['primary_goal'] as String?,
      secondaryGoal: json['secondary_goal'] as String?,
      injuries: (json['injuries'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      availableDays: json['available_days'] as int? ?? 5,
      dietType: json['diet_type'] as String?,
      foodAllergies: (json['food_allergies'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      calorieTarget: json['calorie_target'] as int?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'member_id': memberId,
      'gym_id': gymId,
      'height_cm': heightCm,
      'weight_kg': weightKg,
      'body_fat_pct': bodyFatPct,
      'muscle_mass_kg': muscleMassKg,
      'bmi': bmi,
      'age': age,
      'gender': gender,
      'fitness_level': fitnessLevel,
      'primary_goal': primaryGoal,
      'secondary_goal': secondaryGoal,
      'injuries': injuries,
      'available_days': availableDays,
      'diet_type': dietType,
      'food_allergies': foodAllergies,
      'calorie_target': calorieTarget,
    };
  }

  FitnessProfile copyWith({
    String? id,
    String? memberId,
    String? gymId,
    double? heightCm,
    double? weightKg,
    double? bodyFatPct,
    double? muscleMassKg,
    double? bmi,
    int? age,
    String? gender,
    String? fitnessLevel,
    String? primaryGoal,
    String? secondaryGoal,
    List<String>? injuries,
    int? availableDays,
    String? dietType,
    List<String>? foodAllergies,
    int? calorieTarget,
  }) {
    return FitnessProfile(
      id: id ?? this.id,
      memberId: memberId ?? this.memberId,
      gymId: gymId ?? this.gymId,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      bodyFatPct: bodyFatPct ?? this.bodyFatPct,
      muscleMassKg: muscleMassKg ?? this.muscleMassKg,
      bmi: bmi ?? this.bmi,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      fitnessLevel: fitnessLevel ?? this.fitnessLevel,
      primaryGoal: primaryGoal ?? this.primaryGoal,
      secondaryGoal: secondaryGoal ?? this.secondaryGoal,
      injuries: injuries ?? this.injuries,
      availableDays: availableDays ?? this.availableDays,
      dietType: dietType ?? this.dietType,
      foodAllergies: foodAllergies ?? this.foodAllergies,
      calorieTarget: calorieTarget ?? this.calorieTarget,
    );
  }
}
