import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/app_notification_model.dart';
import '../providers/member_provider.dart';
import '../providers/water_tracker_provider.dart';
import '../providers/health_provider.dart';
import '../providers/notification_overlay_provider.dart';
import '../providers/gym_provider.dart';

class NotificationTriggerManager extends ConsumerStatefulWidget {
  const NotificationTriggerManager({super.key});

  @override
  ConsumerState<NotificationTriggerManager> createState() => _NotificationTriggerManagerState();
}

class _NotificationTriggerManagerState extends ConsumerState<NotificationTriggerManager> {
  // Track which notifications have been shown today to avoid spamming
  final Set<String> _shownToday = {};
  DateTime _lastCheckDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    // We use ref.listen to react to provider changes
    _setupListeners();
    return const SizedBox.shrink();
  }

  void _setupListeners() {
    _resetDailyTrackerIfNeeded();

    // 1. Membership Expiry
    ref.listen(memberMembershipProvider, (previous, next) {
      if (next.hasValue && next.value != null) {
        final membership = next.value!;
        final daysLeft = membership.endDate.difference(DateTime.now()).inDays;
        
        if (daysLeft <= 7 && !_shownToday.contains('membership_expiry')) {
          final gym = ref.read(selectedGymProvider);
          _showNotification(AppNotification.membership(
            gymName: gym?.name ?? 'Your Gym',
            daysLeft: daysLeft,
          ));
          _shownToday.add('membership_expiry');
        }
      }
    });

    // 2. Hydration Goals
    ref.listen(waterTrackerProvider, (previous, next) {
      final state = next;
      final progress = state.progressFraction;
      
      // Trigger at specific milestones (50%, 90%, 100%)
      if (progress >= 1.0 && !_shownToday.contains('hydration_100')) {
        _showNotification(AppNotification.hydration(
          currentMl: state.totalTodayMl,
          goalMl: state.dailyGoalMl,
        ));
        _shownToday.add('hydration_100');
      } else if (progress >= 0.5 && progress < 0.6 && !_shownToday.contains('hydration_50')) {
        _showNotification(AppNotification.hydration(
          currentMl: state.totalTodayMl,
          goalMl: state.dailyGoalMl,
        ));
        _shownToday.add('hydration_50');
      }
    });

    // 3. Steps Goals
    ref.listen(stepsProvider, (previous, next) {
      final state = next;
      final progress = state.stepsToday / state.dailyGoal;
      
      if (progress >= 1.0 && !_shownToday.contains('steps_100')) {
        _showNotification(AppNotification.steps(
          currentSteps: state.stepsToday,
          goalSteps: state.dailyGoal,
          isComplete: true,
        ));
        _shownToday.add('steps_100');
      } else if (progress >= 0.9 && progress < 1.0 && !_shownToday.contains('steps_90')) {
        _showNotification(AppNotification.steps(
          currentSteps: state.stepsToday,
          goalSteps: state.dailyGoal,
        ));
        _shownToday.add('steps_90');
      }
    });

    // 4. Diet Mealtime Alerts
    ref.listen(memberDietPlanProvider, (previous, next) {
      if (next.hasValue && next.value != null) {
        final plan = next.value!;
        final now = DateTime.now();
        final currentTimeStr = DateFormat('hh:mm a').format(now);

        for (final meal in plan.meals) {
          // If timing matches current time or we are within a 5-minute window
          if (meal.timing == currentTimeStr && !_shownToday.contains('meal_${meal.name}')) {
            _showNotification(AppNotification.diet(
              mealName: meal.name,
              timing: meal.timing,
            ));
            _shownToday.add('meal_${meal.name}');
          }
        }
      }
    });
  }

  void _showNotification(AppNotification notification) {
    // Delay slightly to avoid issues with build cycle
    Future.microtask(() {
      if (mounted) {
        ref.read(notificationOverlayProvider.notifier).show(notification);
      }
    });
  }

  void _resetDailyTrackerIfNeeded() {
    final now = DateTime.now();
    if (now.day != _lastCheckDate.day) {
      _shownToday.clear();
      _lastCheckDate = now;
    }
  }
}
