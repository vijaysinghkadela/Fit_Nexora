/// AI-generated plan stored in Supabase.
class AiGeneratedPlan {
  final String? id;
  final String memberId;
  final String gymId;
  final DateTime planMonth;
  final String planType; // 'workout', 'diet', 'combined'
  final String? planName;
  final String? planDescription;
  final String planTier;

  // AI outputs (structured JSON)
  final Map<String, dynamic>? bodyAnalysis;
  final Map<String, dynamic>? workoutPlan;
  final Map<String, dynamic>? dietPlan;
  final Map<String, dynamic>? monthlyReport;
  final List<String> tips;
  final String? reasoningContent;

  // Generation metadata
  final String modelUsed;
  final int? tokensUsed;
  final int? generationMs;
  final String? reportPdfUrl;
  final DateTime? createdAt;

  const AiGeneratedPlan({
    this.id,
    required this.memberId,
    required this.gymId,
    required this.planMonth,
    this.planType = 'combined',
    this.planName,
    this.planDescription,
    this.planTier = 'system',
    this.bodyAnalysis,
    this.workoutPlan,
    this.dietPlan,
    this.monthlyReport,
    this.tips = const [],
    this.reasoningContent,
    this.modelUsed = 'moonshotai/kimi-k2-thinking',
    this.tokensUsed,
    this.generationMs,
    this.reportPdfUrl,
    this.createdAt,
  });

  factory AiGeneratedPlan.fromJson(Map<String, dynamic> json) {
    return AiGeneratedPlan(
      id: json['id'] as String?,
      memberId: json['member_id'] as String,
      gymId: json['gym_id'] as String,
      planMonth: DateTime.parse(json['plan_month'] as String),
      planType: json['plan_type'] as String? ?? 'combined',
      planName: json['plan_name'] as String?,
      planDescription: json['plan_description'] as String?,
      planTier: json['plan_tier'] as String? ?? 'system',
      bodyAnalysis: json['body_analysis'] as Map<String, dynamic>?,
      workoutPlan: json['workout_plan'] as Map<String, dynamic>?,
      dietPlan: json['diet_plan'] as Map<String, dynamic>?,
      monthlyReport: json['monthly_report'] as Map<String, dynamic>?,
      tips:
          (json['tips'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              [],
      reasoningContent: json['reasoning_content'] as String?,
      modelUsed: json['model_used'] as String? ?? 'moonshotai/kimi-k2-thinking',
      tokensUsed: json['tokens_used'] as int?,
      generationMs: json['generation_ms'] as int?,
      reportPdfUrl: json['report_pdf_url'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'member_id': memberId,
      'gym_id': gymId,
      'plan_month': planMonth.toIso8601String().split('T').first,
      'plan_type': planType,
      'plan_name': planName,
      'plan_description': planDescription,
      'plan_tier': planTier,
      'body_analysis': bodyAnalysis,
      'workout_plan': workoutPlan,
      'diet_plan': dietPlan,
      'monthly_report': monthlyReport,
      'tips': tips,
      'reasoning_content': reasoningContent,
      'model_used': modelUsed,
      'tokens_used': tokensUsed,
      'generation_ms': generationMs,
    };
  }
}

/// Aggregated visit summary from the `member_visit_summary` view.
class MemberVisitSummary {
  final String memberId;
  final String gymId;
  final int totalVisits;
  final int visitsLast30Days;
  final int visitsLast7Days;
  final DateTime? lastVisit;
  final double avgSessionHrs;

  const MemberVisitSummary({
    required this.memberId,
    required this.gymId,
    this.totalVisits = 0,
    this.visitsLast30Days = 0,
    this.visitsLast7Days = 0,
    this.lastVisit,
    this.avgSessionHrs = 0,
  });

  factory MemberVisitSummary.fromJson(Map<String, dynamic> json) {
    return MemberVisitSummary(
      memberId: json['member_id'] as String,
      gymId: json['gym_id'] as String,
      totalVisits: (json['total_visits'] as num?)?.toInt() ?? 0,
      visitsLast30Days: (json['visits_last_30_days'] as num?)?.toInt() ?? 0,
      visitsLast7Days: (json['visits_last_7_days'] as num?)?.toInt() ?? 0,
      lastVisit: json['last_visit'] != null
          ? DateTime.parse(json['last_visit'] as String)
          : null,
      avgSessionHrs: (json['avg_session_hrs'] as num?)?.toDouble() ?? 0,
    );
  }
}
