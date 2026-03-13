import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/client_profile_model.dart';
import '../models/membership_model.dart';
import 'auth_provider.dart';
import 'gym_provider.dart';

/// All clients for the selected gym.
final gymClientsProvider = FutureProvider<List<ClientProfile>>((ref) async {
  final gym = ref.watch(selectedGymProvider);
  if (gym == null) return [];

  final db = ref.read(databaseServiceProvider);
  return db.getClientsForGym(gym.id);
});

/// Memberships expiring within 7 days.
final expiringMembershipsProvider =
    FutureProvider<List<Membership>>((ref) async {
  final gym = ref.watch(selectedGymProvider);
  if (gym == null) return [];

  final db = ref.read(databaseServiceProvider);
  return db.getExpiringMemberships(gym.id, days: 7);
});
