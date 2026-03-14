import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../config/plan_limits.dart';
import '../core/enums.dart';
import '../models/client_profile_model.dart';
import 'ai_prompt_builder.dart';

// ─── MASTER SYSTEM PROMPT ────────────────────────────────────────────────────
String? _masterSystemPrompt;

/// Load the master system prompt. Call once at app startup.
/// Falls back to empty string if the asset file is missing.
Future<void> loadMasterPrompt() async {
  if (_masterSystemPrompt != null) return;
  try {
    _masterSystemPrompt =
        await rootBundle.loadString('lib/config/ai_system_prompt.txt');
  } catch (_) {
    _masterSystemPrompt = '';
  }
}

/// The cached master prompt.
String get masterSystemPrompt => _masterSystemPrompt ?? '';

// ─── MODEL ROUTING (Quota-Aware) ─────────────────────────────────────────────

/// Select the correct model based on gym plan + quota remaining.
///
/// Basic → throws (no AI)
/// Elite + quota remaining → claude-opus-4-5
/// Pro | Elite over quota  → claude-haiku-4-5-20251001
String _selectModel(String plan, int quotaRemaining) {
  if (plan == 'basic') {
    throw AiAccessDeniedException('AI not available on Basic plan');
  }
  if (plan == 'elite' && quotaRemaining > 0) return 'claude-opus-4-5';
  return 'claude-haiku-4-5-20251001'; // Pro default or Elite overage
}

// ─── CORE AI FUNCTION ────────────────────────────────────────────────────────

/// The core GymOS AI function — call this for ALL Claude API interactions.
///
/// ```dart
/// final response = await gymOSAI(
///   client: clientProfile,
///   userRole: 'Trainer',
///   userMessage: 'Generate a plan for this client',
/// );
/// ```
Future<String> gymOSAI({
  required ClientProfile client,
  required String userRole,
  required String userMessage,
  List<Map<String, String>> conversationHistory = const [],
}) async {
  // Route to correct model based on gym plan
  final model = _selectModel(
    client.gymPlan ?? 'basic',
    client.aiQuotaRemaining ?? 0,
  );

  final response = await http.post(
    Uri.parse('https://api.anthropic.com/v1/messages'),
    headers: {
      'x-api-key': AppConfig.claudeApiKey,
      'anthropic-version': '2023-06-01',
      'content-type': 'application/json',
    },
    body: jsonEncode({
      'model': model,
      'max_tokens': 4096,
      'system': masterSystemPrompt,
      'messages': [
        ...conversationHistory,
        {
          'role': 'user',
          'content': '''
ACTIVE ROLE: $userRole
CLIENT PROFILE:
${client.toProfileBlock()}
USER MESSAGE: $userMessage
          '''
        }
      ],
    }),
  );

  if (response.statusCode != 200) {
    throw AiApiException(
      'Claude API error (${response.statusCode}): ${response.body}',
      statusCode: response.statusCode,
    );
  }

  final data = jsonDecode(response.body);
  return data['content'][0]['text'];
}

// ─── TRACKED VARIANT ─────────────────────────────────────────────────────────

