// lib/models/trainer_analysis_model.dart
import 'package:equatable/equatable.dart';

/// Represents an AI-generated analysis report created by a trainer for their client.
/// Links to assigned workout and diet plans and provides comprehensive progress insights.
class TrainerAnalysisReport extends Equatable {
  final String id;
  final String trainerId;
  final String clientId;
  final String gymId;

  // Linked plans at time of analysis
  final String? workoutPlanId;
  final String? dietPlanId;

  // Scores (0-100)
  final int overallScore;
  final int workoutAdherenceScore;
  final int dietAdherenceScore;
  final int progressScore;
  final int consistencyScore;

  // Full AI response
  final Map<String, dynamic> analysisJson;

  // Quick-access fields
  final String? summary;
  final String? clientMessage;

  // Metadata
  final int tokensUsed;
  final int generationMs;
  final DateTime createdAt;

  const TrainerAnalysisReport({
    required this.id,
    required this.trainerId,
    required this.clientId,
    required this.gymId,
    this.workoutPlanId,
    this.dietPlanId,
    required this.overallScore,
    required this.workoutAdherenceScore,
    required this.dietAdherenceScore,
    required this.progressScore,
    required this.consistencyScore,
    required this.analysisJson,
    this.summary,
    this.clientMessage,
    this.tokensUsed = 0,
    this.generationMs = 0,
    required this.createdAt,
  });

  factory TrainerAnalysisReport.fromMap(Map<String, dynamic> map) {
    final analysisJson = map['analysis_json'] as Map<String, dynamic>? ?? {};
    final scoreBreakdown =
        analysisJson['score_breakdown'] as Map<String, dynamic>? ?? {};

    return TrainerAnalysisReport(
      id: map['id'] as String,
      trainerId: map['trainer_id'] as String,
      clientId: map['client_id'] as String,
      gymId: map['gym_id'] as String,
      workoutPlanId: map['workout_plan_id'] as String?,
      dietPlanId: map['diet_plan_id'] as String?,
      overallScore: map['overall_score'] as int? ??
          (analysisJson['overall_score'] as int?) ??
          0,
      workoutAdherenceScore: map['workout_adherence_score'] as int? ??
          (scoreBreakdown['workout_adherence'] as int?) ??
          0,
      dietAdherenceScore: map['diet_adherence_score'] as int? ??
          (scoreBreakdown['diet_adherence'] as int?) ??
          0,
      progressScore: map['progress_score'] as int? ??
          (scoreBreakdown['progress_rate'] as int?) ??
          0,
      consistencyScore: map['consistency_score'] as int? ??
          (scoreBreakdown['consistency'] as int?) ??
          0,
      analysisJson: analysisJson,
      summary:
          map['summary'] as String? ?? (analysisJson['summary'] as String?),
      clientMessage: map['client_message'] as String? ??
          (analysisJson['client_message'] as String?),
      tokensUsed: map['tokens_used'] as int? ?? 0,
      generationMs: map['generation_ms'] as int? ?? 0,
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'trainer_id': trainerId,
        'client_id': clientId,
        'gym_id': gymId,
        'workout_plan_id': workoutPlanId,
        'diet_plan_id': dietPlanId,
        'overall_score': overallScore,
        'workout_adherence_score': workoutAdherenceScore,
        'diet_adherence_score': dietAdherenceScore,
        'progress_score': progressScore,
        'consistency_score': consistencyScore,
        'analysis_json': analysisJson,
        'summary': summary,
        'client_message': clientMessage,
        'tokens_used': tokensUsed,
        'generation_ms': generationMs,
        'created_at': createdAt.toIso8601String(),
      };

  // ─── Getters for nested analysis data ─────────────────────────────────────

  /// Workout analysis section
  Map<String, dynamic> get workoutAnalysis =>
      analysisJson['workout_analysis'] as Map<String, dynamic>? ?? {};

  /// Diet analysis section
  Map<String, dynamic> get dietAnalysis =>
      analysisJson['diet_analysis'] as Map<String, dynamic>? ?? {};

  /// Body composition section
  Map<String, dynamic> get bodyComposition =>
      analysisJson['body_composition'] as Map<String, dynamic>? ?? {};

  /// Risk flags list
  List<Map<String, dynamic>> get riskFlags {
    final flags = analysisJson['risk_flags'];
    if (flags is List) {
      return flags.cast<Map<String, dynamic>>();
    }
    return [];
  }

  /// Achievements list
  List<String> get achievements {
    final items = analysisJson['achievements'];
    if (items is List) {
      return items.cast<String>();
    }
    return [];
  }

  /// Recommendations section
  Map<String, dynamic> get recommendations =>
      analysisJson['recommendations'] as Map<String, dynamic>? ?? {};

  /// Immediate actions
  List<String> get immediateActions {
    final items = recommendations['immediate_actions'];
    if (items is List) return items.cast<String>();
    return [];
  }

  /// Workout adjustments
  List<String> get workoutAdjustments {
    final items = recommendations['workout_adjustments'];
    if (items is List) return items.cast<String>();
    return [];
  }

  /// Diet adjustments
  List<String> get dietAdjustments {
    final items = recommendations['diet_adjustments'];
    if (items is List) return items.cast<String>();
    return [];
  }

  /// Next month priorities
  List<String> get nextMonthPriorities {
    final items = recommendations['next_month_priorities'];
    if (items is List) return items.cast<String>();
    return [];
  }

  /// Score category for UI display
  String get scoreCategory {
    if (overallScore >= 90) return 'Excellent';
    if (overallScore >= 75) return 'Good';
    if (overallScore >= 60) return 'Moderate';
    if (overallScore >= 40) return 'Needs Improvement';
    return 'Critical';
  }

  /// High-severity risk flags count
  int get highRiskCount =>
      riskFlags.where((f) => f['severity'] == 'high').length;

  @override
  List<Object?> get props => [
        id,
        trainerId,
        clientId,
        gymId,
        workoutPlanId,
        dietPlanId,
        overallScore,
        workoutAdherenceScore,
        dietAdherenceScore,
        progressScore,
        consistencyScore,
        createdAt,
      ];
}

/// Aggregated data for generating a trainer analysis report
class TrainerAnalysisData {
  final int totalCheckins;
  final int expectedCheckins;
  final double avgSessionMins;
  final List<Map<String, dynamic>> bodyMeasurements;
  final List<Map<String, dynamic>> personalRecords;
  final List<Map<String, dynamic>> waterLogs;
  final int totalWaterMl;
  final int waterGoalMl;
  final double avgSleepHours;
  final int avgSteps;
  final double? weightChangeKg;
  final String? weightTrend;

