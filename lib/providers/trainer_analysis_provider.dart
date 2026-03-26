// lib/providers/trainer_analysis_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/client_profile_model.dart';
import '../models/diet_plan_model.dart';
import '../models/trainer_analysis_model.dart';
import '../models/workout_plan_model.dart';
import '../providers/ai_agent_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/client_provider.dart';
import '../providers/gym_provider.dart';

/// Fetches analysis data for a specific client (last 30 days)
final trainerAnalysisDataProvider = FutureProvider.autoDispose
    .family<TrainerAnalysisData, String>((ref, clientId) async {
  final client = Supabase.instance.client;
  final now = DateTime.now();
  final thirtyDaysAgo = now.subtract(const Duration(days: 30));
  final startDate = thirtyDaysAgo.toIso8601String();

  // Fetch gym checkins
  final checkinsResult = await client
      .from('gym_checkins')
      .select('id, checked_in_at, checked_out_at')
      .eq('client_id', clientId)
      .gte('checked_in_at', startDate)
      .order('checked_in_at', ascending: false);

  final checkins = checkinsResult as List;
  final totalCheckins = checkins.length;

  // Calculate average session duration
  double totalMins = 0;
  int sessionsWithDuration = 0;
  for (final c in checkins) {
    final inTime = DateTime.tryParse(c['checked_in_at']?.toString() ?? '');
    final outTime = DateTime.tryParse(c['checked_out_at']?.toString() ?? '');
    if (inTime != null && outTime != null) {
      totalMins += outTime.difference(inTime).inMinutes;
      sessionsWithDuration++;
    }
  }
  final avgSessionMins =
      sessionsWithDuration > 0 ? totalMins / sessionsWithDuration : 60.0;

  // Fetch body measurements
  final measurementsResult = await client
      .from('body_measurements')
      .select()
      .eq('client_id', clientId)
      .gte('recorded_at', startDate)
      .order('recorded_at', ascending: false);

  final measurements = (measurementsResult as List)
      .map((m) => m as Map<String, dynamic>)
      .toList();

  // Calculate weight change
  double? weightChangeKg;
  String? weightTrend;
  if (measurements.length >= 2) {
    final latestWeight = measurements.first['weight_kg'] as num?;
    final earliestWeight = measurements.last['weight_kg'] as num?;
    if (latestWeight != null && earliestWeight != null) {
      weightChangeKg = latestWeight.toDouble() - earliestWeight.toDouble();
      weightTrend = weightChangeKg > 0.5
          ? 'gaining'
          : weightChangeKg < -0.5
              ? 'losing'
              : 'stable';
    }
  }

  // Fetch personal records
  final prsResult = await client
      .from('personal_records')
      .select()
      .eq('client_id', clientId)
      .gte('achieved_at', startDate)
      .order('achieved_at', ascending: false);

  final prs =
      (prsResult as List).map((p) => p as Map<String, dynamic>).toList();

  // Fetch water logs
  final waterResult = await client
      .from('water_logs')
      .select()
      .eq('client_id', clientId)
      .gte('logged_at', startDate);

  final waterLogs =
      (waterResult as List).map((w) => w as Map<String, dynamic>).toList();

  final totalWaterMl = waterLogs.fold<int>(
    0,
    (sum, log) => sum + ((log['amount_ml'] as num?)?.toInt() ?? 0),
  );

  // Fetch client profile for expected checkins
  final clientProfile = await client
      .from('clients')
      .select('days_per_week')
      .eq('id', clientId)
      .maybeSingle();

  final daysPerWeek = (clientProfile?['days_per_week'] as num?)?.toInt() ?? 4;
  final expectedCheckins = (daysPerWeek * 4.3).round(); // ~4.3 weeks per month

  // Fetch sleep and steps from health tables (if available)
  double avgSleepHours = 7.0;
  int avgSteps = 5000;

  try {
    final sleepResult = await client
        .from('sleep_logs')
        .select('hours_slept')
        .eq('user_id', clientId)
        .gte('recorded_at', startDate);

    final sleepLogs = sleepResult as List;
    if (sleepLogs.isNotEmpty) {
      final totalSleep = sleepLogs.fold<double>(
        0,
        (sum, log) => sum + ((log['hours_slept'] as num?)?.toDouble() ?? 0),
      );
      avgSleepHours = totalSleep / sleepLogs.length;
    }
  } catch (_) {
    // Sleep table may not exist or have different schema
  }

  try {
    final stepsResult = await client
        .from('steps_logs')
        .select('steps')
        .eq('user_id', clientId)
        .gte('recorded_at', startDate);

    final stepsLogs = stepsResult as List;
    if (stepsLogs.isNotEmpty) {
      final totalSteps = stepsLogs.fold<int>(
        0,
        (sum, log) => sum + ((log['steps'] as num?)?.toInt() ?? 0),
      );
      avgSteps = totalSteps ~/ stepsLogs.length;
    }
  } catch (_) {
    // Steps table may not exist or have different schema
  }

  return TrainerAnalysisData(
    totalCheckins: totalCheckins,
    expectedCheckins: expectedCheckins,
    avgSessionMins: avgSessionMins,
    bodyMeasurements: measurements,
    personalRecords: prs,
    waterLogs: waterLogs,
    totalWaterMl: totalWaterMl,
    waterGoalMl: 2500 * 30, // 2.5L per day * 30 days
    avgSleepHours: avgSleepHours,
    avgSteps: avgSteps,
    weightChangeKg: weightChangeKg,
    weightTrend: weightTrend,
  );
});

