import 'fitness_profile_model.dart';

/// Structured request for generating a member-facing AI plan bundle.
class AiGenerationRequest {
  final String planObjective;
  final String planName;
  final String planDescription;
  final String planTier;
  final FitnessProfile fitnessProfile;
  final bool publishToActivePlans;
  final int? sessionDurationMins;
  final String? equipment;
  final String? trainingTime;
  final String? restrictions;
  final String? medicalConditions;
  final String? sleepQuality;
  final String? energyLevel;
  final String? fullName;
  final String? phone;

  const AiGenerationRequest({
    required this.planObjective,
    required this.planName,
    required this.planDescription,
    required this.fitnessProfile,
    this.planTier = 'pro',
    this.publishToActivePlans = true,
    this.sessionDurationMins,
    this.equipment,
    this.trainingTime,
    this.restrictions,
    this.medicalConditions,
    this.sleepQuality,
    this.energyLevel,
    this.fullName,
    this.phone,
  });

  String get supplementaryProfileContext {
    final lines = <String>[];
    if (fullName != null && fullName!.trim().isNotEmpty) {
      lines.add('- Member Name: ${fullName!.trim()}');
    }
    if (phone != null && phone!.trim().isNotEmpty) {
      lines.add('- Phone: ${phone!.trim()}');
    }
    if (sessionDurationMins != null) {
      lines.add('- Session Duration: $sessionDurationMins minutes');
    }
    if (equipment != null && equipment!.trim().isNotEmpty) {
      lines.add('- Equipment Access: ${equipment!.trim()}');
    }
    if (trainingTime != null && trainingTime!.trim().isNotEmpty) {
      lines.add('- Preferred Training Time: ${trainingTime!.trim()}');
    }
    if (restrictions != null && restrictions!.trim().isNotEmpty) {
      lines.add('- Food Restrictions: ${restrictions!.trim()}');
    }
    if (medicalConditions != null && medicalConditions!.trim().isNotEmpty) {
      lines.add('- Medical Conditions: ${medicalConditions!.trim()}');
    }
    if (sleepQuality != null && sleepQuality!.trim().isNotEmpty) {
      lines.add('- Sleep Quality: ${sleepQuality!.trim()}');
    }
    if (energyLevel != null && energyLevel!.trim().isNotEmpty) {
      lines.add('- Energy Level: ${energyLevel!.trim()}');
    }
    return lines.join('\n');
  }

  Map<String, dynamic> toJson() => {
        'plan_objective': planObjective,
        'plan_name': planName,
        'plan_description': planDescription,
        'plan_tier': planTier,
        'publish_to_active_plans': publishToActivePlans,
        'session_duration_mins': sessionDurationMins,
        'equipment': equipment,
        'training_time': trainingTime,
        'restrictions': restrictions,
        'medical_conditions': medicalConditions,
        'sleep_quality': sleepQuality,
        'energy_level': energyLevel,
        'full_name': fullName,
        'phone': phone,
        'fitness_profile': fitnessProfile.toJson(),
      };
}
