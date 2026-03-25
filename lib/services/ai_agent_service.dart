import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/ai_agent_prompts.dart';
import '../config/app_config.dart';
import '../core/constants.dart';
import '../core/enums.dart';
import '../models/ai_generated_plan_model.dart';
import '../models/ai_generation_request_model.dart';
import '../models/client_profile_model.dart';
import '../models/fitness_profile_model.dart';
import '../models/workout_plan_model.dart';
import '../services/ai_prompt_builder.dart';

/// FitNexora AI Agent — body analysis, plans, chat, and progress reporting.
///
/// This runtime is standardized on NVIDIA-hosted Kimi (`moonshotai/kimi-k2-thinking`)
/// via NVIDIA's OpenAI-compatible chat completion endpoint.
class AiAgentService {
  static const String defaultModel = 'moonshotai/kimi-k2-thinking';
  static const String _chatEndpoint =
      'https://integrate.api.nvidia.com/v1/chat/completions';

  final SupabaseClient _supabase;
  final http.Client _httpClient;

  AiAgentService(
    this._supabase, {
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  // ─── CORE NVIDIA KIMI CALL ────────────────────────────────────────────────

  Future<NvidiaChatResult> _callNvidiaChat({
    required List<Map<String, dynamic>> messages,
    String model = defaultModel,
    int maxTokens = 4096,
    double temperature = 1.0,
  }) async {
    if (AppConfig.nvidiaApiKey.isEmpty) {
      throw Exception(
        'Missing NVIDIA_API_KEY in assets/app.env. '
        'Add the key before using AI features.',
      );
    }

    final startedAt = DateTime.now().millisecondsSinceEpoch;
    final response = await _httpClient.post(
      Uri.parse(_chatEndpoint),
      headers: {
        'Authorization': 'Bearer ${AppConfig.nvidiaApiKey}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': model,
        'messages': messages,
        'max_tokens': maxTokens,
        'temperature': temperature,
        'stream': false,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'NVIDIA Kimi API error (${response.statusCode}): ${response.body}',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return parseNvidiaChatPayload(
      data,
      fallbackModel: model,
      generationMs: DateTime.now().millisecondsSinceEpoch - startedAt,
    );
  }

  Future<Map<String, dynamic>> _callStructuredJson({
    required String prompt,
    String? systemPrompt,
    int maxTokens = 4096,
  }) async {
    final messages = <Map<String, dynamic>>[
      if (systemPrompt != null && systemPrompt.trim().isNotEmpty)
        {'role': 'system', 'content': systemPrompt},
      {'role': 'user', 'content': prompt},
    ];

    final result = await _callNvidiaChat(
      messages: messages,
      maxTokens: maxTokens,
    );

    return {
      'parsed': decodeJsonObject(result.content),
      'tokens_used': result.tokensUsed,
      'generation_ms': result.generationMs,
      'model': result.model,
      'reasoning_content': result.reasoningContent,
    };
  }

  /// Parse the OpenAI-compatible NVIDIA chat payload.
  @visibleForTesting
  static NvidiaChatResult parseNvidiaChatPayload(
    Map<String, dynamic> data, {
    required String fallbackModel,
    required int generationMs,
  }) {
    final choices = data['choices'] as List<dynamic>? ?? const [];
    final firstChoice =
        choices.isNotEmpty && choices.first is Map<String, dynamic>
            ? choices.first as Map<String, dynamic>
            : const <String, dynamic>{};
    final message = firstChoice['message'] as Map<String, dynamic>? ??
        const <String, dynamic>{};

    final usage = data['usage'] as Map<String, dynamic>? ?? const {};
    final promptTokens = _asInt(
      usage['prompt_tokens'] ?? usage['input_tokens'],
    );
    final completionTokens = _asInt(
      usage['completion_tokens'] ?? usage['output_tokens'],
    );
    final totalTokens = _asInt(
      usage['total_tokens'],
      fallback: promptTokens + completionTokens,
    );

    return NvidiaChatResult(
      content: extractMessageText(message['content']),
      reasoningContent: extractMessageText(message['reasoning_content']),
      tokensUsed: totalTokens,
      model: data['model'] as String? ??
          message['model'] as String? ??
          fallbackModel,
      generationMs: generationMs,
    );
  }

  @visibleForTesting
  static String extractMessageText(dynamic content) {
    if (content == null) return '';
    if (content is String) return content.trim();
    if (content is List) {
      final buffer = StringBuffer();
      for (final part in content) {
        if (part is String) {
          if (buffer.isNotEmpty) buffer.writeln();
          buffer.write(part.trim());
          continue;
        }
        if (part is Map<String, dynamic>) {
          final text = part['text'] ?? part['content'] ?? part['value'];
          final normalized = extractMessageText(text);
          if (normalized.isEmpty) continue;
          if (buffer.isNotEmpty) buffer.writeln();
          buffer.write(normalized);
        }
      }
      return buffer.toString().trim();
    }
    return content.toString().trim();
  }

  @visibleForTesting
  static Map<String, dynamic> decodeJsonObject(String rawText) {
    final direct = _decodeJsonCandidate(rawText);
    if (direct != null) return direct;

    final fenced = rawText
        .replaceFirst(RegExp(r'^```(?:json)?\s*'), '')
        .replaceFirst(RegExp(r'\s*```$'), '')
        .trim();
    final unfenced = _decodeJsonCandidate(fenced);
    if (unfenced != null) return unfenced;

    final jsonStart = rawText.indexOf('{');
    final jsonEnd = rawText.lastIndexOf('}');
    if (jsonStart >= 0 && jsonEnd > jsonStart) {
      final substring = rawText.substring(jsonStart, jsonEnd + 1);
      final embedded = _decodeJsonCandidate(substring);
      if (embedded != null) return embedded;
    }

    return {'raw_text': rawText.trim()};
  }

  static Map<String, dynamic>? _decodeJsonCandidate(String candidate) {
    final trimmed = candidate.trim();
    if (trimmed.isEmpty) return null;
    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  static int _asInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return fallback;
  }

  // ─── BODY ANALYSIS ────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> analyseBodyType(FitnessProfile profile) async {
    final prompt = AiAgentPrompts.buildBodyAnalysisPrompt(profile);
    return _callStructuredJson(prompt: prompt, maxTokens: 1024);
  }

  // ─── WORKOUT PLAN ─────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> generateWorkoutPlan(
    FitnessProfile profile,
    Map<String, dynamic> bodyAnalysis,
    MemberVisitSummary? visitStats, {
    String? planObjective,
    String? planName,
    String? planDescription,
    String? supplementaryContext,
  }) async {
    var prompt = AiAgentPrompts.buildWorkoutPlanPrompt(
      profile,
      bodyAnalysis,
      visitStats,
      planObjective: planObjective,
      planName: planName,
      planDescription: planDescription,
    );
    if (supplementaryContext != null &&
        supplementaryContext.trim().isNotEmpty) {
      prompt =
          '$prompt\n\nSUPPLEMENTARY MEMBER CONTEXT:\n$supplementaryContext';
    }
    return _callStructuredJson(prompt: prompt, maxTokens: 4096);
  }

  // ─── DIET PLAN ────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> generateDietPlan(
    FitnessProfile profile,
    Map<String, dynamic> bodyAnalysis, {
    String? planObjective,
    String? planName,
    String? planDescription,
    String? supplementaryContext,
  }) async {
    var prompt = AiAgentPrompts.buildDietPlanPrompt(
      profile,
      bodyAnalysis,
      planObjective: planObjective,
      planName: planName,
      planDescription: planDescription,
    );
    if (supplementaryContext != null &&
        supplementaryContext.trim().isNotEmpty) {
      prompt =
          '$prompt\n\nSUPPLEMENTARY MEMBER CONTEXT:\n$supplementaryContext';
    }
    return _callStructuredJson(prompt: prompt, maxTokens: 3072);
  }

  // ─── MONTHLY REPORT ───────────────────────────────────────────────────────

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
    return _callStructuredJson(prompt: prompt, maxTokens: 2048);
  }

