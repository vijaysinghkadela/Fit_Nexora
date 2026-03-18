import '../models/fitness_profile_model.dart';
import '../models/ai_generated_plan_model.dart';

/// Prompt builders for the FitNexora AI Agent pipeline.
///
/// Each function returns a user-message string that instructs Claude to respond
/// with ONLY valid JSON matching the expected schema.
class AiAgentPrompts {
  AiAgentPrompts._();

  // ─── BODY ANALYSIS ──────────────────────────────────────────────────────────

  static String buildBodyAnalysisPrompt(FitnessProfile profile) {
    return '''
You are an expert sports scientist and certified personal trainer.
Analyse the following gym member's body metrics and return ONLY valid JSON.
Do not include any explanation, markdown, or text outside the JSON object.

MEMBER PROFILE:
- Age: ${profile.age ?? 'Unknown'} years
- Gender: ${profile.gender ?? 'Not specified'}
- Height: ${profile.heightCm ?? 'Not recorded'} cm
- Weight: ${profile.weightKg ?? 'Not recorded'} kg
- BMI: ${profile.bmi ?? 'Not recorded'}
- Body Fat %: ${profile.bodyFatPct ?? 'Not recorded'}
- Muscle Mass: ${profile.muscleMassKg ?? 'Not recorded'} kg
- Fitness Level: ${profile.fitnessLevel ?? 'beginner'}
- Primary Goal: ${profile.primaryGoal ?? 'general_fitness'}
- Injuries/Limitations: ${profile.injuries.isNotEmpty ? profile.injuries.join(', ') : 'None'}

Respond with a JSON object matching EXACTLY this structure:
{
  "somatotype": "ectomorph | mesomorph | endomorph | ecto-mesomorph | endo-mesomorph",
  "somatotype_explanation": "2-3 sentence explanation of what this means for this person",
  "bmi_category": "underweight | normal | overweight | obese",
  "bmi_interpretation": "1-2 sentences interpreting BMI in context of their goals",
  "fitness_assessment": "Brief assessment of their current fitness level",
  "key_strengths": ["strength 1", "strength 2", "strength 3"],
  "areas_to_improve": ["area 1", "area 2", "area 3"],
  "recommended_focus": "muscle_gain | fat_loss | endurance | strength | flexibility | balanced",
  "risk_flags": ["any injury risks or health flags to communicate to trainer"]
}
''';
  }

  // ─── WORKOUT PLAN ───────────────────────────────────────────────────────────

  static String buildWorkoutPlanPrompt(
    FitnessProfile profile,
    Map<String, dynamic> bodyAnalysis,
    MemberVisitSummary? visitStats,
  ) {
    return '''
You are a certified strength and conditioning coach creating a monthly workout plan.
Return ONLY valid JSON. No markdown, no explanations outside the JSON.

MEMBER DATA:
- Somatotype: ${bodyAnalysis['somatotype'] ?? 'mesomorph'}
- Primary Goal: ${profile.primaryGoal ?? 'general_fitness'}
- Fitness Level: ${profile.fitnessLevel ?? 'beginner'}
- Available Training Days/Week: ${profile.availableDays}
- Injuries: ${profile.injuries.isNotEmpty ? profile.injuries.join(', ') : 'None'}
- Avg Gym Visit Duration: ${visitStats?.avgSessionHrs ?? 1.0} hours
- Visits last 30 days: ${visitStats?.visitsLast30Days ?? 0}
- Recommended Focus: ${bodyAnalysis['recommended_focus'] ?? 'balanced'}

Create a 4-week progressive workout plan. Each week should be slightly harder than the last.

JSON structure:
{
  "plan_name": "e.g. 4-Week Fat Burn Accelerator",
  "weekly_structure": "e.g. 5 days on, 2 days rest",
  "progression_logic": "brief explanation of how intensity increases each week",
  "weeks": [
    {
      "week": 1,
      "theme": "e.g. Foundation",
      "intensity": "low | moderate | high",
      "days": [
        {
          "day": "Monday",
          "focus": "e.g. Upper Body Push",
          "exercises": [
            {
              "name": "Bench Press",
              "sets": 3,
              "reps": "10-12",
              "rest_seconds": 60,
              "notes": "Keep elbows at 45 degrees"
            }
          ],
          "cardio": "e.g. 20 min moderate treadmill",
          "estimated_duration_mins": 60
        }
      ]
    }
  ],
  "warm_up_protocol": "General 5-minute warm-up description",
  "cool_down_protocol": "General cool-down and stretching description",
  "trainer_tips": ["tip 1", "tip 2", "tip 3"]
}
''';
  }

  // ─── DIET PLAN ──────────────────────────────────────────────────────────────

