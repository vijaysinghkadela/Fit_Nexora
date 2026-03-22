import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/equipment_status_model.dart';

class EquipmentNotifier extends StateNotifier<AsyncValue<List<EquipmentStatus>>> {
  final String gymId;
  EquipmentNotifier(this.gymId) : super(const AsyncValue.loading()) {
    fetch();
  }

  final _client = Supabase.instance.client;
  static const _table = 'equipment_status';

  Future<void> fetch() async {
    state = const AsyncValue.loading();
    try {
      final rows = await _client
          .from(_table)
          .select()
          .eq('gym_id', gymId)
          .order('name');
      
      final list = (rows as List).map((e) => EquipmentStatus.fromJson(e)).toList();
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateStatus({
    required String id,
    int? inUse,
    int? outOfService,
  }) async {
    final prev = state.value ?? [];
    
    // Optimistic update
    state = AsyncValue.data(prev.map((e) {
      if (e.id == id) {
        return e.copyWith(
          inUse: inUse ?? e.inUse,
          outOfService: outOfService ?? e.outOfService,
          updatedAt: DateTime.now(),
        );
      }
      return e;
    }).toList());

    try {
      final map = {
        if (inUse != null) 'in_use': inUse,
        if (outOfService != null) 'out_of_service': outOfService,
        'updated_at': DateTime.now().toIso8601String(),
      };
      await _client.from(_table).update(map).eq('id', id);
    } catch (e) {
      // Rollback
      state = AsyncValue.data(prev);
      rethrow;
    }
  }
}

final equipmentProvider = StateNotifierProvider.family.autoDispose<
    EquipmentNotifier, AsyncValue<List<EquipmentStatus>>, String>(
  (ref, gymId) => EquipmentNotifier(gymId),
);