  // ─── SHARED CHAT ──────────────────────────────────────────────────────────

  Future<String> generateChatReply({
    required ClientProfile client,
    required UserRole role,
    required String userMessage,
    List<Map<String, String>> conversationHistory = const [],
    int maxTokens = 2048,
  }) async {
    final systemPrompt = await AiPromptBuilder.buildPrompt(
      role: role,
      client: client,
    );

    final messages = <Map<String, dynamic>>[
      {'role': 'system', 'content': systemPrompt},
      ...conversationHistory.map(
        (message) => {
          'role': message['role'] ?? 'user',
          'content': message['content'] ?? '',
        },
      ),
      {'role': 'user', 'content': userMessage},
    ];

    final result = await _callNvidiaChat(
      messages: messages,
      maxTokens: maxTokens,
    );
    return result.content;
  }

  // ─── FULL PIPELINE ────────────────────────────────────────────────────────

  Future<AiGeneratedPlan> generateMemberReport({
    required String memberId,
    required String gymId,
    AiGenerationRequest? request,
    bool enforceRateLimit = true,
  }) async {
    debugPrint(
        '🤖 [AiAgent] Starting pipeline for member=$memberId gym=$gymId');

    if (enforceRateLimit) {
      await _enforceRateLimit(memberId);
    }

    // Resolve profile: prefer request, then DB, else synthesize a default profile
    late final FitnessProfile profile;
    if (request?.fitnessProfile != null) {
      profile = request!.fitnessProfile!;
    } else {
      final dbProfile = await getFitnessProfile(memberId, gymId);
      if (dbProfile != null) {
        profile = dbProfile;
      } else {
        // Synthesize a safe default profile for testing/gating flows
        profile = FitnessProfile(
          memberId: memberId,
          gymId: gymId,
          heightCm: 170,
          weightKg: 70,
          age: 25,
          fitnessLevel: 'beginner',
          primaryGoal: 'general_fitness',
          availableDays: 5,
        );
      }
    }

    if (request != null) {
      await saveFitnessProfile(profile);
    }

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

    final bodyResult = await analyseBodyType(profile);
    final bodyAnalysis = bodyResult['parsed'] as Map<String, dynamic>;
    int totalTokens = bodyResult['tokens_used'] as int? ?? 0;
    int totalGenerationMs = bodyResult['generation_ms'] as int? ?? 0;
    final reasoningSegments = <String>[
      if ((bodyResult['reasoning_content'] as String?)?.trim().isNotEmpty ==
          true)
        (bodyResult['reasoning_content'] as String).trim(),
    ];

    final planResults = await Future.wait([
      generateWorkoutPlan(
        profile,
        bodyAnalysis,
        visitStats,
        planObjective: request?.planObjective,
        planName: request?.planName,
        planDescription: request?.planDescription,
        supplementaryContext: request?.supplementaryProfileContext,
      ),
      generateDietPlan(
        profile,
        bodyAnalysis,
        planObjective: request?.planObjective,
        planName: request?.planName,
        planDescription: request?.planDescription,
        supplementaryContext: request?.supplementaryProfileContext,
      ),
    ]);

    final workoutResult = planResults[0];
    final dietResult = planResults[1];
    final workoutPlan = workoutResult['parsed'] as Map<String, dynamic>;
    final dietPlan = dietResult['parsed'] as Map<String, dynamic>;

    totalTokens += (workoutResult['tokens_used'] as int? ?? 0) +
        (dietResult['tokens_used'] as int? ?? 0);
    totalGenerationMs += (workoutResult['generation_ms'] as int? ?? 0) +
        (dietResult['generation_ms'] as int? ?? 0);

    final workoutReasoning = workoutResult['reasoning_content'] as String?;
    if (workoutReasoning != null && workoutReasoning.trim().isNotEmpty) {
      reasoningSegments.add(workoutReasoning.trim());
    }

    final dietReasoning = dietResult['reasoning_content'] as String?;
    if (dietReasoning != null && dietReasoning.trim().isNotEmpty) {
      reasoningSegments.add(dietReasoning.trim());
    }

    final reportResult = await generateMonthlyReport(
      profile,
      bodyAnalysis,
      visitStats,
    );
    final monthlyReport = reportResult['parsed'] as Map<String, dynamic>;
    totalTokens += reportResult['tokens_used'] as int? ?? 0;
    totalGenerationMs += reportResult['generation_ms'] as int? ?? 0;

    final reportReasoning = reportResult['reasoning_content'] as String?;
    if (reportReasoning != null && reportReasoning.trim().isNotEmpty) {
      reasoningSegments.add(reportReasoning.trim());
    }

    final now = DateTime.now();
    final planMonth = DateTime(now.year, now.month, 1);
    final resolvedPlanName = request?.planName.trim().isNotEmpty == true
        ? request!.planName.trim()
        : (workoutPlan['plan_name'] as String?) ??
            (dietPlan['plan_name'] as String?);
    final resolvedPlanDescription =
        request?.planDescription.trim().isNotEmpty == true
            ? request!.planDescription.trim()
            : (workoutPlan['plan_summary'] as String?) ??
                (dietPlan['plan_summary'] as String?);
    final trainerRecommendations =
        monthlyReport['trainer_recommendations'] as List<dynamic>?;

    final plan = AiGeneratedPlan(
      memberId: memberId,
      gymId: gymId,
      planMonth: planMonth,
      planType: 'combined',
      planName: resolvedPlanName,
      planDescription: resolvedPlanDescription,
      planTier: request?.planTier ?? 'system',
      bodyAnalysis: bodyAnalysis,
      workoutPlan: workoutPlan,
      dietPlan: dietPlan,
      monthlyReport: monthlyReport,
      tips: trainerRecommendations?.map((e) => e.toString()).toList() ?? [],
      reasoningContent: reasoningSegments.join('\n\n').trim(),
      modelUsed: defaultModel,
      tokensUsed: totalTokens,
      generationMs: totalGenerationMs,
    );

    final savedData = await _supabase
        .from('ai_generated_plans')
        .insert(plan.toInsertJson())
        .select()
        .single();

    final savedPlan = AiGeneratedPlan.fromJson(savedData);

    final publishRequest =
        (request != null && request.publishToActivePlans) ? request : null;
    if (publishRequest != null) {
      final clientId = await _resolveClientId(memberId: memberId, gymId: gymId);
      await Future.wait([
        _publishWorkoutPlan(
          clientId: clientId,
          gymId: gymId,
          request: publishRequest,
          generatedPlan: savedPlan,
        ),
        _publishDietPlan(
          clientId: clientId,
          gymId: gymId,
          request: publishRequest,
          generatedPlan: savedPlan,
        ),
      ]);
    }

    debugPrint('✅ [AiAgent] Pipeline complete — saved as ${savedPlan.id}');
    return savedPlan;
  }

