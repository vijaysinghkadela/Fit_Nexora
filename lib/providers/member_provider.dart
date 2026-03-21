import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/pagination.dart';
import '../core/dev_bypass.dart';
import '../models/membership_model.dart';
import '../models/workout_plan_model.dart';
import '../models/diet_plan_model.dart';
import '../models/announcement_model.dart';
import 'auth_provider.dart';
import 'gym_provider.dart';

import '../services/notification_service.dart';

const _announcementsPageSize = 10;

// ─── Access Gate ──────────────────────────────────────────────────────────────

/// The member's active membership for their gym. Null = no active membership.
final memberMembershipProvider =
    FutureProvider.autoDispose<Membership?>((ref) async {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return null;

  // Developer Bypass: Unlock Master plan for testing all features
  if (isDevUser(user.email)) return devMembership();

  final db = ref.watch(databaseServiceProvider);
  final membership = await db.getActiveMembershipForUser(user.id);

  if (membership != null) {
    // Attempt to schedule a 7-day warning
    final gym = ref.read(selectedGymProvider);
    NotificationService.scheduleMembershipExpiryWarning(
      expiryDate: membership.endDate,
      gymName: gym?.name ?? 'Your Gym',
    );
  }

  return membership;
});

/// True only if the member has a paid, non-expired membership.
/// This is the premium paywall gate - only checks for premium features.
/// Free tier features are ALWAYS accessible regardless of membership status.
final memberHasAccessProvider = FutureProvider.autoDispose<bool>((ref) async {
  final membership = await ref.watch(memberMembershipProvider.future);
  
  // Developer bypass (uncomment for testing with dev emails)
  // final user = ref.watch(currentUserProvider).value;
  // if (user != null && isDevUser(user.email)) return true;
  
  // For premium features only - check if membership is active
  if (membership == null) return false;
  return !membership.isExpired;
});

/// Determines if a member can access FREE tier features.
/// Returns true for ALL authenticated users (members don't need paid plans for free features).
final memberCanAccessFreeFeaturesProvider = FutureProvider.autoDispose<bool>((ref) async {
  final user = ref.watch(currentUserProvider).value;
  
  // Developer bypass (uncomment for testing with dev emails)
  // if (user != null && isDevUser(user.email)) return true;
  
  // Any authenticated member has access to free features
  // Membership/payment is ONLY required for premium features
  return user != null;
});

/// Maps specific features to their access level (free vs premium)
/// 
/// Usage: 
/// final canAccess = ref.watch(memberCanAccessFeatureProvider('feature_id'));
/// if (!canAccess) { return const UpgradePrompt(); }
final memberCanAccessFeatureProvider = Provider.family<bool, String>((ref, featureId) {
  final user = ref.watch(currentUserProvider).value;
  
  if (user == null) return false; // Must be authenticated
  
  // FREE TIER - These 5 features are ALWAYS accessible
  const freeFeatures = {
    'attendance',           // Attendance tracking
    'gym_traffic',          // Live gym traffic
    'calendar',             // Workout calendar
    'motivation_quotes',    // Motivation quotes (NEW)
    'checkin_checkout',     // Check-in/check-out
  };
  
  if (freeFeatures.contains(featureId)) {
    return true; // These features are always free
  }
  
  // PREMIUM FEATURES = require paid membership
  final membership = ref.watch(memberMembershipProvider).value;
  if (membership == null) return false;
  if (membership.isExpired) return false;
  
  return true; // Has active membership → can access premium features
});

// ─── Workout ─────────────────────────────────────────────────────────────────

/// The active workout plan assigned to this member by their trainer.
final memberWorkoutPlanProvider =
    FutureProvider.autoDispose<WorkoutPlan?>((ref) async {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return null;

  // Developer Bypass: Return mock workout plan
  if (isDevUser(user.email)) return devWorkoutPlan();

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

  // Developer Bypass: Return mock diet plan
  if (isDevUser(user.email)) return devDietPlan();

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

  // Developer Bypass: Return mock progress data
  if (isDevUser(user.email)) return devProgressData();

  final db = ref.watch(databaseServiceProvider);
  return db.getProgressCheckIns(user.id);
});

// ─── Attendance ───────────────────────────────────────────────────────────────

/// Number of gym check-ins this calendar month.
final memberAttendanceProvider = FutureProvider.autoDispose<int>((ref) async {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return 0;

  // Developer Bypass: Return mock attendance
  if (isDevUser(user.email)) return devAttendanceThisMonth;

  final gym = ref.watch(selectedGymProvider);
  if (gym == null) return 0;
  final db = ref.watch(databaseServiceProvider);
  return db.getAttendanceThisMonth(gymId: gym.id, userId: user.id);
});

// ─── Announcements ────────────────────────────────────────────────────────────

/// Real-time stream of gym announcements.
final memberAnnouncementsProvider =
    StreamProvider.autoDispose<List<Announcement>>((ref) {
  final user = ref.watch(currentUserProvider).value;

  // Developer Bypass: Return mock announcements
  if (user != null && isDevUser(user.email)) {
    return Stream.value(devAnnouncements());
  }

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
