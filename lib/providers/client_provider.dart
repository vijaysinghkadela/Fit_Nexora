import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/enums.dart';
import '../core/pagination.dart';
import '../models/client_profile_model.dart';
import '../models/membership_model.dart';
import 'auth_provider.dart';
import '../core/dev_bypass.dart';
import 'gym_provider.dart';

const _clientsPageSize = 12;

/// Client search query.
final clientSearchQueryProvider = StateProvider<String>((ref) => '');

/// Client sort order.
final clientSortProvider = StateProvider<String>((ref) => 'name_asc');

/// Client goal filter.
final clientGoalFilterProvider = StateProvider<FitnessGoal?>((ref) => null);

/// All clients for the selected gym.
final gymClientsProvider = FutureProvider<List<ClientProfile>>((ref) async {
  final gym = ref.watch(selectedGymProvider);
  if (gym == null) return [];

  final db = ref.read(databaseServiceProvider);
  return db.getClientsForGym(gym.id);
});

/// Clients assigned to the currently signed-in trainer.
final trainerClientsProvider =
    FutureProvider.autoDispose<List<ClientProfile>>((ref) async {
  final gym = ref.watch(selectedGymProvider);
  final user = ref.watch(currentUserProvider).value;
  if (gym == null || user == null) return [];

  final db = ref.read(databaseServiceProvider);
  return db.getClientsForTrainer(gym.id, user.id);
});

/// Memberships expiring within 7 days.
final expiringMembershipsProvider =
    FutureProvider<List<Membership>>((ref) async {
  final gym = ref.watch(selectedGymProvider);
  if (gym == null) return [];

  final db = ref.read(databaseServiceProvider);
  return db.getExpiringMemberships(gym.id, days: 7);
});

final pagedClientsControllerProvider = StateNotifierProvider.autoDispose<
    CallbackPagedController<ClientProfile>, PagedListState<ClientProfile>>(
  (ref) {
    final controller = CallbackPagedController<ClientProfile>((offset) async {
      final user = ref.read(currentUserProvider).value;
      if (user != null && isDevUser(user.email)) {
        return devClientsPaged(
          limit: _clientsPageSize,
          offset: offset,
          search: ref.read(clientSearchQueryProvider),
          goalFilter: ref.read(clientGoalFilterProvider),
          sort: ref.read(clientSortProvider),
        );
      }

      final gym = ref.read(selectedGymProvider);
      if (gym == null) {
        return const PagedResult<ClientProfile>(
          items: [],
          hasMore: false,
          nextOffset: 0,
          totalCount: 0,
        );
      }

      return ref.read(databaseServiceProvider).getClientsForGymPaged(
            gym.id,
            limit: _clientsPageSize,
            offset: offset,
            search: ref.read(clientSearchQueryProvider),
            goalFilter: ref.read(clientGoalFilterProvider),
            sort: ref.read(clientSortProvider),
          );
    });

    ref.listen(selectedGymProvider, (_, __) {
      controller.loadInitial();
    });
    ref.listen(clientSearchQueryProvider, (_, __) {
      controller.loadInitial();
    });
    ref.listen(clientSortProvider, (_, __) {
      controller.loadInitial();
    });
    ref.listen(clientGoalFilterProvider, (_, __) {
      controller.loadInitial();
    });

    Future.microtask(controller.loadInitial);
    return controller;
  },
);
