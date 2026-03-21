import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/extensions.dart';
import '../providers/notification_overlay_provider.dart';
import '../services/notification_trigger_manager.dart';


class AppNotificationOverlay extends ConsumerWidget {
  final Widget child;

  const AppNotificationOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notification = ref.watch(notificationOverlayProvider);
    final t = context.fitTheme;

    return Stack(
      children: [
        // Main App Content
        child,

        // Notification Trigger Manager (Headless)
        const NotificationTriggerManager(),

        // The Overlay Alert
        if (notification != null)
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            right: 16,
            child: GestureDetector(
              onVerticalDragUpdate: (details) {
                if (details.delta.dy < -10) {
                  ref.read(notificationOverlayProvider.notifier).dismiss();
                }
              },
              onTap: () {
                notification.onTap?.call();
                ref.read(notificationOverlayProvider.notifier).dismiss();
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: t.surface.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: (notification.color ?? t.brand).withOpacity(0.3),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Icon Circle
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: (notification.color ?? t.brand).withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            notification.icon ?? Icons.notifications_rounded,
                            color: notification.color ?? t.brand,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Text Content
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                notification.title,
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: t.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                notification.body,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: t.textSecondary,
                                  height: 1.2,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        // Handle
                        Container(
                          width: 4,
                          height: 30,
                          decoration: BoxDecoration(
                            color: t.textMuted.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
            .animate()
            .slideY(
              begin: -1.5,
              end: 0,
              curve: Curves.easeOutBack,
              duration: 600.ms,
            )
            .fadeIn(duration: 400.ms)
            .shimmer(
              duration: 2.seconds,
              color: (notification.color ?? t.brand).withOpacity(0.2),
            ),
          ),
      ],
    );
  }
}