  Future<AiGeneratedPlan> generateProPlan({
    required String memberId,
    required String gymId,
    required AiGenerationRequest request,
  }) {
    return generateMemberReport(
      memberId: memberId,
      gymId: gymId,
      request: request,
      enforceRateLimit: false,
    );
  }

  // ─── HELPERS ──────────────────────────────────────────────────────────────

  Future<void> _publishWorkoutPlan({
    required String clientId,
    required String gymId,
    required AiGenerationRequest request,
    required AiGeneratedPlan generatedPlan,
  }) async {
    final workoutPlan = generatedPlan.workoutPlan ?? const {};
    final weeks = workoutPlan['weeks'] as List<dynamic>? ?? const [];
    final firstWeek = weeks.isNotEmpty && weeks.first is Map<String, dynamic>
        ? weeks.first as Map<String, dynamic>
        : const <String, dynamic>{};
    final days = firstWeek['days'] as List<dynamic>? ?? const [];

    final payload = {
      'gym_id': gymId,
      'client_id': clientId,
      'trainer_id': null,
      'name': generatedPlan.planName ?? request.planName,
      'description': generatedPlan.planDescription ?? request.planDescription,
      'goal': request.planObjective,
      'duration_weeks': weeks.isEmpty ? 4 : weeks.length,
      'current_week': 1,
      'phase':
          firstWeek['theme'] ?? workoutPlan['weekly_structure'] ?? 'AI Plan',
      'athlete_type': generatedPlan.bodyAnalysis?['somatotype'] ?? 'General',
      'days': _convertTrainingDays(days),
      'status': PlanStatus.active.value,
      'is_template': false,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };

    await _supabase
        .from(AppConstants.workoutPlansTable)
        .insert(payload)
        .select()
        .single();
  }

