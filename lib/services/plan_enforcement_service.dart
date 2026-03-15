import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/plan_limits.dart';
import '../core/constants.dart';
import '../core/database_values.dart';
import '../core/enums.dart';
import '../models/ai_usage_model.dart';

/// Enforces plan limits at the application layer.
///
/// Every mutating operation (add client, generate AI plan) must pass
/// through this service before hitting the database or external API.
class PlanEnforcementService {
  final SupabaseClient _client;

  PlanEnforcementService(this._client);

  // ─── CLIENT CAP ENFORCEMENT ────────────────────────────────────────

  /// Check if a gym can add one more client.
  /// Returns null if allowed, or an error message if blocked.
  Future<String?> checkClientCap(String gymId, PlanTier tier) async {
    final count = await _client
        .from(AppConstants.clientsTable)
        .select()
        .eq('gym_id', gymId)
        .count(CountOption.exact);

    if (PlanLimits.isClientCapReached(tier, count.count)) {
      final cap = PlanLimits.maxClients[tier]!;
      return 'Client limit reached ($cap). '
          '${tier == PlanTier.elite ? 'Contact us for enterprise pricing.' : 'Upgrade your plan to add more clients.'}';
    }
    return null;
  }

  /// Check if a gym can add one more trainer.
  Future<String?> checkTrainerCap(String gymId, PlanTier tier) async {
    final count = await _client
        .from(AppConstants.gymMembersTable)
        .select()
        .eq('gym_id', gymId)
        .eq('role', DatabaseValues.gymMemberTrainerRole)
        .count(CountOption.exact);

    final cap = PlanLimits.maxTrainers[tier]!;
    if (cap != -1 && count.count >= cap) {
      return 'Trainer seat limit reached ($cap). '
          'Upgrade your plan for more trainer seats.';
    }
    return null;
  }

  // ─── FEATURE GATE ──────────────────────────────────────────────────

  /// Check if a feature is available on the current plan.
  /// Returns null if allowed, error message if blocked.
  String? checkFeature(PlanTier tier, String feature) {
    if (!PlanLimits.hasFeature(tier, feature)) {
      final requiredPlan = _getMinimumPlan(feature);
      return 'This feature requires a ${requiredPlan?.label ?? 'higher'} plan. '
          'Upgrade to unlock it.';
    }
    return null;
  }

  PlanTier? _getMinimumPlan(String feature) {
    for (final tier in PlanTier.values) {
      if (PlanLimits.hasFeature(tier, feature)) return tier;
    }
    return null;
  }

  // ─── AI CALL ENFORCEMENT ───────────────────────────────────────────

  /// Get the current period's AI usage for a gym.
  Future<AiUsage?> getCurrentAiUsage(String gymId) async {
    final now = DateTime.now();
    final periodStart = DateTime(now.year, now.month, 1);

    final data = await _client
        .from(AppConstants.aiUsageTable)
        .select()
        .eq('gym_id', gymId)
        .gte('period_start', periodStart.toIso8601String())
        .order('period_start', ascending: false)
        .limit(1)
        .maybeSingle();

    return data != null ? AiUsage.fromJson(data) : null;
  }

  /// Check if an AI call is allowed and what model to use.
  Future<AiCallDecision> checkAiAccess({
    required String gymId,
    required PlanTier tier,
    required bool requestsOpus,
  }) async {
    final usage = await getCurrentAiUsage(gymId);

    return PlanLimits.canMakeAiCall(
      tier: tier,
      usedOpusCalls: usage?.opusCallsUsed ?? 0,
      usedHaikuCalls: usage?.haikuCallsUsed ?? 0,
      usedTokens: usage?.totalTokensUsed ?? 0,
      requestsOpus: requestsOpus,
    );
  }

  /// Record an AI call (increment counters after successful generation).
  Future<void> recordAiCall({
    required String gymId,
    required String model,
    required int tokensUsed,
    double overageCharge = 0.0,
  }) async {
    final now = DateTime.now();
    final periodStart = DateTime(now.year, now.month, 1);
    final periodEnd = DateTime(now.year, now.month + 1, 1);

    final existing = await getCurrentAiUsage(gymId);

    if (existing != null && existing.isCurrentPeriod) {
      // Update existing record
      final updates = <String, dynamic>{
        'total_tokens_used': existing.totalTokensUsed + tokensUsed,
        'overage_charges': existing.overageCharges + overageCharge,
        'updated_at': now.toIso8601String(),
      };

      if (model == 'opus') {
        updates['opus_calls_used'] = existing.opusCallsUsed + 1;
      } else {
        updates['haiku_calls_used'] = existing.haikuCallsUsed + 1;
      }

      await _client.from(AppConstants.aiUsageTable).update(updates).eq('id', existing.id);
    } else {
      // Create new period record
      await _client.from(AppConstants.aiUsageTable).insert({
        'gym_id': gymId,
        'period_start': periodStart.toIso8601String(),
        'period_end': periodEnd.toIso8601String(),
        'opus_calls_used': model == 'opus' ? 1 : 0,
        'haiku_calls_used': model == 'haiku' ? 1 : 0,
        'total_tokens_used': tokensUsed,
        'overage_charges': overageCharge,
        'updated_at': now.toIso8601String(),
      });
    }
  }

  // ─── USAGE SUMMARY (for dashboard display) ─────────────────────────

  /// Get a summary of current AI usage for display in the dashboard.
  Future<Map<String, dynamic>> getUsageSummary(
      String gymId, PlanTier tier) async {
    final usage = await getCurrentAiUsage(gymId);

    final opusLimit = PlanLimits.monthlyOpusCallLimit[tier] ?? 0;
    final haikuLimit = PlanLimits.monthlyHaikuCallLimit[tier] ?? 0;
    final tokenLimit = PlanLimits.monthlyAiTokenLimit[tier] ?? 0;

    return {
      'opus_used': usage?.opusCallsUsed ?? 0,
      'opus_limit': opusLimit,
      'opus_percent': opusLimit > 0
          ? ((usage?.opusCallsUsed ?? 0) / opusLimit * 100).clamp(0, 100)
          : 0,
      'haiku_used': usage?.haikuCallsUsed ?? 0,
      'haiku_limit': haikuLimit, // -1 = unlimited
      'tokens_used': usage?.totalTokensUsed ?? 0,
      'token_limit': tokenLimit,
      'token_percent': tokenLimit > 0
          ? ((usage?.totalTokensUsed ?? 0) / tokenLimit * 100).clamp(0, 100)
          : 0,
      'overage_charges': usage?.overageCharges ?? 0.0,
      'has_ai_access': tier != PlanTier.basic,
      'has_opus_access': tier == PlanTier.elite,
    };
  }
}
