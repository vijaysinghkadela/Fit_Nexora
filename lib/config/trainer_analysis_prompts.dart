// lib/config/trainer_analysis_prompts.dart

import '../models/client_profile_model.dart';
import '../models/workout_plan_model.dart';
import '../models/diet_plan_model.dart';
import '../models/trainer_analysis_model.dart';

/// Prompt builders for trainer-generated AI analysis reports.
class TrainerAnalysisPrompts {
  TrainerAnalysisPrompts._();

  /// Builds the comprehensive analysis prompt for a trainer reviewing their client.
  static String buildClientAnalysisPrompt({
    required ClientProfile client,
    required WorkoutPlan? workoutPlan,
    required DietPlan? dietPlan,
    required TrainerAnalysisData data,
    required String trainerName,
  }) {
    return '''
You are a senior fitness consultant and sports scientist reviewing a trainer's client.
Analyse ALL provided data comprehensively and return ONLY valid JSON.
No markdown, no explanations outside the JSON object.

═══════════════════════════════════════════════════════════════════════════════
TRAINER: $trainerName
CLIENT: ${client.fullName ?? 'Unknown'}
ANALYSIS PERIOD: Last 30 days
═══════════════════════════════════════════════════════════════════════════════

CLIENT PROFILE:
${client.toAiContext()}

═══════════════════════════════════════════════════════════════════════════════
ASSIGNED WORKOUT PLAN:
${workoutPlan != null ? _formatWorkoutPlan(workoutPlan) : 'No workout plan currently assigned'}

═══════════════════════════════════════════════════════════════════════════════
ASSIGNED DIET PLAN:
${dietPlan != null ? _formatDietPlan(dietPlan) : 'No diet plan currently assigned'}

═══════════════════════════════════════════════════════════════════════════════
PERFORMANCE DATA (Last 30 days):

${data.toContextString()}

═══════════════════════════════════════════════════════════════════════════════
ANALYSIS REQUIREMENTS:

Consider the following in your analysis:
1. How well is the client adhering to BOTH assigned plans?
2. Are the assigned plans appropriate for their stated goals?
3. What measurable progress has been made toward goals?
4. Are there any red flags (overtraining, underrecovery, stagnation, injury risk)?
5. What specific, actionable adjustments would you recommend?
6. How can the trainer better support this client?

═══════════════════════════════════════════════════════════════════════════════

Respond with ONLY this JSON structure:

{
  "overall_score": 85,
  "score_breakdown": {
    "workout_adherence": 90,
    "diet_adherence": 75,
    "progress_rate": 85,
    "consistency": 80
  },
  
  "summary": "2-3 sentence executive summary for the trainer highlighting key findings",
  
  "workout_analysis": {
    "adherence_percent": 85,
    "sessions_completed": 12,
    "sessions_expected": 16,
    "strengths": ["Strength 1", "Strength 2"],
    "concerns": ["Concern 1", "Concern 2"],
    "plan_fit_assessment": "Assessment of whether current plan is appropriate for goals"
  },
  
  "diet_analysis": {
    "estimated_adherence": 70,
    "protein_target_met": true,
    "calorie_target_met": false,
    "hydration_adequate": true,
    "observations": ["Observation 1", "Observation 2"],
    "concerns": ["Diet concern 1"],
    "plan_fit_assessment": "Assessment of whether diet plan fits their needs"
  },
  
  "body_composition": {
    "weight_trend": "losing | stable | gaining",
    "weight_change_kg": -1.5,
    "trend_appropriate": true,
    "notes": "Interpretation of body composition changes"
  },
  
  "risk_flags": [
    {
      "severity": "low | medium | high",
      "flag": "Description of the concern",
      "recommendation": "What action to take"
    }
  ],
  
  "achievements": [
    "Achievement 1",
    "Achievement 2"
  ],
  
  "recommendations": {
    "immediate_actions": [
      "Action the trainer should take this week"
    ],
    "workout_adjustments": [
      "Suggested change to workout plan"
    ],
    "diet_adjustments": [
      "Suggested change to diet plan"
    ],
    "next_month_priorities": [
      "Focus area for next month"
    ]
  },
  
  "client_message": "A motivating 2-3 sentence message the trainer can share with the client"
}
''';
  }

  /// Format workout plan for prompt injection
  static String _formatWorkoutPlan(WorkoutPlan plan) {
    final buffer = StringBuffer();
    buffer.writeln('Plan Name: ${plan.name}');
    buffer.writeln('Goal: ${plan.goal}');
    buffer.writeln('Athlete Type: ${plan.athleteType}');
    buffer.writeln(
        'Duration: ${plan.durationWeeks} weeks (Currently Week ${plan.currentWeek})');
    buffer.writeln('Phase: ${plan.phase}');
    buffer.writeln('Status: ${plan.status.name}');
    buffer.writeln('Training Days per Week: ${plan.days.length}');
    buffer.writeln();
    buffer.writeln('Weekly Structure:');
    for (final day in plan.days) {
      buffer.writeln(
          '  ${day.dayName}: ${day.muscleGroup} (${day.exercises.length} exercises)');
      for (final ex in day.exercises.take(3)) {
        buffer.writeln(
            '    - ${ex.name}: ${ex.sets}x${ex.reps} @ RPE ${ex.rpe ?? 'N/A'}');
      }
      if (day.exercises.length > 3) {
        buffer
            .writeln('    ... and ${day.exercises.length - 3} more exercises');
      }
    }
    return buffer.toString();
  }

  /// Format diet plan for prompt injection
  static String _formatDietPlan(DietPlan plan) {
    final buffer = StringBuffer();
    buffer.writeln('Plan Name: ${plan.name}');
    buffer.writeln('Goal: ${plan.goal}');
    buffer.writeln('Target Calories: ${plan.targetCalories} kcal');
    buffer.writeln(
        'Macros: P${plan.targetProtein}g / C${plan.targetCarbs}g / F${plan.targetFat}g');
    buffer.writeln('Hydration Target: ${plan.hydrationLiters}L');
    buffer.writeln('Status: ${plan.status.name}');
    buffer.writeln('Meals per Day: ${plan.meals.length}');
    buffer.writeln();
    buffer.writeln('Meal Structure:');
    for (final meal in plan.meals) {
      final mealCalories =
          meal.foods.fold<int>(0, (sum, f) => sum + f.calories);
      buffer.writeln('  ${meal.name} (${meal.timing}): ~$mealCalories kcal');
      for (final food in meal.foods.take(3)) {
        buffer.writeln('    - ${food.name}: ${food.quantity}');
      }
      if (meal.foods.length > 3) {
        buffer.writeln('    ... and ${meal.foods.length - 3} more items');
      }
    }
    return buffer.toString();
  }

  /// Build a quick progress check prompt (lighter than full analysis)
  static String buildQuickProgressCheckPrompt({
    required ClientProfile client,
    required int attendancePercent,
    required double? weightChangeKg,
    required int prsAchieved,
  }) {
    return '''
You are a fitness coach doing a quick progress check.
Return ONLY valid JSON with a brief assessment.

CLIENT: ${client.fullName ?? 'Unknown'}
GOAL: ${client.goal.value}

QUICK STATS (Last 30 days):
- Attendance: $attendancePercent%
- Weight Change: ${weightChangeKg?.toStringAsFixed(1) ?? 'No data'}kg
- PRs Achieved: $prsAchieved

Respond with ONLY this JSON:
{
  "status": "on_track | needs_attention | falling_behind | exceeding",
  "brief_assessment": "One sentence assessment",
  "top_priority": "Single most important focus area",
  "encouragement": "Brief motivating message for client"
}
''';
  }
}
