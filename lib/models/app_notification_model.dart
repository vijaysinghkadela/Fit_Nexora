import 'package:flutter/material.dart';

enum NotificationType {
  membership,
  hydration,
  steps,
  diet,
  sleep,
  info,
}

class AppNotification {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final IconData? icon;
  final Color? color;
  final VoidCallback? onTap;
  final Duration duration;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.icon,
    this.color,
    this.onTap,
    this.duration = const Duration(seconds: 4),
  });

  factory AppNotification.membership({
    required String gymName,
    required int daysLeft,
    VoidCallback? onTap,
  }) {
    return AppNotification(
      id: 'membership_expiry',
      title: 'Membership expiring soon',
      body: 'Your $gymName membership expires in $daysLeft days. Renew to keep access.',
      type: NotificationType.membership,
      icon: Icons.card_membership_rounded,
      color: Colors.orange,
      onTap: onTap,
      duration: const Duration(seconds: 6),
    );
  }

  factory AppNotification.hydration({
    required int currentMl,
    required int goalMl,
    VoidCallback? onTap,
  }) {
    return AppNotification(
      id: 'hydration_reminder',
      title: 'Stay Hydrated!',
      body: '$currentMl / $goalMl ml today. Time for a glass of water?',
      type: NotificationType.hydration,
      icon: Icons.water_drop_rounded,
      color: Colors.blue,
      onTap: onTap,
    );
  }

  factory AppNotification.steps({
    required int currentSteps,
    required int goalSteps,
    bool isComplete = false,
    VoidCallback? onTap,
  }) {
    return AppNotification(
      id: 'steps_goal',
      title: isComplete ? 'Goal Reached! 🎉' : 'Keep Walking!',
      body: isComplete 
          ? 'You hit your $goalSteps steps goal! Amazing work.'
          : '$currentSteps / $goalSteps steps today. You\'re almost there!',
      type: NotificationType.steps,
      icon: Icons.directions_walk_rounded,
      color: isComplete ? Colors.green : Colors.purple,
      onTap: onTap,
    );
  }

  factory AppNotification.diet({
    required String mealName,
    required String timing,
    VoidCallback? onTap,
  }) {
    return AppNotification(
      id: 'diet_mealtime_${mealName.replaceAll(' ', '_')}',
      title: 'Mealtime: $mealName',
      body: 'Scheduled for $timing. Don\'t forget to fuel your body!',
      type: NotificationType.diet,
      icon: Icons.restaurant_rounded,
      color: Colors.teal,
      onTap: onTap,
    );
  }
}