/// Fetches analysis reports for a specific client
final clientAnalysisReportsProvider = FutureProvider.autoDispose
    .family<List<TrainerAnalysisReport>, String>((ref, clientId) async {
  final aiService = ref.watch(aiAgentServiceProvider);
  return aiService.getClientAnalysisReports(clientId);
});

/// Fetches all analysis reports created by the current trainer
final trainerAllReportsProvider =
    FutureProvider.autoDispose<List<TrainerAnalysisReport>>((ref) async {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return [];

  final aiService = ref.watch(aiAgentServiceProvider);
  return aiService.getTrainerAnalysisReports(user.id);
});

/// Fetches the client's assigned workout plan
final clientWorkoutPlanProvider = FutureProvider.autoDispose
    .family<WorkoutPlan?, String>((ref, clientId) async {
  final db = ref.watch(databaseServiceProvider);
  final plan = await db.getWorkoutPlanForClient(clientId);
  if (plan == null) return null;
  return WorkoutPlan.fromJson(plan);
});

/// Fetches the client's assigned diet plan
final clientDietPlanProvider =
    FutureProvider.autoDispose.family<DietPlan?, String>((ref, clientId) async {
  final db = ref.watch(databaseServiceProvider);
  final plan = await db.getDietPlanForClient(clientId);
  if (plan == null) return null;
  return DietPlan.fromJson(plan);
});

/// State notifier for generating and saving analysis reports
class TrainerAnalysisNotifier
    extends StateNotifier<AsyncValue<TrainerAnalysisReport?>> {
  final Ref _ref;

  TrainerAnalysisNotifier(this._ref) : super(const AsyncValue.data(null));

  Future<TrainerAnalysisReport?> generateAnalysis({
    required ClientProfile client,
    required String gymId,
  }) async {
    state = const AsyncValue.loading();

    try {
      final user = _ref.read(currentUserProvider).value;
      if (user == null) throw Exception('User not authenticated');

      // Fetch all required data
      final workoutPlan =
          await _ref.read(clientWorkoutPlanProvider(client.id).future);
      final dietPlan =
          await _ref.read(clientDietPlanProvider(client.id).future);
      final analysisData =
          await _ref.read(trainerAnalysisDataProvider(client.id).future);

      // Generate AI analysis
      final aiService = _ref.read(aiAgentServiceProvider);
      final result = await aiService.generateTrainerAnalysis(
        client: client,
        workoutPlan: workoutPlan,
        dietPlan: dietPlan,
        data: analysisData,
        trainerName: user.fullName,
      );

      // Save to database
      final report = await aiService.saveTrainerAnalysisReport(
        trainerId: user.id,
        clientId: client.id,
        gymId: gymId,
        workoutPlanId: workoutPlan?.id,
        dietPlanId: dietPlan?.id,
        analysisResult: result,
      );

      state = AsyncValue.data(report);

      // Invalidate the reports list to refresh
      _ref.invalidate(clientAnalysisReportsProvider(client.id));
      _ref.invalidate(trainerAllReportsProvider);

      return report;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  void reset() {
    state = const AsyncValue.data(null);
  }
}

final trainerAnalysisNotifierProvider = StateNotifierProvider.autoDispose<
    TrainerAnalysisNotifier, AsyncValue<TrainerAnalysisReport?>>((ref) {
  return TrainerAnalysisNotifier(ref);
});

/// Get a specific client by ID
final trainerClientByIdProvider = FutureProvider.autoDispose
    .family<ClientProfile?, String>((ref, clientId) async {
  final gym = ref.watch(selectedGymProvider);
  if (gym == null) return null;

  final clients = await ref.watch(trainerClientsProvider.future);
  return clients.firstWhere(
    (c) => c.id == clientId,
    orElse: () => throw Exception('Client not found'),
  );
});
