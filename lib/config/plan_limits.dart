import '../core/enums.dart';

/// Plan pricing, limits, and AI budget configuration.
///
/// These are the single source of truth for all plan enforcement
/// across the app. Backend must mirror these limits via RLS + check constraints.
class PlanLimits {
  PlanLimits._();

  // ─── MONTHLY PRICING ──────────────────────────────────────────────
  static const Map<PlanTier, double> monthlyPrice = {
    PlanTier.basic: 9.99,
    PlanTier.pro: 19.99,
    PlanTier.elite: 29.99,
  };

  static const Map<PlanTier, double> annualPrice = {
    PlanTier.basic: 99.99, // 2 months free
    PlanTier.pro: 199.99, // 2 months free
    PlanTier.elite: 299.99, // 2 months free
  };

  // ─── CLIENT CAPS (hard limits, backend-enforced) ───────────────────
  static const Map<PlanTier, int> maxClients = {
    PlanTier.basic: 50,
    PlanTier.pro: 200,
    PlanTier.elite: 500, // NOT unlimited — custom pricing above this
  };

  // ─── TRAINER SEATS ─────────────────────────────────────────────────
  static const Map<PlanTier, int> maxTrainers = {
    PlanTier.basic: 1,
    PlanTier.pro: 5,
    PlanTier.elite: -1, // unlimited
  };

  // ─── AI TOKEN BUDGET (monthly) ─────────────────────────────────────
  // Basic: zero AI access
  // Pro: Haiku only — ~100 plan generations/month
  // Elite: Opus (50 calls) + Haiku (unlimited fallback)
  static const Map<PlanTier, int> monthlyAiTokenLimit = {
    PlanTier.basic: 0,
    PlanTier.pro: 500000, // ~100 Haiku plan generations
    PlanTier.elite: 2000000, // ~50 Opus + overflow Haiku
  };

  static const Map<PlanTier, int> monthlyOpusCallLimit = {
    PlanTier.basic: 0,
    PlanTier.pro: 0, // Pro = Haiku only
    PlanTier.elite: 50, // Hard cap, then auto-downgrade to Haiku
  };

  static const Map<PlanTier, int> monthlyHaikuCallLimit = {
    PlanTier.basic: 0,
    PlanTier.pro: 100,
    PlanTier.elite: -1, // unlimited (within token budget)
  };

  // ─── AI OVERAGE PRICING ────────────────────────────────────────────
  /// Cost per extra Opus generation beyond the monthly limit.
  static const double opusOveragePerCall = 0.10;

  /// Whether the plan supports overage billing (vs hard cutoff).
  static const Map<PlanTier, bool> supportsOverage = {
    PlanTier.basic: false,
    PlanTier.pro: false, // Hard cap — upgrade to Elite
    PlanTier.elite: true, // Metered billing via Stripe
  };

  // ─── FEATURE FLAGS (22-item competitive gap matrix) ─────────────────
  static const Map<PlanTier, Set<String>> features = {
    PlanTier.basic: {
      // Core CRUD
      'client_management',
      'membership_tracking',
      'basic_dashboard',
      'expiry_alerts',
      'manual_workout_plans',
      // Indian market essentials (available to all)
      'gst_invoice_generator',
      'upi_razorpay',
      'hindi_language',
      'offline_mode',
    },
    PlanTier.pro: {
      // Everything in Basic
      'client_management',
      'membership_tracking',
      'basic_dashboard',
      'expiry_alerts',
      'manual_workout_plans',
      'gst_invoice_generator',
      'upi_razorpay',
      'hindi_language',
      'offline_mode',
      // AI (Haiku only)
      'ai_haiku_suggestions',
      'indian_food_database',
      'supplement_advisor',
      'recovery_rest_day_ai',
      'calorie_auto_calculator',
      // Diet
      'diet_plans',
      // Trainer tools
      'trainer_commission_tracker',
      'client_trainer_auto_assign',
      'trainer_workload_monitor',
      // Gamification
      'streak_system',
      'gym_leaderboard',
      'milestone_rewards',
      'before_after_photos',
      // Tracking & alerts
      'progress_tracking',
      'attendance_tracking',
      'payment_tracking',
      'at_risk_client_alerts',
      // Communication
      'notifications',
      'whatsapp_notifications',
      'broadcast_messaging',
      'client_plan_requests',
    },
    PlanTier.elite: {
      // Everything in Pro
      'client_management',
      'membership_tracking',
      'basic_dashboard',
      'expiry_alerts',
      'manual_workout_plans',
      'gst_invoice_generator',
      'upi_razorpay',
      'hindi_language',
      'offline_mode',
      'ai_haiku_suggestions',
      'indian_food_database',
      'supplement_advisor',
      'recovery_rest_day_ai',
      'calorie_auto_calculator',
      'diet_plans',
      'trainer_commission_tracker',
      'client_trainer_auto_assign',
      'trainer_workload_monitor',
      'streak_system',
      'gym_leaderboard',
      'milestone_rewards',
      'before_after_photos',
      'progress_tracking',
      'attendance_tracking',
      'payment_tracking',
      'at_risk_client_alerts',
      'notifications',
      'whatsapp_notifications',
      'broadcast_messaging',
      'client_plan_requests',
      // Elite exclusives
      'ai_opus_coaching',
      'ai_chat',
      'agent_performance_scoring',
      'video_message_chat',
      'mrr_churn_dashboard',
      'revenue_forecast',
      'peak_hours_heatmap',
      'advanced_analytics',
      'multi_gym',
      'white_label',
      'custom_templates',
      'api_access',
      'priority_support',
    },
  };

