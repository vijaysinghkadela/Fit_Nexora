import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/pagination.dart';
import '../models/food_log_model.dart';
import '../services/food_service.dart';
import 'auth_provider.dart';

final foodServiceProvider = Provider<FoodService>((ref) => FoodService());

const _foodLogsPageSize = 8;

// ─── Date helpers ────────────────────────────────────────────────────────────

DateTime _startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);
DateTime _endOfDay(DateTime d) =>
    DateTime(d.year, d.month, d.day, 23, 59, 59, 999);

// ─── Today's logs ────────────────────────────────────────────────────────────

final todayFoodLogsProvider =
    FutureProvider.family<List<FoodLog>, String>((ref, userId) async {
  final db = ref.watch(databaseServiceProvider);
  final now = DateTime.now();
  return db.getFoodLogs(
    userId: userId,
    startDate: _startOfDay(now),
    endDate: _endOfDay(now),
  );
});

// ─── Last 7 days logs ────────────────────────────────────────────────────────

final weeklyFoodLogsProvider =
    FutureProvider.family<List<FoodLog>, String>((ref, userId) async {
  final db = ref.watch(databaseServiceProvider);
  final now = DateTime.now();
  return db.getFoodLogs(
    userId: userId,
    startDate: _startOfDay(now.subtract(const Duration(days: 6))),
    endDate: _endOfDay(now),
  );
});

// ─── Last 30 days logs ───────────────────────────────────────────────────────

final monthlyFoodLogsProvider =
    FutureProvider.family<List<FoodLog>, String>((ref, userId) async {
  final db = ref.watch(databaseServiceProvider);
  final now = DateTime.now();
  return db.getFoodLogs(
    userId: userId,
    startDate: _startOfDay(now.subtract(const Duration(days: 29))),
    endDate: _endOfDay(now),
  );
});

final pagedTodayFoodLogsProvider = StateNotifierProvider.autoDispose
    .family<CallbackPagedController<FoodLog>, PagedListState<FoodLog>, String>(
        (ref, userId) {
  final controller = CallbackPagedController<FoodLog>((offset) {
    final now = DateTime.now();
    return ref.read(databaseServiceProvider).getFoodLogsPaged(
          userId: userId,
          startDate: _startOfDay(now),
          endDate: _endOfDay(now),
          limit: _foodLogsPageSize,
          offset: offset,
        );
  });

  Future.microtask(controller.loadInitial);
  return controller;
});

// ─── Per-day summaries for chart (weekly/monthly) ────────────────────────────

/// Returns a map of { 'yyyy-MM-dd' → NutritionSummary } for the given logs.
Map<String, NutritionSummary> groupLogsByDay(List<FoodLog> logs) {
  final Map<String, List<FoodLog>> byDay = {};
  for (final log in logs) {
    final key =
        '${log.loggedAt.year}-${log.loggedAt.month.toString().padLeft(2, '0')}-${log.loggedAt.day.toString().padLeft(2, '0')}';
    byDay.putIfAbsent(key, () => []).add(log);
  }
  return byDay.map((k, v) => MapEntry(k, NutritionSummary.fromLogs(v)));
}

// ─── Rule-based daily insight ─────────────────────────────────────────────────

String buildNutritionInsight(NutritionSummary s) {
  final msgs = <String>[];

  if (s.count == 0) return 'Start logging your meals to see insights here.';

  if (s.protein >= DailyTargets.protein * 0.8) {
    msgs.add('Good protein intake today.');
  } else {
    msgs.add('Protein is low — consider adding lean meat, eggs, or legumes.');
  }

  if (s.sugar > DailyTargets.sugar * 0.8) {
    msgs.add('Sugar is approaching the daily limit — watch sweetened foods.');
  }

  if (s.fiber < DailyTargets.fiber * 0.4) {
    msgs.add('Fiber is low — add vegetables, fruits, or whole grains.');
  }

  if (s.sodium > DailyTargets.sodiumMg * 0.9) {
    msgs.add('Sodium is high — reduce processed or salty foods.');
  }

  if (s.calories < DailyTargets.calories * 0.5 && s.count > 0) {
    msgs.add('Calorie intake is quite low — ensure you are eating enough.');
  }

  return msgs.isEmpty ? 'Your nutrition looks balanced today!' : msgs.join(' ');
}
