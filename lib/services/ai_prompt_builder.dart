import 'package:flutter/services.dart' show rootBundle;
import '../core/enums.dart';
import '../models/client_profile_model.dart';

/// Manages the AI system prompt and context injection for Claude API calls.
class AiPromptBuilder {
  static String? _cachedSystemPrompt;

  /// Load the master system prompt from assets.
  /// Falls back to empty string if the asset file is missing.
  static Future<String> loadSystemPrompt() async {
    if (_cachedSystemPrompt != null) return _cachedSystemPrompt!;
    try {
      _cachedSystemPrompt =
          await rootBundle.loadString('lib/config/ai_system_prompt.txt');
    } catch (_) {
      _cachedSystemPrompt = '';
    }
    return _cachedSystemPrompt!;
  }

  /// Build the complete system message for a Claude API call.
  ///
  /// Injects the role context and client profile data into the master prompt.
  static Future<String> buildPrompt({
    required UserRole role,
    ClientProfile? client,
    Map<String, dynamic>? gymStats,
    String? trainerName,
    DateTime? subscriptionExpiry,
  }) async {
    final systemPrompt = await loadSystemPrompt();
    final parts = <String>[systemPrompt];

    // Inject role context
    parts.add('\n\n═══ CURRENT SESSION CONTEXT ═══');
    parts.add('Active Role: ${role.label}');

    // Inject client profile if available
    if (client != null) {
      parts.add('\n═══ CLIENT PROFILE ═══');
      parts.add(client.toAiContext());

      if (subscriptionExpiry != null) {
        parts.add(
            'Subscription Expiry: ${subscriptionExpiry.toIso8601String().split('T').first}');
      }
    }

    // Inject gym stats for owner/admin
    if (gymStats != null &&
        (role == UserRole.gymOwner || role == UserRole.superAdmin)) {
      parts.add('\n═══ GYM BUSINESS DATA ═══');
      gymStats.forEach((key, value) {
        parts.add('$key: $value');
      });
    }

    return parts.join('\n');
  }

  /// Determine which Claude model to use based on the plan and request type.
  static String getModel({
    required PlanTier tier,
    required AiRequestType requestType,
  }) {
    switch (tier) {
      case PlanTier.elite:
        // Elite gets Opus for complex tasks, Haiku for quick ones
        switch (requestType) {
          case AiRequestType.fullPlanGeneration:
          case AiRequestType.progressAnalysis:
          case AiRequestType.businessIntelligence:
            return 'claude-opus-4-5';
          case AiRequestType.quickQuestion:
          case AiRequestType.substitution:
          case AiRequestType.supplementAdvice:
            return 'claude-haiku-4-5-20251001';
        }
      case PlanTier.pro:
        return 'claude-haiku-4-5-20251001'; // Pro = Haiku only
      case PlanTier.basic:
        return ''; // Basic = no AI access
    }
  }

  /// Estimate token cost for a request type (for budget tracking).
  static int estimateTokens(AiRequestType requestType) {
    switch (requestType) {
      case AiRequestType.fullPlanGeneration:
        return 4000; // ~2K input + ~2K output
      case AiRequestType.progressAnalysis:
        return 3000;
      case AiRequestType.businessIntelligence:
        return 5000;
      case AiRequestType.quickQuestion:
        return 1000;
      case AiRequestType.substitution:
        return 800;
      case AiRequestType.supplementAdvice:
        return 1500;
    }
  }
}

/// Types of AI requests — determines model selection and token estimation.
enum AiRequestType {
  fullPlanGeneration,
  progressAnalysis,
  businessIntelligence,
  quickQuestion,
  substitution,
  supplementAdvice,
}
