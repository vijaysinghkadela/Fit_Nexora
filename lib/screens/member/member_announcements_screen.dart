import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/dev_bypass.dart';
import '../../core/extensions.dart';
import '../../models/announcement_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/gym_provider.dart';
import '../../providers/member_provider.dart';
import '../../widgets/error_widgets.dart';
import '../../widgets/loading_widgets.dart';
import '../../widgets/member_bottom_nav.dart';

class MemberAnnouncementsScreen extends ConsumerWidget {
  const MemberAnnouncementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.fitTheme;
    final user = ref.watch(currentUserProvider).value;
    final gym = ref.watch(selectedGymProvider);

    // Developer Bypass: Show mock announcements when no gym
    if (gym == null && user != null && isDevUser(user.email)) {
      final announcements = devAnnouncements();
      return Scaffold(
        backgroundColor: t.background,
        bottomNavigationBar: const MemberBottomNav(),
        appBar: AppBar(
          backgroundColor: t.background,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_rounded, color: t.textSecondary),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/member');
              }
            },
          ),
          title: Text(
            'Announcements',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: t.textPrimary,
            ),
          ),
        ),
        body: ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: announcements.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) => _AnnouncementCard(
            announcement: announcements[index],
            delay: index * 60,
          ),
        ),
      );
    }

    if (gym == null) {
      return Scaffold(
        backgroundColor: t.background,
        bottomNavigationBar: const MemberBottomNav(),
        appBar: AppBar(
          backgroundColor: t.background,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_rounded, color: t.textSecondary),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/member');
              }
            },
          ),
          title: Text(
            'Announcements',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: t.textPrimary,
            ),
          ),
        ),
        body: Center(
          child: Text(
            'No gym selected',
            style: GoogleFonts.inter(color: t.textMuted),
          ),
        ),
      );
    }

    final announcementsState =
        ref.watch(pagedAnnouncementsControllerProvider(gym.id));

    return Scaffold(
      backgroundColor: t.background,
      appBar: AppBar(
        backgroundColor: t.background,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/member');
            }
          },
        ),
        title: Text(
          'Announcements',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: t.textPrimary,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref
            .read(pagedAnnouncementsControllerProvider(gym.id).notifier)
            .refresh(),
        backgroundColor: t.surface,
        color: t.brand,
        child: Builder(
          builder: (context) {
            if (announcementsState.isInitialLoading) {
              return ListView.builder(
                padding: const EdgeInsets.all(20),
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: 4,
                itemBuilder: (_, __) => const CardSkeleton(height: 150),
              );
            }

            if (announcementsState.items.isEmpty &&
                announcementsState.hasError) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.sizeOf(context).height * 0.7,
                    child: ErrorStateWidget(
                      message: 'Unable to load announcements.',
                      onRetry: () => ref
                          .read(pagedAnnouncementsControllerProvider(gym.id)
                              .notifier)
                          .loadInitial(),
                    ),
                  ),
                ],
              );
            }

            if (announcementsState.items.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.sizeOf(context).height * 0.7,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.campaign_rounded,
                          size: 56,
                          color: t.textMuted,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No announcements yet',
                          style: GoogleFonts.inter(
                            color: t.textSecondary,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Your gym will post updates here.',
                          style: GoogleFonts.inter(
                            color: t.textMuted,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(20),
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: announcementsState.items.length + 1,
              separatorBuilder: (_, index) =>
                  index == announcementsState.items.length - 1
                      ? const SizedBox.shrink()
                      : const SizedBox(height: 12),
              itemBuilder: (context, index) {
                if (index == announcementsState.items.length) {
                  return LoadingFooter(
                    isLoading: announcementsState.isLoadingMore,
                    hasMore: announcementsState.hasMore,
                    error: announcementsState.items.isNotEmpty
                        ? announcementsState.error
                        : null,
                    onPressed: () => ref
                        .read(pagedAnnouncementsControllerProvider(gym.id)
                            .notifier)
                        .loadMore(),
                  );
                }
                return _AnnouncementCard(
                  announcement: announcementsState.items[index],
                  delay: index * 60,
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  const _AnnouncementCard({
    required this.announcement,
    required this.delay,
  });

  final Announcement announcement;
  final int delay;

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;
    final isPinned = announcement.isPinned;
    final isAppUpdate = announcement.type == 'app';

    // App updates use brand colors, gym uses info/warning
    final color = isAppUpdate ? t.brand : (isPinned ? t.warning : t.info);

    final icon = isAppUpdate
        ? Icons.system_update_rounded
        : (isPinned ? Icons.push_pin_rounded : Icons.campaign_rounded);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isAppUpdate ? t.brand.withOpacity(0.05) : t.surfaceAlt,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isAppUpdate
              ? t.brand.withOpacity(0.3)
              : (isPinned ? t.warning.withOpacity(0.3) : t.border),
          width: (isPinned || isAppUpdate) ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              if (isAppUpdate)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [t.brand, t.accent]),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'APP UPDATE',
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 1,
                    ),
                  ),
                )
              else if (isPinned)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: t.warning.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: t.warning.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    'PINNED',
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: t.warning,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              const Spacer(),
              Text(
                announcement.createdAt.dayMonth,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: t.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            announcement.title,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: t.textPrimary,
            ),
          ),
          if (announcement.body != null && announcement.body!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              announcement.body!,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: t.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    )
        .animate(delay: Duration(milliseconds: delay))
        .fadeIn()
        .slideY(begin: 0.04);
  }
}