/// Plan-tier-aware variant with PlanLimits enforcement + token tracking.
Future<ClaudeResponse> gymOSAIWithTracking({
  required ClientProfile client,
  required String userRole,
  required String userMessage,
  required PlanTier planTier,
  AiRequestType requestType = AiRequestType.quickQuestion,
  required int usedOpusCalls,
  required int usedHaikuCalls,
  required int usedTokens,
  List<Map<String, String>> conversationHistory = const [],
}) async {
  // Pre-flight check using PlanLimits
  final decision = PlanLimits.canMakeAiCall(
    tier: planTier,
    usedOpusCalls: usedOpusCalls,
    usedHaikuCalls: usedHaikuCalls,
    usedTokens: usedTokens,
    requestsOpus: requestType == AiRequestType.fullPlanGeneration ||
        requestType == AiRequestType.progressAnalysis ||
        requestType == AiRequestType.businessIntelligence,
  );

  if (!decision.isAllowed) {
    throw AiAccessDeniedException(decision.reason ?? 'AI access denied.');
  }

  // Get model from decision (respects downgrades)
  final model = decision.model == 'opus'
      ? 'claude-opus-4-5'
      : 'claude-haiku-4-5-20251001';

  // Build system prompt with context
  final systemPrompt = await AiPromptBuilder.buildPrompt(
    role: UserRole.fromString(userRole.toLowerCase().replaceAll(' ', '_')),
    client: client,
  );

  final response = await http.post(
    Uri.parse('https://api.anthropic.com/v1/messages'),
    headers: {
      'x-api-key': AppConfig.claudeApiKey,
      'anthropic-version': '2023-06-01',
      'content-type': 'application/json',
    },
    body: jsonEncode({
      'model': model,
      'max_tokens': 4096,
      'system': systemPrompt,
      'messages': [
        ...conversationHistory,
        {
          'role': 'user',
          'content': '''
ACTIVE ROLE: $userRole
CLIENT PROFILE:
${client.toProfileBlock()}
USER MESSAGE: $userMessage
          '''
        }
      ],
    }),
  );

  if (response.statusCode != 200) {
    throw AiApiException(
      'Claude API error (${response.statusCode}): ${response.body}',
      statusCode: response.statusCode,
    );
  }

  final data = jsonDecode(response.body) as Map<String, dynamic>;
  final content = data['content'] as List<dynamic>;
  final text = content.isNotEmpty
      ? (content[0] as Map<String, dynamic>)['text'] as String
      : '';

  final usage = data['usage'] as Map<String, dynamic>? ?? {};
  final inputTokens = usage['input_tokens'] as int? ?? 0;
  final outputTokens = usage['output_tokens'] as int? ?? 0;

  return ClaudeResponse(
    text: text,
    model: model,
    inputTokens: inputTokens,
    outputTokens: outputTokens,
    isDowngraded: decision.isDowngraded,
    hasOverage: decision.hasOverage,
    overageCost: decision.overageCost,
  );
}

// ─── CONVENIENCE FUNCTIONS ───────────────────────────────────────────────────

/// Generate a full workout + diet plan.
Future<String> generatePlan(ClientProfile client, {String extra = ''}) {
  return gymOSAI(
    client: client,
    userRole: 'Trainer',
    userMessage:
        'Generate a complete workout and nutrition plan. $extra'.trim(),
  );
}

/// Analyze progress from check-in data.
Future<String> analyzeProgress(ClientProfile client, String checkInData) {
  return gymOSAI(
    client: client,
    userRole: 'Trainer',
    userMessage: 'Analyze this progress check-in:\n$checkInData',
  );
}

/// Get exercise or food substitution.
Future<String> getSubstitution(
    ClientProfile client, String item, String reason) {
  return gymOSAI(
    client: client,
    userRole: 'Client',
    userMessage: 'I need a substitute for "$item". Reason: $reason',
  );
}

/// Get supplement recommendation.
Future<String> getSupplementAdvice(ClientProfile client) {
  return gymOSAI(
    client: client,
    userRole: 'Trainer',
    userMessage: 'Provide evidence-based supplement stack for this client.',
  );
}

/// Elite-only AI chat.
Future<String> clientChat(
  ClientProfile client,
  String message, {
  List<Map<String, String>> history = const [],
}) {
  if (client.gymPlan != 'elite') {
    throw AiAccessDeniedException(
        'AI Chat is available exclusively on the Elite plan.');
  }
  return gymOSAI(
    client: client,
    userRole: 'Client',
    userMessage: message,
    conversationHistory: history,
  );
}

// ─── RESPONSE MODEL ──────────────────────────────────────────────────────────

class ClaudeResponse {
  final String text;
  final String model;
  final int inputTokens;
  final int outputTokens;
  final bool isDowngraded;
  final bool hasOverage;
  final double? overageCost;

  const ClaudeResponse({
    required this.text,
    required this.model,
    this.inputTokens = 0,
    this.outputTokens = 0,
    this.isDowngraded = false,
    this.hasOverage = false,
    this.overageCost,
  });

  int get totalTokens => inputTokens + outputTokens;

  /// Rough cost in USD.
  double get estimatedCost {
    if (model.contains('opus')) {
      return (inputTokens * 15 + outputTokens * 75) / 1000000;
    }
    return (inputTokens * 0.25 + outputTokens * 1.25) / 1000000;
  }
}

// ─── EXCEPTIONS ──────────────────────────────────────────────────────────────

class AiAccessDeniedException implements Exception {
  final String message;
  const AiAccessDeniedException(this.message);
  @override
  String toString() => 'AiAccessDeniedException: $message';
}

class AiApiException implements Exception {
  final String message;
  final int statusCode;
  const AiApiException(this.message, {this.statusCode = 0});
  @override
  String toString() => 'AiApiException($statusCode): $message';
}
