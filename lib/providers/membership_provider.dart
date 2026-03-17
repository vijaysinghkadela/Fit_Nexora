import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/pagination.dart';
import '../models/membership_counts.dart';
import '../models/membership_model.dart';
import 'auth_provider.dart';
import '../core/dev_bypass.dart';
import 'gym_provider.dart';

const _membershipsPageSize = 12;

final membershipFilterProvider = StateProvider<String>((ref) => 'all');

final membershipCountsProvider = FutureProvider.autoDispose<MembershipCounts>(
  (ref) async {
    final user = ref.watch(currentUserProvider).value;
    if (user != null && isDevUser(user.email)) return devMembershipCounts();

    final gym = ref.watch(selectedGymProvider);
    if (gym == null) {
      return const MembershipCounts(total: 0, active: 0, expiring: 0);
    }
    return ref.read(databaseServiceProvider).getMembershipCounts(gym.id);
  },
);

final pagedMembershipsControllerProvider = StateNotifierProvider.autoDispose<
    CallbackPagedController<Membership>, PagedListState<Membership>>(
  (ref) {
    final controller = CallbackPagedController<Membership>((offset) async {
      final user = ref.read(currentUserProvider).value;
      if (user != null && isDevUser(user.email)) {
        return devMembershipsPaged(limit: _membershipsPageSize, offset: offset);
      }

      final gym = ref.read(selectedGymProvider);
      if (gym == null) {
        return const PagedResult<Membership>(
          items: [],
          hasMore: false,
          nextOffset: 0,
          totalCount: 0,
        );
      }

      return ref.read(databaseServiceProvider).getMembershipsForGymPaged(
            gym.id,
            limit: _membershipsPageSize,
            offset: offset,
            filter: ref.read(membershipFilterProvider),
          );
    });

    ref.listen(selectedGymProvider, (_, __) {
      ref.invalidate(membershipCountsProvider);
      controller.loadInitial();
    });
    ref.listen(membershipFilterProvider, (_, __) {
      controller.loadInitial();
    });

    Future.microtask(controller.loadInitial);
    return controller;
  },
);