  Future<void> _publishDietPlan({
    required String clientId,
    required String gymId,
    required AiGenerationRequest request,
    required AiGeneratedPlan generatedPlan,
  }) async {
    final dietPlan = generatedPlan.dietPlan ?? const {};
    final dailyTemplate =
        dietPlan['daily_template'] as Map<String, dynamic>? ?? const {};

    final payload = {
      'gym_id': gymId,
      'client_id': clientId,
      'trainer_id': null,
      'name': generatedPlan.planName ?? request.planName,
      'description': generatedPlan.planDescription ?? request.planDescription,
      'goal': request.planObjective,
      'target_calories': _asInt(dietPlan['calorie_target'], fallback: 2000),
      'target_protein': _asInt(dietPlan['protein_g'], fallback: 150),
      'target_carbs': _asInt(dietPlan['carbs_g'], fallback: 200),
      'target_fat': _asInt(
        dietPlan['fat_g'] ?? dietPlan['fats_g'],
        fallback: 65,
      ),
      'hydration_liters':
          (dietPlan['hydration_target_litres'] as num?)?.toDouble() ?? 3.0,
      'meals': _convertMeals(dailyTemplate),
      'status': PlanStatus.active.value,
      'is_template': false,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };

    await _supabase
        .from(AppConstants.dietPlansTable)
        .insert(payload)
        .select()
        .single();
  }

