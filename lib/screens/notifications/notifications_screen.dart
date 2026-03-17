import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../core/extensions.dart';
import '../../providers/notifications_provider.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  static const _tabs = ['All', 'Membership', 'Gym', 'Workouts'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;
    final notifications = ref.watch(notificationsProvider);

    final hasExpiringMembership = notifications.any((n) =>
        n.type == NotificationType.membership && !n.isRead);

    return Scaffold(
      backgroundColor: t.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            floating: true,
            pinned: true,
            backgroundColor: t.surface,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_rounded, color: t.textPrimary),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              'Notifications',
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: t.textPrimary,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () =>
                    ref.read(notificationsProvider.notifier).markAllRead(),
                child: Text(
                  'Mark all read',
                  style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: t.brand),
                ),
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: t.brand,
              labelColor: t.brand,
              unselectedLabelColor: t.textMuted,
              labelStyle: GoogleFonts.inter(
                  fontSize: 13, fontWeight: FontWeight.w700),
              unselectedLabelStyle:
                  GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
              tabs: _tabs.map((t) => Tab(text: t)).toList(),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: _tabs.asMap().entries.map((entry) {
            return _NotificationsTab(
              tabIndex: entry.key,
              tabLabel: entry.value,
              hasExpiringMembership: hasExpiringMembership,
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _NotificationsTab extends ConsumerStatefulWidget {
  final int tabIndex;
  final String tabLabel;
  final bool hasExpiringMembership;

  const _NotificationsTab({
    required this.tabIndex,
    required this.tabLabel,
    required this.hasExpiringMembership,
  });

  @override
  ConsumerState<_NotificationsTab> createState() => _NotificationsTabState();
}

class _NotificationsTabState extends ConsumerState<_NotificationsTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final t = context.fitTheme;
    final all = ref.watch(notificationsProvider);

    List<AppNotification> items;
    if (widget.tabIndex == 0) {
      items = all;
    } else {
      final typeMap = {
        1: NotificationType.membership,
        2: NotificationType.gym,
        3: NotificationType.workout,
      };
      items = all.where((n) => n.type == typeMap[widget.tabIndex]).toList();
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      itemCount: items.length +
          (widget.hasExpiringMembership && widget.tabIndex == 0 ? 1 : 0),
      itemBuilder: (context, index) {
        // Pinned membership alert at top of "All" tab
        if (widget.hasExpiringMembership && widget.tabIndex == 0 && index == 0) {
          return _MembershipExpiryAlert().animate().fadeIn();
        }

        final offset = (widget.hasExpiringMembership && widget.tabIndex == 0) ? 1 : 0;
        final notification = items[index - offset];

        return Dismissible(
          key: ValueKey(notification.id),
          direction: DismissDirection.endToStart,
          onDismissed: (_) {
            ref.read(notificationsProvider.notifier).dismiss(notification.id);
          },
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            decoration: BoxDecoration(
              color: t.danger.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.delete_outline_rounded, color: t.danger),
          ),
          child: GestureDetector(
            onTap: () => ref
                .read(notificationsProvider.notifier)
                .markRead(notification.id),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: notification.isRead ? t.surface : t.surfaceAlt,
                borderRadius: BorderRadius.circular(16),
                border: Border(
                  left: BorderSide(
                    color: notification.isRead ? t.border : t.brand,
                    width: 3,
                  ),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _typeColor(notification.type, t)
                            .withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _typeIcon(notification.type),
                        color: _typeColor(notification.type, t),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  notification.title,
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: notification.isRead
                                        ? FontWeight.w500
                                        : FontWeight.w700,
                                    color: t.textPrimary,
                                  ),
                                ),
                              ),
                              if (!notification.isRead)
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: t.brand,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            notification.body,
                            style: GoogleFonts.inter(
                                fontSize: 13, color: t.textSecondary),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            notification.createdAt.relative,
                            style: GoogleFonts.inter(
                                fontSize: 11, color: t.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ).animate(delay: (index * 40).ms).fadeIn().slideY(begin: 0.04),
          ),
        );
      },
    );
  }

  Color _typeColor(NotificationType type, FitNexoraThemeTokens t) {
    switch (type) {
      case NotificationType.membership:
        return t.warning;
      case NotificationType.gym:
        return t.info;
      case NotificationType.workout:
        return t.accent;
      case NotificationType.general:
        return t.brand;
    }
  }

  IconData _typeIcon(NotificationType type) {
    switch (type) {
      case NotificationType.membership:
        return Icons.card_membership_rounded;
      case NotificationType.gym:
        return Icons.campaign_rounded;
      case NotificationType.workout:
        return Icons.fitness_center_rounded;
      case NotificationType.general:
        return Icons.notifications_rounded;
    }
  }
}

class _MembershipExpiryAlert extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.fitTheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: t.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: t.warning.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: t.warning, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Membership Expiring Soon',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: t.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Renew before expiry to keep access',
                  style: GoogleFonts.inter(
                      fontSize: 12, color: t.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () => context.push('/pricing'),
            style: TextButton.styleFrom(
              foregroundColor: t.warning,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: t.warning.withValues(alpha: 0.4)),
              ),
            ),
            child: Text('Renew',
                style: GoogleFonts.inter(
                    fontSize: 13, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
