import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/fitness_profile_model.dart';
import '../models/ai_generated_plan_model.dart';
import '../services/ai_agent_service.dart';

/// Singleton AI agent service instance.
final aiAgentServiceProvider = Provider<AiAgentService>((ref) {
  return AiAgentService(Supabase.instance.client);
});

/// Fetch the fitness profile for a member in a gym.
final fitnessProfileProvider =
    FutureProvider.family<FitnessProfile?, ({String memberId, String gymId})>(
  (ref, params) async {
    final service = ref.read(aiAgentServiceProvider);
    return service.getFitnessProfile(params.memberId, params.gymId);
  },
);

/// Fetch previous AI-generated plans for a member in a gym.
final aiGeneratedPlansProvider =
    FutureProvider.family<List<AiGeneratedPlan>, ({String memberId, String gymId})>(
  (ref, params) async {
    final service = ref.read(aiAgentServiceProvider);
    return service.getGeneratedPlans(params.memberId, params.gymId);
  },
);

/// State notifier for AI report generation (loading, success, error).
class AiReportGeneratorNotifier extends StateNotifier<AsyncValue<AiGeneratedPlan?>> {
  final AiAgentService _service;

  AiReportGeneratorNotifier(this._service) : super(const AsyncData(null));

  /// Trigger the full AI agent pipeline.
  Future<void> generate({
    required String memberId,
    required String gymId,
  }) async {
    state = const AsyncLoading();
    try {
      final plan = await _service.generateMemberReport(
        memberId: memberId,
        gymId: gymId,
      );
      state = AsyncData(plan);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  void reset() {
    state = const AsyncData(null);
  }
}

/// Provider for the report generator notifier.
final aiReportGeneratorProvider =
    StateNotifierProvider<AiReportGeneratorNotifier, AsyncValue<AiGeneratedPlan?>>(
  (ref) {
    final service = ref.read(aiAgentServiceProvider);
    return AiReportGeneratorNotifier(service);
  },
);
