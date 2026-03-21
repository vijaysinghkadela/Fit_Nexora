import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_provider.dart';

/// Current occupant count for the active gym.
final currentOccupancyProvider = FutureProvider.autoDispose.family<int, String>((ref, gymId) async {
  final db = ref.watch(databaseServiceProvider);
  return db.getCurrentOccupancyCount(gymId);
});

/// Equipment status summary for the active gym.
final equipmentSummaryProvider = FutureProvider.autoDispose.family<Map<String, int>, String>((ref, gymId) async {
  final db = ref.watch(databaseServiceProvider);
  return db.getEquipmentStatusSummary(gymId);
});
