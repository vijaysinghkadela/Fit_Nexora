import '../models/membership_model.dart';

/// Membership plan tier levels (higher number = more features).
enum PlanTier {
  none(0),
  basic(1),
  pro(2),
  elite(3),
  master(4);

  const PlanTier(this.level);
  final int level;

  bool operator >=(PlanTier other) => level >= other.level;
  bool operator >(PlanTier other) => level > other.level;
  bool operator <=(PlanTier other) => level <= other.level;
  bool operator <(PlanTier other) => level < other.level;
}

/// Centralized access-control checks for subscription-gated features.
///
/// Usage:
/// ```dart
/// final control = AccessControl.fromMembership(membership);
/// if (!control.canAccessElite) {
///   throw PlanUpgradeRequiredException(requiredPlan: 'Elite');
/// }
/// ```
class AccessControl {
  final PlanTier tier;

  const AccessControl(this.tier);

  /// Build from a [Membership] model (may be null → no active plan).
  factory AccessControl.fromMembership(Membership? membership) {
    if (membership == null || !membership.isActive) {
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
    return PlanTier.none;
  }

  // ─── Tier gates ─────────────────────────────────────────────────────────

  bool get hasAnyPlan => tier >= PlanTier.basic;
  bool get canAccessPro => tier >= PlanTier.pro;
  bool get canAccessElite => tier >= PlanTier.elite;
  bool get canAccessMaster => tier >= PlanTier.master;

  // ─── Feature gates (Basic) ───────────────────────────────────────────────

  bool get canTrackAttendance => hasAnyPlan;
  bool get canViewWorkoutPlan => hasAnyPlan;
  bool get canViewDietPlan => hasAnyPlan;
  bool get canTrackProgress => hasAnyPlan;

  // ─── Feature gates (Pro) ────────────────────────────────────────────────

  bool get canUseAiWorkout => canAccessPro;
  bool get canUseAiDiet => canAccessPro;
  bool get canTrackCalories => canAccessPro;
  bool get canScanBarcode => canAccessPro;
  bool get canTrackMacros => canAccessPro;
  bool get canTrackBodyMeasurements => canAccessPro;

  // ─── Feature gates (Elite) ──────────────────────────────────────────────

  bool get canUseAdvancedAiTrainer => canAccessElite;
  bool get canTrackSupplements => canAccessElite;
  bool get canAnalyzeBodyFat => canAccessElite;
  bool get canTrackMuscleProgress => canAccessElite;
  bool get canCompareTransformationPhotos => canAccessElite;
  bool get canChatWithTrainer => canAccessElite;

  // ─── Feature gates (Master) ─────────────────────────────────────────────

  bool get canUseAiCoach => canAccessMaster;
  bool get canGetAdaptivePlans => canAccessMaster;
  bool get canUseAiNutritionCoach => canAccessMaster;
  bool get canScanFoodAi => canAccessMaster;
  bool get canGetRecoverySuggestions => canAccessMaster;
  bool get canViewAdvancedAnalytics => canAccessMaster;
  bool get canJoinLiveSessions => canAccessMaster;
  bool get canGetPrioritySupport => canAccessMaster;
  bool get canAccessExclusiveChallenges => canAccessMaster;

  // ─── Helper ─────────────────────────────────────────────────────────────

  /// The display name for the current plan.
  String get planDisplayName => switch (tier) {
    PlanTier.master => 'Master ₹2499',
    PlanTier.elite  => 'Elite ₹1499',
    PlanTier.pro    => 'Pro ₹899',
    PlanTier.basic  => 'Basic ₹499',
    PlanTier.none   => 'No Active Plan',
  };

  /// Minimum plan name needed for a tier (used in upgrade prompts).
  static String planNameForTier(PlanTier required) => switch (required) {
    PlanTier.master => 'Master',
    PlanTier.elite  => 'Elite',
    PlanTier.pro    => 'Pro',
    PlanTier.basic  => 'Basic',
    PlanTier.none   => '',
  };
}