  const TrainerAnalysisData({
    required this.totalCheckins,
    required this.expectedCheckins,
    required this.avgSessionMins,
    required this.bodyMeasurements,
    required this.personalRecords,
    required this.waterLogs,
    required this.totalWaterMl,
    required this.waterGoalMl,
    required this.avgSleepHours,
    required this.avgSteps,
    this.weightChangeKg,
    this.weightTrend,
  });

  double get attendancePercent => expectedCheckins > 0
      ? (totalCheckins / expectedCheckins * 100).clamp(0, 100)
      : 0;

  double get hydrationPercent =>
      waterGoalMl > 0 ? (totalWaterMl / waterGoalMl * 100).clamp(0, 200) : 0;

  String toContextString() {
    final buffer = StringBuffer();

    buffer.writeln('GYM ATTENDANCE (Last 30 days):');
    buffer.writeln('- Total check-ins: $totalCheckins');
    buffer.writeln('- Expected (based on plan): $expectedCheckins');
    buffer
        .writeln('- Attendance rate: ${attendancePercent.toStringAsFixed(1)}%');
    buffer.writeln(
        '- Avg session duration: ${avgSessionMins.toStringAsFixed(0)} minutes');
    buffer.writeln();

    buffer.writeln('BODY MEASUREMENTS:');
    if (bodyMeasurements.isEmpty) {
      buffer.writeln('- No measurements recorded');
    } else {
      for (final m in bodyMeasurements.take(5)) {
        final date = m['recorded_at']?.toString().split('T').first ?? 'Unknown';
        final weight = m['weight_kg'];
        final bodyFat = m['body_fat_percent'];
        buffer.writeln(
            '- $date: Weight ${weight ?? 'N/A'}kg, Body Fat ${bodyFat ?? 'N/A'}%');
      }
    }
    if (weightChangeKg != null) {
      buffer.writeln(
          '- Weight change: ${weightChangeKg! > 0 ? '+' : ''}${weightChangeKg!.toStringAsFixed(1)}kg ($weightTrend)');
    }
    buffer.writeln();

    buffer.writeln('PERSONAL RECORDS ACHIEVED:');
    if (personalRecords.isEmpty) {
      buffer.writeln('- No PRs recorded this period');
    } else {
      for (final pr in personalRecords.take(10)) {
        buffer.writeln(
            '- ${pr['exercise_name']}: ${pr['weight_kg']}kg x ${pr['reps']} reps');
      }
    }
    buffer.writeln();

    buffer.writeln('HYDRATION:');
    buffer.writeln('- Daily average: ${(totalWaterMl / 30).round()}ml');
    buffer.writeln('- Goal: ${waterGoalMl}ml/day');
    buffer
        .writeln('- Achievement rate: ${hydrationPercent.toStringAsFixed(0)}%');
    buffer.writeln();

    buffer.writeln('RECOVERY METRICS:');
    buffer.writeln(
        '- Average sleep: ${avgSleepHours.toStringAsFixed(1)} hours/night');
    buffer.writeln('- Average daily steps: $avgSteps');

    return buffer.toString();
  }
}
