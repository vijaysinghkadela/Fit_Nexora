import '../models/membership_model.dart';

/// Membership plan tier levels (higher number = more features).
enum PlanTier {
  none(0),
  free(1), // NEW: Free tier - always accessible to all members
  basic(2),
  pro(3),
  elite(4),
  master(5);

  const PlanTier(this.level);
  final int level;

  bool operator >=(PlanTier other) => level >= other.level;
  bool operator >(PlanTier other) => level > other.level;
  bool operator <=(PlanTier other) => level <= other.level;
  bool operator <(PlanTier other) => level < other.level;
}

/// Centralized access-control checks for subscription-gated features.
/// 
/// CRITICAL: Free tier features are always accessible to all authenticated members.
/// Premium features require active paid membership.
/// 
/// FREE TIER FEATURES (Always Available):
/// - Attendance tracking
/// - Live gym traffic
/// - Workout calendar
/// - Motivation quotes
/// - Check-in/check-out
/// 
/// PREMIUM FEATURES (Require Paid Membership):
/// - AI Workout Plans (Pro+)
/// - AI Diet Plans (Pro+)
/// - Advanced Analytics (Elite+)
/// - Body Measurements tracking (Pro+)
/// - Water tracker (Pro+)
/// - Personal records (Pro+)
/// - Macro calculator (Pro+)
/// - 1RM calculator (Pro+)
class AccessControl {
  final PlanTier tier;

  const AccessControl(this.tier);

  /// Build from a [Membership] model (null = no active plan).
  /// FOR FREE TIER: if membership is null, still return tier = PlanTier.free
  /// This ensures free features are always accessible.
  factory AccessControl.fromMembership(Membership? membership) {
    if (membership == null) {
      // NEW: No membership = free tier (can access free features)
      return const AccessControl(PlanTier.free);
    }
    if (!membership.isActive || membership.isExpired) {
      return const AccessControl(PlanTier.none);
    }
    final tier = _tierFromPlanName(membership.planName);
    return AccessControl(tier);
  }

  /// Build from a raw plan name string.
  factory AccessControl.fromPlanName(String? planName) {
    return AccessControl(_tierFromPlanName(planName ?? ''));
  }

  static PlanTier _tierFromPlanName(String planName) {
    final lower = planName.toLowerCase();
    if (lower.contains('master')) return PlanTier.master;
    if (lower.contains('elite')) return PlanTier.elite;
    if (lower.contains('pro')) return PlanTier.pro;
    if (lower.contains('basic')) return PlanTier.basic;
    if (lower.contains('free')) return PlanTier.free; // NEW: Support free tier plan name
    return PlanTier.none;
  }

  // ─── Tier gates ─────────────────────────────────────────────────────────

  bool get hasAnyPlan => tier >= PlanTier.basic;
  bool get canAccessPro => tier >= PlanTier.pro;
  bool get canAccessElite => tier >= PlanTier.elite;
  bool get canAccessMaster => tier >= PlanTier.master;

  // ─── FREE TIER FEATURES (Always Available) ────────────────────────────────
  // CRITICAL: These features are available to ALL members, regardless of membership status
  
  bool get canTrackAttendance => true; // Changed: ALWAYS available (Free tier)
  bool get canViewGymTraffic => true; // NEW: ALWAYS available (Free tier)
  bool get canViewCalendar => true; // NEW: ALWAYS available (Free tier)
  bool get canViewMotivationQuotes => true; // NEW: ALWAYS available (Free tier)
  bool get canCheckInOut => true; // NEW: ALWAYS available (Free tier)
  bool get canViewWorkoutPlan => tier >= PlanTier.free; // Basic workout viewing is free
  bool get canViewDietPlan => tier >= PlanTier.free; // Basic diet viewing is free
  
  // ─── PREMIUM FEATURES (Require Paid Plans) ──────────────────────────────

  // PRO TIER FEATURES
  bool get canUseAiWorkout => canAccessPro;
  bool get canUseAiDiet => canAccessPro;
  bool get canTrackCalories => canAccessPro;
  bool get canScanBarcode => canAccessPro;
  bool get canTrackMacros => canAccessPro;
  bool get canTrackBodyMeasurements => canAccessPro;
  bool get canAddCustomFood => canAccessPro;
  bool get canTrackWater => canAccessPro;
  bool get canTrackPersonalRecords => canAccessPro;

  // ELITE TIER FEATURES
  bool get canUseAdvancedAiTrainer => canAccessElite;
  bool get canTrackSupplements => canAccessElite;
  bool get canAnalyzeBodyFat => canAccessElite;
  bool get canTrackMuscleProgress => canAccessElite;
  bool get canCompareTransformationPhotos => canAccessElite;
  bool get canChatWithTrainer => canAccessElite;
  bool get canViewAdvancedAnalytics => canAccessElite;
  bool get canSyncWearables => canAccessElite;

  // MASTER TIER FEATURES
  bool get canUseAiCoach => canAccessMaster;
  bool get canGetAdaptivePlans => canAccessMaster;
  bool get canUseAiNutritionCoach => canAccessMaster;
  bool get canScanFoodAi => canAccessMaster;
  bool get canGetRecoverySuggestions => canAccessMaster;
  bool get canJoinLiveSessions => canAccessMaster;
  bool get canGetPrioritySupport => canAccessMaster;
  bool get canAccessExclusiveChallenges => canAccessMaster;

  // ─── Helper ─────────────────────────────────────────────────────────────

  /// The display name for the current plan.
  String get planDisplayName => switch (tier) {
    PlanTier.master => 'Master ₹2499',
    PlanTier.elite => 'Elite ₹1499',
    PlanTier.pro => 'Pro ₹899',
    PlanTier.basic => 'Basic ₹499',
    PlanTier.free => 'Free Tier',
    PlanTier.none => 'No Active Plan',
  };

  /// Minimum plan name needed for a tier (used in upgrade prompts).
  static String planNameForTier(PlanTier required) => switch (required) {
    PlanTier.master => 'Master',
    PlanTier.elite => 'Elite',
    PlanTier.pro => 'Pro',
    PlanTier.basic => 'Basic',
    PlanTier.free => 'Free', // NEW: Free tier
    PlanTier.none => '',
  };
  
  /// Check if a specific feature requires premium plan.
  /// 
  /// Usage: 
  /// bool isPremiumFeature(String featureId) {
  ///   return AccessControl.isPremiumFeature(featureId);
  /// }
  static bool isPremiumFeature(String featureId) {
    const freeFeatures = {
      'attendance',
      'gym_traffic',
      'calendar',
      'motivation_quotes',
      'checkin_checkout',
      'view_workout_plan',
      'view_diet_plan',
    };
    return !freeFeatures.contains(featureId);
  }
}
