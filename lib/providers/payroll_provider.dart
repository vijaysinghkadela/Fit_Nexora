// lib/providers/payroll_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/payroll_model.dart';
import '../providers/auth_provider.dart';
import '../providers/gym_provider.dart';

final trainerContractsProvider =
    FutureProvider.autoDispose<List<TrainerContract>>((ref) async {
  final gym = ref.watch(selectedGymProvider);
  if (gym == null) return [];

  final db = ref.watch(databaseServiceProvider);
  final data = await db.getTrainerContracts(gym.id);
  return data.map((e) => TrainerContract.fromMap(e)).toList();
});

final payrollRunsProvider =
    FutureProvider.autoDispose<List<PayrollRun>>((ref) async {
  final gym = ref.watch(selectedGymProvider);
  if (gym == null) return [];

  final db = ref.watch(databaseServiceProvider);
  final data = await db.getPayrollRuns(gym.id);
  return data.map((e) => PayrollRun.fromMap(e)).toList();
});

final payrollRunDetailsProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>((ref, runId) async {
  final db = ref.watch(databaseServiceProvider);
  final data = await db.getPayrollRunDetails(runId);

  final run = PayrollRun.fromMap(data['run']);
  final slips =
      (data['slips'] as List).map((e) => SalarySlip.fromMap(e)).toList();

  return {
    'run': run,
    'slips': slips,
  };
});

final trainerSalarySlipsProvider =
    FutureProvider.autoDispose<List<SalarySlip>>((ref) async {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return [];

  final db = ref.watch(databaseServiceProvider);
  final data = await db.getTrainerSalarySlips(user.id);
  return data.map((e) => SalarySlip.fromMap(e)).toList();
});

final trainerActiveContractProvider =
    FutureProvider.autoDispose<TrainerContract?>((ref) async {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return null;

  final db = ref.watch(databaseServiceProvider);
  final data = await db.getTrainerActiveContract(user.id);
  if (data == null) return null;
  return TrainerContract.fromMap(data);
});