  List<Map<String, dynamic>> _convertTrainingDays(List<dynamic> rawDays) {
    return rawDays.asMap().entries.map((entry) {
      final day = entry.value as Map<String, dynamic>;
      final exercises = day['exercises'] as List<dynamic>? ?? const [];
      return {
        'day_name': day['day'] ?? 'Day ${entry.key + 1}',
        'muscle_group': (day['focus'] ?? '').toString().toLowerCase(),
        'day_index': entry.key,
        'notes': day['cardio'] ?? day['notes'],
        'exercises': exercises.asMap().entries.map((exerciseEntry) {
          final exercise = exerciseEntry.value as Map<String, dynamic>;
          return {
            'name': exercise['name'] ?? 'Exercise',
            'sets': _asInt(exercise['sets'], fallback: 3),
            'reps': (exercise['reps'] ?? '10').toString(),
            'rest_seconds': _asInt(exercise['rest_seconds'], fallback: 60),
            'tempo': exercise['tempo'],
            'equipment': exercise['equipment'],
            'cue': exercise['cue'],
            'substitute': exercise['substitute'],
            'rpe': _asInt(exercise['rpe']),
            'order_index': exerciseEntry.key,
          };
        }).toList(),
      };
    }).toList();
  }

  List<Map<String, dynamic>> _convertMeals(
    Map<String, dynamic> dailyTemplate,
  ) {
    final meals = <Map<String, dynamic>>[];
    final entries = dailyTemplate.entries.toList();
    for (var index = 0; index < entries.length; index++) {
      final mealEntry = entries[index];
      final mealData = mealEntry.value as Map<String, dynamic>? ?? const {};
      final items = mealData['items'] as List<dynamic>? ?? const [];
      meals.add({
        'name': _formatMealName(mealEntry.key),
        'timing': mealData['time'] ?? '',
        'order_index': index,
        'notes': mealData['notes'],
        'foods': items.map((item) {
          final food = item as Map<String, dynamic>;
          return {
            'name': food['food'] ?? 'Meal item',
            'quantity': food['quantity'] ?? '',
            'protein': _asInt(food['protein_g']),
            'carbs': _asInt(food['carbs_g']),
            'fat': _asInt(food['fat_g']),
            'calories': _asInt(food['calories']),
            'is_indian': true,
          };
        }).toList(),
      });
    }
    return meals;
  }

  String _formatMealName(String key) {
    return key
        .split('_')
        .map(
          (part) => part.isEmpty
              ? part
              : '${part[0].toUpperCase()}${part.substring(1)}',
        )
        .join(' ');
  }

  Future<String> _resolveClientId({
    required String memberId,
    required String gymId,
  }) async {
    final client = await _supabase
        .from(AppConstants.clientsTable)
        .select('id')
        .eq('user_id', memberId)
        .eq('gym_id', gymId)
        .maybeSingle();

    final clientId = client?['id'] as String?;
    if (clientId == null || clientId.isEmpty) {
      throw Exception(
        'Could not resolve the member client profile for published plans.',
      );
    }
    return clientId;
  }

  Future<void> _enforceRateLimit(String memberId) async {
    final since = DateTime.now()
        .subtract(const Duration(hours: 24))
        .toUtc()
        .toIso8601String();

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

  // ─── DATA ACCESS ──────────────────────────────────────────────────────────

  Future<FitnessProfile?> getFitnessProfile(
    String memberId,
    String gymId,
  ) async {
    final data = await _supabase
        .from('member_fitness_profiles')
        .select()
        .eq('member_id', memberId)
        .eq('gym_id', gymId)
        .maybeSingle();
    return data != null ? FitnessProfile.fromJson(data) : null;
  }

  Future<FitnessProfile> saveFitnessProfile(FitnessProfile profile) async {
    final data = await _supabase
        .from('member_fitness_profiles')
        .upsert(profile.toJson(), onConflict: 'member_id,gym_id')
        .select()
        .single();
    return FitnessProfile.fromJson(data);
  }

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

class NvidiaChatResult {
  final String content;
  final String? reasoningContent;
  final int tokensUsed;
  final String model;
  final int generationMs;

  const NvidiaChatResult({
    required this.content,
    required this.reasoningContent,
    required this.tokensUsed,
    required this.model,
    required this.generationMs,
  });
}
