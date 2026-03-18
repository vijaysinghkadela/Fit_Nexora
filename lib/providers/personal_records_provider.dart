// lib/providers/personal_records_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/personal_record_model.dart';

class PersonalRecordsNotifier
    extends StateNotifier<AsyncValue<List<PersonalRecord>>> {
  PersonalRecordsNotifier() : super(const AsyncValue.loading()) {
    load();
  }

  final _client = Supabase.instance.client;
  static const _table = 'personal_records';

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
          .order('achieved_at', ascending: false);
      state = AsyncValue.data(
        (rows as List).map((r) => PersonalRecord.fromMap(r)).toList(),
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> add({
    required String exerciseName,
    required double weightKg,
    required int reps,
    String? notes,
  }) async {
    final uid = _userId;
    if (uid == null) return;

    final record = PersonalRecord(
      id: const Uuid().v4(),
      userId: uid,
      exerciseName: exerciseName,
      weightKg: weightKg,
      reps: reps,
      achievedAt: DateTime.now(),
      notes: notes,
    );

    final current = state.value ?? [];
    state = AsyncValue.data([record, ...current]);

    try {
      await _client.from(_table).insert(record.toMap());
    } catch (_) {
      state = AsyncValue.data(current);
      rethrow;
    }
  }

  Future<void> delete(String id) async {
    final current = state.value ?? [];
    state = AsyncValue.data(current.where((r) => r.id != id).toList());
    try {
      await _client.from(_table).delete().eq('id', id);
    } catch (_) {
      state = AsyncValue.data(current);
      rethrow;
    }
  }

  /// Returns only the best (highest estimated 1RM) per exercise.
  List<PersonalRecord> get bests {
    final records = state.value ?? [];
    final map = <String, PersonalRecord>{};
    for (final r in records) {
      final existing = map[r.exerciseName];
      if (existing == null ||
          r.estimatedOneRepMax > existing.estimatedOneRepMax) {
        map[r.exerciseName] = r;
      }
    }
    final list = map.values.toList()
      ..sort(
          (a, b) => b.estimatedOneRepMax.compareTo(a.estimatedOneRepMax));
    return list;
  }
}

final personalRecordsProvider = StateNotifierProvider<PersonalRecordsNotifier,
    AsyncValue<List<PersonalRecord>>>(
  (ref) => PersonalRecordsNotifier(),
);

/// Convenience: grouped bests map
final prBestsProvider = Provider<List<PersonalRecord>>((ref) {
  return ref.watch(personalRecordsProvider.notifier).bests;
});
