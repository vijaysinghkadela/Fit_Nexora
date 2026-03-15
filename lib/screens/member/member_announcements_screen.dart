import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants.dart';
import '../../core/extensions.dart';
import '../../models/announcement_model.dart';
import '../../providers/gym_provider.dart';
import '../../providers/member_provider.dart';
import '../../widgets/error_widgets.dart';
import '../../widgets/loading_widgets.dart';

class MemberAnnouncementsScreen extends ConsumerWidget {
  const MemberAnnouncementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gym = ref.watch(selectedGymProvider);
    if (gym == null) {
      return Scaffold(
        backgroundColor: AppColors.bgDark,
        appBar: AppBar(
          backgroundColor: AppColors.bgDark,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textSecondary),
            onPressed: () => context.pop(),
          ),
          title: Text(
            'Announcements',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        body: Center(
          child: Text(
            'No gym selected',
            style: GoogleFonts.inter(color: AppColors.textMuted),
          ),
        ),
      );
    }

    final announcementsState =
        ref.watch(pagedAnnouncementsControllerProvider(gym.id));

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.bgDark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textSecondary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Announcements',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref
            .read(pagedAnnouncementsControllerProvider(gym.id).notifier)
            .refresh(),
        backgroundColor: AppColors.bgElevated,
        color: AppColors.primary,
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

            if (announcementsState.items.isEmpty && announcementsState.hasError) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.sizeOf(context).height * 0.7,
                    child: ErrorStateWidget(
                      message: 'Unable to load announcements.',
                      onRetry: () => ref
                          .read(pagedAnnouncementsControllerProvider(gym.id).notifier)
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
                        const Icon(
                          Icons.campaign_rounded,
                          size: 56,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No announcements yet',
                          style: GoogleFonts.inter(
                            color: AppColors.textSecondary,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Your gym will post updates here.',
                          style: GoogleFonts.inter(
                            color: AppColors.textMuted,
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
              separatorBuilder: (_, index) => index == announcementsState.items.length - 1
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
                        .read(pagedAnnouncementsControllerProvider(gym.id).notifier)
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
    final isPinned = announcement.isPinned;
    final color = isPinned ? AppColors.warning : AppColors.info;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPinned
              ? AppColors.warning.withValues(alpha: 0.3)
              : AppColors.border,
          width: isPinned ? 1.5 : 1,
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
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isPinned ? Icons.push_pin_rounded : Icons.campaign_rounded,
                  color: color,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              if (isPinned)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: AppColors.warning.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    'PINNED',
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: AppColors.warning,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              const Spacer(),
              Text(
                announcement.createdAt.dayMonth,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.textMuted,
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
              color: AppColors.textPrimary,
            ),
          ),
          if (announcement.body != null && announcement.body!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              announcement.body!,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    ).animate(delay: Duration(milliseconds: delay)).fadeIn().slideY(begin: 0.04);
  }
}
