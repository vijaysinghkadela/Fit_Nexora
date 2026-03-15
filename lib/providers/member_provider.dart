import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/pagination.dart';
import '../models/membership_model.dart';
import '../models/workout_plan_model.dart';
import '../models/diet_plan_model.dart';
import '../models/announcement_model.dart';
import 'auth_provider.dart';
import 'gym_provider.dart';

const _announcementsPageSize = 10;

// ─── Access Gate ──────────────────────────────────────────────────────────────

/// The member's active membership for their gym. Null = no active membership.
final memberMembershipProvider =
    FutureProvider.autoDispose<Membership?>((ref) async {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return null;
  final db = ref.watch(databaseServiceProvider);
  return db.getActiveMembershipForUser(user.id);
});

/// True only if the member has a paid, non-expired membership.
/// This is the single paywall gate — every member screen checks this.
final memberHasAccessProvider = FutureProvider.autoDispose<bool>((ref) async {
  final membership = await ref.watch(memberMembershipProvider.future);
  if (membership == null) return false;
  return !membership.isExpired;
});

// ─── Workout ─────────────────────────────────────────────────────────────────

/// The active workout plan assigned to this member by their trainer.
final memberWorkoutPlanProvider =
    FutureProvider.autoDispose<WorkoutPlan?>((ref) async {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return null;
  final db = ref.watch(databaseServiceProvider);
  final raw = await db.getWorkoutPlanForClient(user.id);
  if (raw == null) return null;
  return WorkoutPlan.fromJson(raw);
});

// ─── Diet ────────────────────────────────────────────────────────────────────

/// The active diet plan assigned to this member by their trainer.
final memberDietPlanProvider =
    FutureProvider.autoDispose<DietPlan?>((ref) async {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return null;
  final db = ref.watch(databaseServiceProvider);
  final raw = await db.getDietPlanForClient(user.id);
  if (raw == null) return null;
  return DietPlan.fromJson(raw);
});

// ─── Progress ────────────────────────────────────────────────────────────────

/// Raw weight entries (latest first) for the weight chart.
final memberProgressProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return [];
  final db = ref.watch(databaseServiceProvider);
  return db.getProgressCheckIns(user.id);
});

// ─── Attendance ───────────────────────────────────────────────────────────────

/// Number of gym check-ins this calendar month.
final memberAttendanceProvider = FutureProvider.autoDispose<int>((ref) async {
  final user = ref.watch(currentUserProvider).value;
  final gym = ref.watch(selectedGymProvider);
  if (user == null || gym == null) return 0;
  final db = ref.watch(databaseServiceProvider);
  return db.getAttendanceThisMonth(gymId: gym.id, userId: user.id);
});

// ─── Announcements ────────────────────────────────────────────────────────────

/// Real-time stream of gym announcements.
final memberAnnouncementsProvider =
    StreamProvider.autoDispose<List<Announcement>>((ref) {
  final gym = ref.watch(selectedGymProvider);
  if (gym == null) return const Stream.empty();
  final db = ref.watch(databaseServiceProvider);
  return db
      .streamAnnouncements(gym.id)
      .map((rows) => rows.map(Announcement.fromJson).toList());
});

final pagedAnnouncementsControllerProvider = StateNotifierProvider.autoDispose
    .family<CallbackPagedController<Announcement>, PagedListState<Announcement>,
        String>((ref, gymId) {
  final controller = CallbackPagedController<Announcement>((offset) {
    return ref.read(databaseServiceProvider).getAnnouncementsPaged(
          gymId,
          limit: _announcementsPageSize,
          offset: offset,
        );
  });

  Future.microtask(controller.loadInitial);
  return controller;
});
