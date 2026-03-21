import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/gym_model.dart';
import '../models/subscription_model.dart';
import 'auth_provider.dart';
import '../core/enums.dart';
import '../core/dev_bypass.dart';

/// Currently selected gym (for multi-gym owners).
/// Auto-selects the first gym for real users once userGymsProvider loads.
final selectedGymProvider = StateProvider<Gym?>((ref) {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return null;

  if (isDevUser(user.email)) return devGyms().first;

  // Auto-select the first gym when real user's gyms are loaded
  final gyms = ref.watch(userGymsProvider).value;
  if (gyms != null && gyms.isNotEmpty) return gyms.first;

  return null;
});

/// Gyms for the current user.
final userGymsProvider = FutureProvider.autoDispose<List<Gym>>((ref) async {
  final currentUser = ref.watch(currentUserProvider).value;
  if (currentUser == null) return [];

  if (isDevUser(currentUser.email)) return devGyms();

  final db = ref.read(databaseServiceProvider);
  return db.getGymsForUser(currentUser.id);
});

/// Dashboard stats for the selected gym.
final dashboardStatsProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final user = ref.watch(currentUserProvider).value;
  if (user != null && isDevUser(user.email)) return devDashboardStats();

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

  final currentUser = ref.watch(currentUserProvider).value;
  
  if (currentUser != null && isDevUser(currentUser.email)) {
    // Return a mock Pro subscription for developer users to test unlocked features
    return Subscription(
      id: 'dev-sub',
      gymId: gym.id,
      planTier: PlanTier.pro,
      status: SubscriptionStatus.active,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

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