  static String buildDietPlanPrompt(
    FitnessProfile profile,
    Map<String, dynamic> bodyAnalysis,
  ) {
    // Estimate TDEE
    final weight = profile.weightKg ?? 70;
    final height = profile.heightCm ?? 170;
    final age = profile.age ?? 25;
    final isMale = profile.gender == 'male';

    final bmr = isMale
        ? 88.36 + (13.4 * weight) + (4.8 * height) - (5.7 * age)
        : 447.6 + (9.2 * weight) + (3.1 * height) - (4.3 * age);

    final activityMultiplier = profile.availableDays >= 5 ? 1.55 : 1.375;
    final tdee = (bmr * activityMultiplier).round();

    return '''
You are a certified sports nutritionist. Return ONLY valid JSON. No text outside the JSON.

MEMBER PROFILE:
- Age: ${profile.age ?? 25}, Gender: ${profile.gender ?? 'male'}
- Weight: ${profile.weightKg ?? 70}kg, Height: ${profile.heightCm ?? 170}cm
- Primary Goal: ${profile.primaryGoal ?? 'general_fitness'}
- Diet Type: ${profile.dietType ?? 'non_vegetarian'}
- Food Allergies: ${profile.foodAllergies.isNotEmpty ? profile.foodAllergies.join(', ') : 'None'}
- Estimated TDEE: $tdee calories/day
- Calorie Target Override: ${profile.calorieTarget ?? 'Use TDEE-based calculation'}
- Training Days/Week: ${profile.availableDays}
- Recommended Focus: ${bodyAnalysis['recommended_focus'] ?? 'balanced'}

Create a practical, culturally appropriate (Indian context) diet plan.

JSON structure:
{
  "calorie_target": 2200,
  "protein_g": 160,
  "carbs_g": 250,
  "fats_g": 70,
  "meal_timing": "brief guidance on when to eat relative to training",
  "daily_template": {
    "early_morning": {
      "time": "6:00 AM",
      "items": [
        { "food": "Warm water with lemon", "quantity": "1 glass", "calories": 5 }
      ]
    },
    "breakfast": { "time": "7:30 AM", "items": [] },
    "mid_morning": { "time": "10:30 AM", "items": [] },
    "lunch": { "time": "1:00 PM", "items": [] },
    "pre_workout": { "time": "4:30 PM", "items": [] },
    "post_workout": { "time": "7:00 PM", "items": [] },
    "dinner": { "time": "8:30 PM", "items": [] }
  },
  "hydration_target_litres": 3.5,
  "supplements": [
    { "name": "Whey Protein", "timing": "Post-workout", "dose": "25g", "optional": false }
  ],
  "foods_to_avoid": ["specific foods to avoid based on goals"],
  "nutritionist_tips": ["tip 1", "tip 2", "tip 3"]
}
''';
  }

  // ─── MONTHLY REPORT ─────────────────────────────────────────────────────────

  static String buildMonthlyReportPrompt(
    FitnessProfile profile,
    Map<String, dynamic> bodyAnalysis,
    MemberVisitSummary? visitStats,
  ) {
    final now = DateTime.now();
    final monthName = _monthNames[now.month - 1];
    final year = now.year;

    return '''
You are a senior fitness coach writing a monthly progress report for a gym member.
Write in an encouraging, professional, and direct tone.
Return ONLY valid JSON. No markdown or text outside the JSON.

CONTEXT:
- Member visits this month: ${visitStats?.visitsLast30Days ?? 0}
- Average session duration: ${visitStats?.avgSessionHrs ?? 0} hours
- Body type: ${bodyAnalysis['somatotype'] ?? 'mesomorph'}
- Primary goal: ${profile.primaryGoal ?? 'general_fitness'}
- Fitness level: ${profile.fitnessLevel ?? 'beginner'}

JSON structure:
{
  "report_month": "$monthName $year",
  "executive_summary": "3-4 sentence overview of the member's month",
  "attendance_analysis": {
    "verdict": "excellent | good | fair | poor",
    "comment": "Specific comment on their attendance this month"
  },
  "progress_assessment": {
    "overall_rating": 7,
    "positive_indicators": ["point 1", "point 2"],
    "areas_needing_attention": ["area 1", "area 2"]
  },
  "next_month_focus": [
    { "priority": 1, "focus": "Title", "action": "Specific action step" },
    { "priority": 2, "focus": "Title", "action": "Specific action step" },
    { "priority": 3, "focus": "Title", "action": "Specific action step" }
  ],
  "motivational_message": "Personal, specific motivational closing message",
  "trainer_recommendations": ["recommendation 1", "recommendation 2"]
}
''';
  }

  static const _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];
}
