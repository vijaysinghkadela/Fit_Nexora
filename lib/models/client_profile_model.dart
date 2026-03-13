import 'package:equatable/equatable.dart';
import '../core/enums.dart';

/// Client fitness profile — maps 1:1 to the AI prompt schema.
///
/// All fields that appear in the master system prompt's CLIENT PROFILE SCHEMA
/// are represented here, ensuring `toAiContext()` produces a complete profile
/// injection for Claude API calls.
class ClientProfile extends Equatable {
  final String id;
  final String? userId;
  final String gymId;
  final String? fullName;
  final String? email;
  final String? phone;
  final int? age;
  final String? sex;
  final double? weightKg;
  final double? heightCm;
  final FitnessGoal goal;
  final TrainingLevel trainingLevel;
  final int daysPerWeek;
  final EquipmentType equipmentType;
  final TrainingTime trainingTime;
  final DietType dietType;
  final String? restrictions;
  final String? injuries;
  final String? medicalConditions;
  final String? currentPlanPhase;
  final double? lastCheckInWeight;
  final WeightTrend? weightTrend;
  final QualityRating? sleepQuality;
  final QualityRating? energyLevel;
  final int? adherencePercent;
  final DateTime? lastGymVisit;
  final String? assignedTrainerId;
  final String? assignedTrainerName;
  final String? currentPlanName;
  final LanguagePreference languagePreference;

  // v2.0 additions
  final FitnessGoal? secondaryGoal;
  final int? sessionDurationMins;
  final CuisineType cuisine;
  final CookingLevel cookingLevel;
  final String? medications;
  final StressLevel? stressLevel;
  final int? nutritionAdherencePercent;
  final int currentStreak;
  final String? gymPlan; // basic | pro | elite
  final int? aiQuotaRemaining;
  final String? gymName;

  final DateTime createdAt;
  final DateTime updatedAt;

  /// Legacy getter for backward compat — maps to equipmentType.value.
  String? get equipment => equipmentType.value;

  const ClientProfile({
    required this.id,
    this.userId,
    required this.gymId,
    this.fullName,
    this.email,
    this.phone,
    this.age,
    this.sex,
    this.weightKg,
    this.heightCm,
    this.goal = FitnessGoal.generalFitness,
    this.trainingLevel = TrainingLevel.beginner,
    this.daysPerWeek = 3,
    this.equipmentType = EquipmentType.fullGym,
    this.trainingTime = TrainingTime.morning,
    this.dietType = DietType.nonVegetarian,
    this.restrictions,
    this.injuries,
    this.medicalConditions,
    this.currentPlanPhase,
    this.lastCheckInWeight,
    this.weightTrend,
    this.sleepQuality,
    this.energyLevel,
    this.adherencePercent,
    this.lastGymVisit,
    this.assignedTrainerId,
    this.assignedTrainerName,
    this.currentPlanName,
    this.languagePreference = LanguagePreference.english,
    this.secondaryGoal,
    this.sessionDurationMins,
    this.cuisine = CuisineType.indian,
    this.cookingLevel = CookingLevel.fullCooking,
    this.medications,
    this.stressLevel,
    this.nutritionAdherencePercent,
    this.currentStreak = 0,
    this.gymPlan,
    this.aiQuotaRemaining,
    this.gymName,
    required this.createdAt,
    required this.updatedAt,
  });

  /// BMI calculation.
  double? get bmi {
    if (weightKg == null || heightCm == null || heightCm == 0) return null;
    final heightM = heightCm! / 100;
    return weightKg! / (heightM * heightM);
  }

  /// Build the complete AI context string matching the master prompt schema.
  /// This output is injected into the Claude API system message.
  String toAiContext() {
    final bmiValue = bmi?.toStringAsFixed(1) ?? 'N/A';
    return '''
Name: ${fullName ?? 'Unknown'}
Age: ${age ?? 'Not provided'}
Sex: ${sex ?? 'Not provided'}
Weight: ${weightKg != null ? '$weightKg kg' : 'Not provided'} | Height: ${heightCm != null ? '$heightCm cm' : 'Not provided'} | BMI: $bmiValue
Language: ${languagePreference.value}
Goal: ${goal.value}${secondaryGoal != null ? ' | Secondary: ${secondaryGoal!.value}' : ''}
Training Level: ${trainingLevel.value}
Training Days Available: $daysPerWeek${sessionDurationMins != null ? ' | Session Duration: ${sessionDurationMins}min' : ''}
Preferred Training Time: ${trainingTime.value}
Available Equipment: ${equipmentType.value}
Dietary Preference: ${dietType.value}
Cuisine: ${cuisine.value} | Cooking Level: ${cookingLevel.value}
Food Allergies / Restrictions: ${restrictions ?? 'None'}
Injuries / Physical Limitations: ${injuries ?? 'None'}
Medical Conditions: ${medicalConditions ?? 'None'}
Medications: ${medications ?? 'None'}
Sleep Quality: ${sleepQuality?.value ?? 'No data'} | Stress Level: ${stressLevel?.value ?? 'No data'}
Energy Level: ${energyLevel?.value ?? 'No data'}
Current Plan Phase: ${currentPlanPhase ?? 'Not set'}
Last Check-in Weight: ${lastCheckInWeight != null ? '$lastCheckInWeight kg' : 'No data'}
Weight Trend: ${weightTrend?.value ?? 'No data'}
Training Adherence Rate: ${adherencePercent != null ? '$adherencePercent%' : 'No data'}
Nutrition Adherence Rate: ${nutritionAdherencePercent != null ? '$nutritionAdherencePercent%' : 'No data'}
Current Streak: $currentStreak days
Last Gym Visit: ${lastGymVisit?.toIso8601String().split('T').first ?? 'No data'}
Trainer Assigned: ${assignedTrainerName ?? 'Unassigned'}
Plan Name: ${currentPlanName ?? 'None'}
Gym Plan: ${gymPlan ?? 'basic'} | AI Quota Remaining: ${aiQuotaRemaining ?? 'N/A'}
Gym: ${gymName ?? 'Unknown'}''';
  }

