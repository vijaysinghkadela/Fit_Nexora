import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_config.dart';
import '../config/ai_agent_prompts.dart';
import '../models/fitness_profile_model.dart';
import '../models/ai_generated_plan_model.dart';

/// FitNexora AI Agent — body analysis, plans, and monthly report pipeline.
///
/// This mirrors the Next.js guide from `FitNexora_AI_Agent_Integration_Guide.md`
/// as a pure Dart service that calls the Anthropic Claude API directly.
class AiAgentService {
  final SupabaseClient _supabase;

  AiAgentService(this._supabase);

  // ─── CORE CLAUDE CALL ───────────────────────────────────────────────────────

  /// Send a prompt to Claude and get the parsed JSON back.
  Future<Map<String, dynamic>> _callClaude({
    required String prompt,
    String model = 'claude-opus-4-5',
    int maxTokens = 4096,
  }) async {
    final startTime = DateTime.now().millisecondsSinceEpoch;

    final response = await http.post(
      Uri.parse('https://api.anthropic.com/v1/messages'),
      headers: {
        'x-api-key': AppConfig.claudeApiKey,
        'anthropic-version': '2023-06-01',
        'content-type': 'application/json',
      },
      body: jsonEncode({
        'model': model,
        'max_tokens': maxTokens,
        'messages': [
          {'role': 'user', 'content': prompt},
        ],
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Claude API error (${response.statusCode}): ${response.body}',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final content = data['content'] as List<dynamic>;
    final rawText =
        content.isNotEmpty ? (content[0] as Map<String, dynamic>)['text'] as String : '{}';

    // Strip markdown fences if Claude adds them
    final cleaned = rawText
        .replaceAll(RegExp(r'```json\n?'), '')
        .replaceAll(RegExp(r'```\n?'), '')
        .trim();

    final usage = data['usage'] as Map<String, dynamic>? ?? {};
    final inputTokens = usage['input_tokens'] as int? ?? 0;
    final outputTokens = usage['output_tokens'] as int? ?? 0;
    final generationMs = DateTime.now().millisecondsSinceEpoch - startTime;

    return {
      'parsed': jsonDecode(cleaned) as Map<String, dynamic>,
      'tokens_used': inputTokens + outputTokens,
      'generation_ms': generationMs,
      'model': model,
    };
  }

  // ─── BODY ANALYSIS ──────────────────────────────────────────────────────────

  /// Analyse a member's body type using Claude.
  Future<Map<String, dynamic>> analyseBodyType(FitnessProfile profile) async {
    final prompt = AiAgentPrompts.buildBodyAnalysisPrompt(profile);
    final result = await _callClaude(prompt: prompt, maxTokens: 1024);
    return result;
  }

  // ─── WORKOUT PLAN ───────────────────────────────────────────────────────────

  /// Generate a 4-week progressive workout plan.
  Future<Map<String, dynamic>> generateWorkoutPlan(
    FitnessProfile profile,
    Map<String, dynamic> bodyAnalysis,
    MemberVisitSummary? visitStats,
  ) async {
    final prompt = AiAgentPrompts.buildWorkoutPlanPrompt(
      profile,
      bodyAnalysis,
      visitStats,
    );
    return await _callClaude(prompt: prompt, maxTokens: 4096);
  }

  // ─── DIET PLAN ──────────────────────────────────────────────────────────────

  /// Generate an Indian-context diet plan.
  Future<Map<String, dynamic>> generateDietPlan(
    FitnessProfile profile,
    Map<String, dynamic> bodyAnalysis,
  ) async {
    final prompt = AiAgentPrompts.buildDietPlanPrompt(profile, bodyAnalysis);
    return await _callClaude(prompt: prompt, maxTokens: 2048);
  }

  // ─── MONTHLY REPORT ─────────────────────────────────────────────────────────

  /// Generate a monthly progress report.
  Future<Map<String, dynamic>> generateMonthlyReport(
    FitnessProfile profile,
    Map<String, dynamic> bodyAnalysis,
    MemberVisitSummary? visitStats,
  ) async {
    final prompt = AiAgentPrompts.buildMonthlyReportPrompt(
      profile,
      bodyAnalysis,
      visitStats,
    );
    return await _callClaude(prompt: prompt, maxTokens: 2048);
  }

  // ─── FULL PIPELINE ──────────────────────────────────────────────────────────

  /// Run the complete AI agent pipeline for a member:
  /// 1. Fetch fitness profile
  /// 2. Fetch visit stats
  /// 3. Body analysis
  /// 4. Workout plan + Diet plan (parallel)
  /// 5. Monthly report
  /// 6. Save to Supabase
  ///
  /// Returns the saved [AiGeneratedPlan].
  Future<AiGeneratedPlan> generateMemberReport({
    required String memberId,
    required String gymId,
  }) async {
    debugPrint('🤖 [AiAgent] Starting pipeline for member=$memberId gym=$gymId');

    // 0. Rate limit — max 1 report per member per day
    await _enforceRateLimit(memberId);

    // 1. Fetch fitness profile
    final profileData = await _supabase
        .from('member_fitness_profiles')
        .select()
        .eq('member_id', memberId)
        .eq('gym_id', gymId)
        .maybeSingle();

    if (profileData == null) {
      throw Exception('No fitness profile found for member $memberId in gym $gymId');
    }
    final profile = FitnessProfile.fromJson(profileData);

    // 2. Fetch visit stats
    MemberVisitSummary? visitStats;
    try {
      final visitData = await _supabase
          .from('member_visit_summary')
          .select()
          .eq('member_id', memberId)
          .eq('gym_id', gymId)
          .maybeSingle();
      if (visitData != null) {
        visitStats = MemberVisitSummary.fromJson(visitData);
      }
    } catch (e) {
      debugPrint('⚠️ [AiAgent] Could not fetch visit stats: $e');
    }

    // 3. Body analysis
    debugPrint('🤖 [AiAgent] Step 1/4: Body analysis...');
    final bodyResult = await analyseBodyType(profile);
    final bodyAnalysis = bodyResult['parsed'] as Map<String, dynamic>;
    int totalTokens = bodyResult['tokens_used'] as int;

    // 4. Workout + Diet (parallel)
    debugPrint('🤖 [AiAgent] Step 2-3/4: Workout + Diet plans (parallel)...');
    final results = await Future.wait([
      generateWorkoutPlan(profile, bodyAnalysis, visitStats),
      generateDietPlan(profile, bodyAnalysis),
    ]);

    final workoutResult = results[0];
    final dietResult = results[1];
    final workoutPlan = workoutResult['parsed'] as Map<String, dynamic>;
    final dietPlan = dietResult['parsed'] as Map<String, dynamic>;
    totalTokens += (workoutResult['tokens_used'] as int) +
        (dietResult['tokens_used'] as int);

    // 5. Monthly report
    debugPrint('🤖 [AiAgent] Step 4/4: Monthly report...');
    final reportResult = await generateMonthlyReport(
      profile,
      bodyAnalysis,
      visitStats,
    );
    final monthlyReport = reportResult['parsed'] as Map<String, dynamic>;
    totalTokens += reportResult['tokens_used'] as int;

    // 6. Build full plan object
    final now = DateTime.now();
    final planMonth = DateTime(now.year, now.month, 1);

    final plan = AiGeneratedPlan(
      memberId: memberId,
      gymId: gymId,
      planMonth: planMonth,
      planType: 'combined',
      bodyAnalysis: bodyAnalysis,
      workoutPlan: workoutPlan,
      dietPlan: dietPlan,
      monthlyReport: monthlyReport,
      tips: (monthlyReport['trainer_recommendations'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      modelUsed: 'claude-opus-4-5',
      tokensUsed: totalTokens,
      generationMs:
          (bodyResult['generation_ms'] as int) +
          (workoutResult['generation_ms'] as int) +
          (dietResult['generation_ms'] as int) +
          (reportResult['generation_ms'] as int),
    );

    // 7. Save to Supabase
    final savedData = await _supabase
        .from('ai_generated_plans')
        .insert(plan.toInsertJson())
        .select()
        .single();

    debugPrint('✅ [AiAgent] Pipeline complete — saved as ${savedData['id']}');

    return AiGeneratedPlan.fromJson(savedData);
  }

  // ─── HELPERS ────────────────────────────────────────────────────────────────

  /// Enforce a max of 1 report per member per day.
  Future<void> _enforceRateLimit(String memberId) async {
    final since =
        DateTime.now().subtract(const Duration(hours: 24)).toUtc().toIso8601String();

    final count = await _supabase
        .from('ai_generated_plans')
        .select()
        .eq('member_id', memberId)
        .gte('created_at', since)
        .count(CountOption.exact);

    if (count.count >= 1) {
      throw Exception(
        'Rate limit: A report was already generated for this member today. '
        'Please try again tomorrow.',
      );
    }
  }

  // ─── DATA ACCESS ────────────────────────────────────────────────────────────

  /// Fetch the fitness profile for a member in a gym.
  Future<FitnessProfile?> getFitnessProfile(String memberId, String gymId) async {
    final data = await _supabase
        .from('member_fitness_profiles')
        .select()
        .eq('member_id', memberId)
        .eq('gym_id', gymId)
        .maybeSingle();
    return data != null ? FitnessProfile.fromJson(data) : null;
  }

  /// Upsert a fitness profile (insert or update).
  Future<FitnessProfile> saveFitnessProfile(FitnessProfile profile) async {
    final data = await _supabase
        .from('member_fitness_profiles')
        .upsert(profile.toJson(), onConflict: 'member_id,gym_id')
        .select()
        .single();
    return FitnessProfile.fromJson(data);
  }

  /// Fetch previous AI-generated plans for a member (newest first).
  Future<List<AiGeneratedPlan>> getGeneratedPlans(
    String memberId,
    String gymId, {
    int limit = 10,
  }) async {
    final data = await _supabase
        .from('ai_generated_plans')
        .select()
        .eq('member_id', memberId)
        .eq('gym_id', gymId)
        .order('created_at', ascending: false)
        .limit(limit);
    return data.map((json) => AiGeneratedPlan.fromJson(json)).toList();
  }
}
