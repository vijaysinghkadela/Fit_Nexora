import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/dev_bypass.dart';
import '../models/progress_checkin_model.dart';
import 'auth_provider.dart';
import 'member_provider.dart';

// ─── Elite Access Gate ────────────────────────────────────────────────────────

const _eliteTiers = {
  'elite',
  'elite_monthly',
  'elite_yearly',
  'Elite Plan',
  'Elite Monthly',
  'Elite Yearly',
  'master',
  'Master',
  'Master Plan',
};

/// True when the member has an active Elite membership.
final memberHasEliteAccessProvider =
    FutureProvider.autoDispose<bool>((ref) async {
  final user = ref.watch(currentUserProvider).value;
  if (user != null && isDevUser(user.email)) return true;

  final membership = await ref.watch(memberMembershipProvider.future);
  if (membership == null || membership.isExpired) return false;
  return _eliteTiers
      .any((t) => membership.planName.toLowerCase().contains(t.toLowerCase()));
});

// ─── Supplements ──────────────────────────────────────────────────────────────

/// Today's supplement logs.
final eliteSupplementsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return [];
  final db = ref.watch(databaseServiceProvider);
  return db.getSupplementLogs(user.id);
});

// ─── Muscle Group Progress ────────────────────────────────────────────────────

/// All progress check-ins with muscle metrics.
final eliteMuscleProgressProvider =
    FutureProvider.autoDispose<List<ProgressCheckIn>>((ref) async {
  final clientId = await ref.watch(memberClientIdProvider.future);
  if (clientId == null) return [];
  final db = ref.watch(databaseServiceProvider);
  final entries = await db.getProgressCheckIns(clientId);
  return entries.map(ProgressCheckIn.fromJson).toList();
});

// ─── Transformation Photos ────────────────────────────────────────────────────

/// All progress check-ins that have at least one photo.
final eliteTransformationPhotosProvider =
    FutureProvider.autoDispose<List<ProgressCheckIn>>((ref) async {
  final clientId = await ref.watch(memberClientIdProvider.future);
  if (clientId == null) return [];
  final db = ref.watch(databaseServiceProvider);
  final entries = await db.getProgressCheckIns(clientId);
  return entries
      .map(ProgressCheckIn.fromJson)
      .where((e) =>
          e.frontPhotoUrl != null ||
          e.sidePhotoUrl != null ||
          e.backPhotoUrl != null)
      .toList();
});

// ─── Trainer Chat Messages ────────────────────────────────────────────────────

/// Stream of trainer chat messages for the current member.
final eliteTrainerChatProvider =
    StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return const Stream.empty();
  final db = ref.watch(databaseServiceProvider);
  return db.streamTrainerMessages(user.id);
});
