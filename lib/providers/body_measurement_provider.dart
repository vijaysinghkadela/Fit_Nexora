// lib/providers/body_measurement_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/body_measurement_model.dart';

class BodyMeasurementNotifier
    extends StateNotifier<AsyncValue<List<BodyMeasurement>>> {
  BodyMeasurementNotifier() : super(const AsyncValue.loading()) {
    load();
  }

  final _client = Supabase.instance.client;
  static const _table = 'body_measurements';

  String? get _userId => _client.auth.currentUser?.id;

  Future<void> load() async {
    final uid = _userId;
    if (uid == null) {
      state = const AsyncValue.data([]);
      return;
    }
    try {
      final rows = await _client
          .from(_table)
          .select()
          .eq('user_id', uid)
          .order('recorded_at', ascending: false)
          .limit(60);
      state = AsyncValue.data(
        (rows as List).map((r) => BodyMeasurement.fromMap(r)).toList(),
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> add({
    double? weightKg,
    double? heightCm,
    double? bodyFatPercent,
    double? muscleMassKg,
    double? waistCm,
    double? chestCm,
    double? armCm,
    double? thighCm,
    double? hipCm,
    String? notes,
  }) async {
    final uid = _userId;
    if (uid == null) return;

    final measurement = BodyMeasurement(
      id: const Uuid().v4(),
      userId: uid,
      weightKg: weightKg,
      heightCm: heightCm,
      bodyFatPercent: bodyFatPercent,
      muscleMassKg: muscleMassKg,
      waistCm: waistCm,
      chestCm: chestCm,
      armCm: armCm,
      thighCm: thighCm,
      hipCm: hipCm,
      notes: notes,
      recordedAt: DateTime.now(),
    );

    // Optimistic update
    final current = state.value ?? [];
    state = AsyncValue.data([measurement, ...current]);

    try {
      await _client.from(_table).insert(measurement.toMap());
    } catch (_) {
      state = AsyncValue.data(current); // rollback
      rethrow;
    }
  }

  Future<void> delete(String id) async {
    final current = state.value ?? [];
    final updated = current.where((m) => m.id != id).toList();
    state = AsyncValue.data(updated); // optimistic
    try {
      await _client.from(_table).delete().eq('id', id);
    } catch (_) {
      state = AsyncValue.data(current);
      rethrow;
    }
  }
}

final bodyMeasurementProvider = StateNotifierProvider<BodyMeasurementNotifier,
    AsyncValue<List<BodyMeasurement>>>(
  (ref) => BodyMeasurementNotifier(),
);

/// Latest measurement convenience provider
final latestMeasurementProvider = Provider<BodyMeasurement?>((ref) {
  final list = ref.watch(bodyMeasurementProvider).value ?? [];
  return list.isEmpty ? null : list.first;
});
