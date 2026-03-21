import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_notification_model.dart';

final notificationOverlayProvider = StateNotifierProvider<NotificationOverlayNotifier, AppNotification?>((ref) {
  return NotificationOverlayNotifier();
});

class NotificationOverlayNotifier extends StateNotifier<AppNotification?> {
  NotificationOverlayNotifier() : super(null);

  Timer? _dismissTimer;

  void show(AppNotification notification) {
    // Cancel existing timer
    _dismissTimer?.cancel();

    // If a notification is already showing, wait for it to clear or just replace it
    // For now, we replace it immediately
    state = notification;

    // Set auto-dismiss timer
    _dismissTimer = Timer(notification.duration, () {
      dismiss();
    });
  }

  void dismiss() {
    _dismissTimer?.cancel();
    state = null;
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    super.dispose();
  }
}