  /// Alias for [toAiContext] — matches the Claude API call pattern.
  String toProfileBlock() => toAiContext();

  factory ClientProfile.fromJson(Map<String, dynamic> json) {
    return ClientProfile(
      id: json['id'] as String,
      userId: json['user_id'] as String?,
      gymId: json['gym_id'] as String,
      fullName: json['full_name'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      age: json['age'] as int?,
      sex: json['sex'] as String?,
      weightKg: (json['weight_kg'] as num?)?.toDouble(),
      heightCm: (json['height_cm'] as num?)?.toDouble(),
      goal:
          FitnessGoal.fromString(json['goal'] as String? ?? 'general_fitness'),
      trainingLevel: TrainingLevel.fromString(
          json['training_level'] as String? ?? 'beginner'),
      daysPerWeek: json['days_per_week'] as int? ?? 3,
      equipmentType:
          EquipmentType.fromString(json['equipment'] as String? ?? 'full_gym'),
      trainingTime: TrainingTime.fromString(
          json['training_time'] as String? ?? 'morning'),
      dietType: DietType.fromString(json['diet_type'] as String? ?? 'non_veg'),
      restrictions: json['restrictions'] as String?,
      injuries: json['injuries'] as String?,
      medicalConditions: json['medical_conditions'] as String?,
      currentPlanPhase: json['current_plan_phase'] as String?,
      lastCheckInWeight: (json['last_checkin_weight'] as num?)?.toDouble(),
      weightTrend: json['weight_trend'] != null
          ? WeightTrend.fromString(json['weight_trend'] as String)
          : null,
      sleepQuality: json['sleep_quality'] != null
          ? QualityRating.fromString(json['sleep_quality'] as String)
          : null,
      energyLevel: json['energy_level'] != null
          ? QualityRating.fromString(json['energy_level'] as String)
          : null,
      adherencePercent: json['adherence_percent'] as int?,
      lastGymVisit: json['last_gym_visit'] != null
          ? DateTime.parse(json['last_gym_visit'] as String)
          : null,
      assignedTrainerId: json['assigned_trainer_id'] as String?,
      assignedTrainerName: json['assigned_trainer_name'] as String?,
      currentPlanName: json['current_plan_name'] as String?,
      languagePreference: LanguagePreference.fromString(
          json['language_preference'] as String? ?? 'english'),
      secondaryGoal: json['secondary_goal'] != null
          ? FitnessGoal.fromString(json['secondary_goal'] as String)
          : null,
      sessionDurationMins: json['session_duration_mins'] as int?,
      cuisine: CuisineType.fromString(json['cuisine'] as String? ?? 'indian'),
      cookingLevel: CookingLevel.fromString(
          json['cooking_level'] as String? ?? 'full_cooking'),
      medications: json['medications'] as String?,
      stressLevel: json['stress_level'] != null
          ? StressLevel.fromString(json['stress_level'] as String)
          : null,
      nutritionAdherencePercent: json['nutrition_adherence_percent'] as int?,
      currentStreak: json['current_streak'] as int? ?? 0,
      gymPlan: json['gym_plan'] as String?,
      aiQuotaRemaining: json['ai_quota_remaining'] as int?,
      gymName: json['gym_name'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'gym_id': gymId,
        'full_name': fullName,
        'email': email,
        'phone': phone,
        'age': age,
        'sex': sex,
        'weight_kg': weightKg,
        'height_cm': heightCm,
        'goal': goal.value,
        'training_level': trainingLevel.value,
        'days_per_week': daysPerWeek,
        'equipment': equipmentType.value,
        'training_time': trainingTime.value,
        'diet_type': dietType.value,
        'restrictions': restrictions,
        'injuries': injuries,
        'medical_conditions': medicalConditions,
        'current_plan_phase': currentPlanPhase,
        'last_checkin_weight': lastCheckInWeight,
        'weight_trend': weightTrend?.value,
        'sleep_quality': sleepQuality?.value,
        'energy_level': energyLevel?.value,
        'adherence_percent': adherencePercent,
        'last_gym_visit': lastGymVisit?.toIso8601String(),
        'assigned_trainer_id': assignedTrainerId,
        'current_plan_name': currentPlanName,
        'language_preference': languagePreference.value,
        'secondary_goal': secondaryGoal?.value,
        'session_duration_mins': sessionDurationMins,
        'cuisine': cuisine.value,
        'cooking_level': cookingLevel.value,
        'medications': medications,
        'stress_level': stressLevel?.value,
        'nutrition_adherence_percent': nutritionAdherencePercent,
        'current_streak': currentStreak,
        'gym_plan': gymPlan,
        'ai_quota_remaining': aiQuotaRemaining,
        'gym_name': gymName,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  @override
  List<Object?> get props => [id, gymId, fullName, email, updatedAt];
}
