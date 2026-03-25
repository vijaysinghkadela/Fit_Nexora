import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/ai_generated_plan_model.dart';
import '../core/dev_bypass.dart';
import '../models/food_log_model.dart';
import '../models/progress_checkin_model.dart';
import 'auth_provider.dart';
import 'ai_agent_provider.dart';
import 'member_provider.dart';

// ─── Pro Access Gate ──────────────────────────────────────────────────────────

/// Pro plan tier names stored in the memberships.plan_name column.
/// Any membership with planTier = 'pro' or 'elite' unlocks Pro features.
const _proTiers = {
  'pro',
  'pro_monthly',
  'pro_yearly',
  'elite',
  'Pro Plan',
  'Pro Monthly',
  'Pro Yearly',
  'Elite',
  'master',
  'Master'
};

/// True when the member has an active Pro (or higher) membership.
final memberHasProAccessProvider =
    FutureProvider.autoDispose<bool>((ref) async {
  final user = ref.watch(currentUserProvider).value;
  if (user != null && isDevUser(user.email)) return true;

  final membership = await ref.watch(memberMembershipProvider.future);
  if (membership == null || membership.isExpired) return false;
  return _proTiers
      .any((t) => membership.planName.toLowerCase().contains(t.toLowerCase()));
});

// ─── Calories & Macros (Today) ────────────────────────────────────────────────

/// Today's food logs for the current member.
final proTodayFoodLogsProvider =
    FutureProvider.autoDispose<List<FoodLog>>((ref) async {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return [];
  final db = ref.watch(databaseServiceProvider);
  final now = DateTime.now();
  final start = DateTime(now.year, now.month, now.day);
  final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
  return db.getFoodLogs(userId: user.id, startDate: start, endDate: end);
});

/// NutritionSummary for today.
final proTodayNutritionProvider =
    FutureProvider.autoDispose<NutritionSummary>((ref) async {
  final logs = await ref.watch(proTodayFoodLogsProvider.future);
  return NutritionSummary.fromLogs(logs);
});

// ─── Weekly Calorie History (for chart) ───────────────────────────────────────

/// Calorie totals for the last 7 days: list of (date, kcal) entries.
final proWeeklyCaloriesProvider =
    FutureProvider.autoDispose<List<_DayCalories>>((ref) async {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return [];
  final db = ref.watch(databaseServiceProvider);
  final now = DateTime.now();
  final logs = await db.getFoodLogs(
    userId: user.id,
    startDate: DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: 6)),
    endDate: DateTime(now.year, now.month, now.day, 23, 59, 59),
  );

  // Group by day
  final Map<String, double> byDay = {};
  for (final log in logs) {
    final key =
        '${log.loggedAt.year}-${log.loggedAt.month.toString().padLeft(2, '0')}-${log.loggedAt.day.toString().padLeft(2, '0')}';
    byDay[key] = (byDay[key] ?? 0) + log.caloriesKcal;
  }

  // Build last 7 days (fill zeros for missing days)
  final result = <_DayCalories>[];
  for (var i = 6; i >= 0; i--) {
    final d =
        DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
    final key =
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    result.add(_DayCalories(date: d, kcal: byDay[key] ?? 0));
  }
  return result;
});

// ─── Body Measurements ────────────────────────────────────────────────────────

/// Latest body measurements from progress_checkins.
final proBodyMeasurementsProvider =
    FutureProvider.autoDispose<ProgressCheckIn?>((ref) async {
  final clientId = await ref.watch(memberClientIdProvider.future);
  if (clientId == null) return null;
  final db = ref.watch(databaseServiceProvider);
  final entries = await db.getProgressCheckIns(clientId);
  if (entries.isEmpty) return null;
  return ProgressCheckIn.fromJson(entries.first);
});

/// All progress check-ins for the body measurements history.
final proAllMeasurementsProvider =
    FutureProvider.autoDispose<List<ProgressCheckIn>>((ref) async {
  final clientId = await ref.watch(memberClientIdProvider.future);
  if (clientId == null) return [];
  final db = ref.watch(databaseServiceProvider);
  final entries = await db.getProgressCheckIns(clientId);
  return entries.map(ProgressCheckIn.fromJson).toList();
});

/// Helper data class for calorie chart.
class _DayCalories {
  final DateTime date;
  final double kcal;
  const _DayCalories({required this.date, required this.kcal});
}

// Re-export for screens that only need the type
typedef DayCalories = _DayCalories;

/// Latest AI-generated plan for the current Pro member.
final proLatestAiPlanProvider =
    FutureProvider.autoDispose<AiGeneratedPlan?>((ref) async {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return null;

  final membership = await ref.watch(memberMembershipProvider.future);
  final gymId = membership?.gymId;
  if (gymId == null) return null;

  final plans = await ref.read(
    aiGeneratedPlansProvider((memberId: user.id, gymId: gymId)).future,
  );
  if (plans.isEmpty) return null;
  return plans.first;
});
