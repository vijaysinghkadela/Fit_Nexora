import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/gym_model.dart';
import '../models/subscription_model.dart';
import 'auth_provider.dart';

/// Currently selected gym (for multi-gym owners).
final selectedGymProvider = StateProvider<Gym?>((ref) => null);

/// Gyms for the current user.
final userGymsProvider = FutureProvider<List<Gym>>((ref) async {
  final currentUser = ref.watch(currentUserProvider).value;
  if (currentUser == null) return [];

  final db = ref.read(databaseServiceProvider);
  return db.getGymsForUser(currentUser.id);
});

/// Dashboard stats for the selected gym.
final dashboardStatsProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  final gym = ref.watch(selectedGymProvider);
  if (gym == null) return {};

  final db = ref.read(databaseServiceProvider);
  return db.getDashboardStats(gym.id);
});

/// Current SaaS subscription for the selected gym.
final currentGymSubscriptionProvider =
    FutureProvider.autoDispose<Subscription?>((ref) async {
  final gym = ref.watch(selectedGymProvider);
  if (gym == null) return null;

  final db = ref.read(databaseServiceProvider);
  return db.getSubscription(gym.id);
});

/// Recent check-ins used for occupancy and traffic visualizations.
final recentGymCheckInsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final gym = ref.watch(selectedGymProvider);
  if (gym == null) return [];

  final db = ref.read(databaseServiceProvider);
  return db.getRecentCheckIns(gymId: gym.id);
});