  // ─── TRIAL ─────────────────────────────────────────────────────────
  /// Free trial duration (card required upfront).
  static const int trialDays = 14;

  /// Plans that support free trials.
  static const Set<PlanTier> trialEligible = {PlanTier.pro, PlanTier.elite};

  // ─── HELPERS ───────────────────────────────────────────────────────

  /// Check if a plan has access to a specific feature.
  static bool hasFeature(PlanTier tier, String feature) {
    return features[tier]?.contains(feature) ?? false;
  }

  /// Check if adding a client would exceed the cap.
  static bool isClientCapReached(PlanTier tier, int currentCount) {
    final cap = maxClients[tier] ?? 50;
    return currentCount >= cap;
  }

  /// Check if an AI call is allowed (before actually calling).
  static AiCallDecision canMakeAiCall({
    required PlanTier tier,
    required int usedOpusCalls,
    required int usedHaikuCalls,
    required int usedTokens,
    required bool requestsOpus,
  }) {
    // Basic: no AI
    if (tier == PlanTier.basic) {
      return AiCallDecision.denied('AI features require a Pro or Elite plan.');
    }

    // Pro: Haiku only
    if (tier == PlanTier.pro) {
      if (requestsOpus) {
        return AiCallDecision.denied(
            'Claude Opus requires an Elite plan. Upgrade to unlock advanced AI.');
      }
      final haikuLimit = monthlyHaikuCallLimit[PlanTier.pro]!;
      if (usedHaikuCalls >= haikuLimit) {
        return AiCallDecision.denied(
            'Monthly AI limit reached ($haikuLimit generations). Resets next month.');
      }
      if (usedTokens >= monthlyAiTokenLimit[PlanTier.pro]!) {
        return AiCallDecision.denied(
            'Monthly AI token budget exhausted. Upgrade to Elite for more.');
      }
      return AiCallDecision.allowed(model: 'haiku');
    }

    // Elite: Opus with cap, then fallback to Haiku
    if (requestsOpus) {
      final opusLimit = monthlyOpusCallLimit[PlanTier.elite]!;
      if (usedOpusCalls >= opusLimit) {
        // Check if overage is enabled
        if (supportsOverage[PlanTier.elite] == true) {
          return AiCallDecision.allowedWithOverage(
            model: 'opus',
            overageCost: opusOveragePerCall,
          );
        }
        // Auto-downgrade to Haiku
        return AiCallDecision.downgraded(
          originalModel: 'opus',
          actualModel: 'haiku',
          reason: 'Monthly Opus limit reached ($opusLimit calls). '
              'Using Haiku instead. Resets next month.',
        );
      }
      return AiCallDecision.allowed(model: 'opus');
    }

    // Elite: Haiku is unlimited within token budget
    if (usedTokens >= monthlyAiTokenLimit[PlanTier.elite]!) {
      return AiCallDecision.denied(
          'Monthly AI token budget exhausted. Contact support for enterprise pricing.');
    }
    return AiCallDecision.allowed(model: 'haiku');
  }

  /// Format price display.
  static String formatMonthly(PlanTier tier) =>
      '\$${monthlyPrice[tier]!.toStringAsFixed(2)}/mo';

  static String formatAnnual(PlanTier tier) =>
      '\$${annualPrice[tier]!.toStringAsFixed(2)}/yr';

  static String formatAnnualMonthly(PlanTier tier) {
    final monthly = annualPrice[tier]! / 12;
    return '\$${monthly.toStringAsFixed(2)}/mo';
  }
}

/// Result of checking whether an AI call is permitted.
class AiCallDecision {
  final bool isAllowed;
  final bool isDowngraded;
  final bool hasOverage;
  final String? model;
  final String? reason;
  final double? overageCost;

  const AiCallDecision._({
    required this.isAllowed,
    this.isDowngraded = false,
    this.hasOverage = false,
    this.model,
    this.reason,
    this.overageCost,
  });

  factory AiCallDecision.allowed({required String model}) {
    return AiCallDecision._(isAllowed: true, model: model);
  }

  factory AiCallDecision.denied(String reason) {
    return AiCallDecision._(isAllowed: false, reason: reason);
  }

  factory AiCallDecision.downgraded({
    required String originalModel,
    required String actualModel,
    required String reason,
  }) {
    return AiCallDecision._(
      isAllowed: true,
      isDowngraded: true,
      model: actualModel,
      reason: reason,
    );
  }

  factory AiCallDecision.allowedWithOverage({
    required String model,
    required double overageCost,
  }) {
    return AiCallDecision._(
      isAllowed: true,
      hasOverage: true,
      model: model,
      overageCost: overageCost,
    );
  }
}
