import 'package:flutter_riverpod/flutter_riverpod.dart';

enum NotificationType { membership, gym, workout, general }

class AppNotification {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final DateTime createdAt;
  final bool isRead;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.createdAt,
    required this.isRead,
  });

  AppNotification copyWith({bool? isRead}) => AppNotification(
        id: id,
        title: title,
        body: body,
        type: type,
        createdAt: createdAt,
        isRead: isRead ?? this.isRead,
      );
}

class NotificationsNotifier extends StateNotifier<List<AppNotification>> {
  NotificationsNotifier() : super(_mockNotifications());

  static List<AppNotification> _mockNotifications() {
    final now = DateTime.now();
    return [
      AppNotification(
        id: '1',
        title: 'Membership Expiring Soon',
        body: 'Your Pro membership expires in 5 days. Renew now to keep access.',
        type: NotificationType.membership,
        createdAt: now.subtract(const Duration(hours: 2)),
        isRead: false,
      ),
      AppNotification(
        id: '2',
        title: 'Second Membership Reminder',
        body: 'Don\'t miss out — renew before March 21 for 10% early-bird discount.',
        type: NotificationType.membership,
        createdAt: now.subtract(const Duration(hours: 10)),
        isRead: false,
      ),
      AppNotification(
        id: '3',
        title: 'Gym Closed on Sunday',
        body: 'FitNexora Gym will be closed this Sunday for maintenance. Plan accordingly.',
        type: NotificationType.gym,
        createdAt: now.subtract(const Duration(days: 1)),
        isRead: true,
      ),
      AppNotification(
        id: '4',
        title: 'New Equipment Arrived',
        body: 'We\'ve added 4 new cable machines and 2 Smith machines to the floor!',
        type: NotificationType.gym,
        createdAt: now.subtract(const Duration(days: 2)),
        isRead: true,
      ),
      AppNotification(
        id: '5',
        title: 'Workout Reminder',
        body: 'You haven\'t logged a workout in 3 days. Let\'s get back on track!',
        type: NotificationType.workout,
        createdAt: now.subtract(const Duration(days: 3)),
        isRead: false,
      ),
      AppNotification(
        id: '6',
        title: 'Check-In Recorded',
        body: 'Your gym check-in for today has been logged successfully. Keep it up!',
        type: NotificationType.general,
        createdAt: now.subtract(const Duration(days: 4)),
        isRead: true,
      ),
    ];
  }

  void markAllRead() {
    state = state.map((n) => n.copyWith(isRead: true)).toList();
  }

  void markRead(String id) {
    state = state
        .map((n) => n.id == id ? n.copyWith(isRead: true) : n)
        .toList();
  }

  void dismiss(String id) {
    state = state.where((n) => n.id != id).toList();
  }
}

final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, List<AppNotification>>(
  (ref) => NotificationsNotifier(),
);

final unreadCountProvider = Provider<int>((ref) {
  return ref.watch(notificationsProvider).where((n) => !n.isRead).length;
});
