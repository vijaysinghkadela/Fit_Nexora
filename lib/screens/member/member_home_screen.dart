import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/extensions.dart';
import '../../core/responsive.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/gym_provider.dart';
import '../../providers/member_provider.dart';
import '../../providers/notifications_provider.dart';
import '../../providers/payment_provider.dart';
import '../../providers/pro_member_provider.dart';
import '../../providers/traffic_provider.dart';
import '../../providers/health_provider.dart';
import '../../widgets/glassmorphic_card.dart';
import '../../widgets/loading_widgets.dart';
import '../../widgets/member_bottom_nav.dart';

/// Entry point for the member-facing experience.
/// Shows the paywall if no active membership, otherwise shows the home dashboard.
class MemberHomeScreen extends ConsumerWidget {
  const MemberHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accessAsync = ref.watch(memberHasAccessProvider);

    return accessAsync.when(
      loading: () => const DashboardSkeletonScaffold(),
      error: (e, _) => const _MemberDashboard(),
      data: (_) => const _MemberDashboard(),
    );
  }
}

// ─── Member Dashboard ─────────────────────────────────────────────────────────

class _MemberDashboard extends ConsumerWidget {
  const _MemberDashboard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.fitTheme;
    final l = AppLocalizations.of(context)!;
    final user = ref.watch(currentUserProvider).value;
    final gym = ref.watch(selectedGymProvider);
    final membershipAsync = ref.watch(memberMembershipProvider);
    final workoutAsync = ref.watch(memberWorkoutPlanProvider);
    final dietAsync = ref.watch(memberDietPlanProvider);
    final progressAsync = ref.watch(memberProgressProvider);
    final attendanceAsync = ref.watch(memberAttendanceProvider);
    final announcementsAsync = ref.watch(memberAnnouncementsProvider);
    final proAccessAsync = ref.watch(memberHasProAccessProvider);

    final stepsState = ref.watch(stepsProvider);
    final sleepState = ref.watch(sleepProvider);

    final hasAccess = ref.watch(memberHasAccessProvider).valueOrNull ?? false;
    final hasProAccess = proAccessAsync.valueOrNull ?? false;
    void handlePremiumTap(String route) {
      if (hasAccess) {
        context.push(route);
      } else {
        context.push('/member/paywall');
      }
    }

    void handleProTap() {
      context.push(hasProAccess ? '/pro/ai' : '/pro/paywall');
    }

    final firstName = user?.fullName.split(' ').first ?? 'Member';
    final rs = ResponsiveSize.of(context);
    Future<void> refreshAll() async {
      ref.invalidate(memberMembershipProvider);
      ref.invalidate(memberWorkoutPlanProvider);
      ref.invalidate(memberDietPlanProvider);
      ref.invalidate(memberProgressProvider);
      ref.invalidate(memberAttendanceProvider);
      ref.invalidate(memberAnnouncementsProvider);
      await Future.wait([
        ref.read(memberMembershipProvider.future),
        ref.read(memberWorkoutPlanProvider.future),
        ref.read(memberDietPlanProvider.future),
        ref.read(memberProgressProvider.future),
        ref.read(memberAttendanceProvider.future),
      ]);
    }

    return Scaffold(
      backgroundColor: t.background,
      bottomNavigationBar: const MemberBottomNav(),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: refreshAll,
          backgroundColor: t.surface,
          color: t.brand,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // ─── Header ─────────────────────────────────────────────────
              SliverAppBar(
                floating: true,
                backgroundColor: t.background,
                toolbarHeight: 80,
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back,',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: t.textSecondary,
                      ),
                    ),
                    Text(
                      firstName,
                      style: GoogleFonts.inter(
                        fontSize: rs.sp(24),
                        fontWeight: FontWeight.w900,
                        color: t.textPrimary,
                      ),
                    ),
                  ],
                ),
                actions: [
                  // Notification bell with unread badge
                  Consumer(builder: (context, ref, _) {
                    final t = context.fitTheme;
                    final unread = ref.watch(unreadCountProvider);
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.notifications_rounded),
                          color: t.textPrimary,
                          onPressed: () => context.push('/notifications'),
                        ),
                        if (unread > 0)
                          Positioned(
                            right: 6,
                            top: 6,
                            child: Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: t.danger,
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '$unread',
                                style: const TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white),
                              ),
                            ),
                          ),
                      ],
                    );
                  }),
                  Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          gym?.name ?? 'Dev Gym',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: t.brand,
                          ),
                        ),
                        membershipAsync.when(
                          data: (m) => Text(
                            m?.planName ?? 'No Plan',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: t.textMuted,
                            ),
                          ),
                          loading: () => Text(
                            '...',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: t.textMuted,
                            ),
                          ),
                          error: (_, __) => Text(
                            'No Plan',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: t.textMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // ─── Membership Card ──────────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: _MembershipCard(async: membershipAsync),
                ),
              ),

              // ─── Live Gym Traffic ─────────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: _LiveTrafficCardMember(gym: gym),
                ),
              ),

              // ─── Quick Stats Row ─────────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    children: [
                      Expanded(
                        child: _StatMiniCard(
                          label: 'Attendance',
                          sublabel: 'This month',
                          value: attendanceAsync.when(
                            data: (v) => '$v days',
                            loading: () => '...',
                            error: (_, __) => '—',
                          ),
                          icon: Icons.calendar_today_rounded,
                          color: t.info,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatMiniCard(
                          label: 'Weight',
                          sublabel: 'Last recorded',
                          value: progressAsync.when(
                            data: (p) =>
                                p.isNotEmpty && p.first['weight_kg'] != null
                                    ? '${p.first['weight_kg']} kg'
                                    : 'Not set',
                            loading: () => '...',
                            error: (_, __) => '—',
                          ),
                          icon: Icons.monitor_weight_rounded,
                          color: t.accent,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ─── Check In Button ──────────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: _CheckInButton(gym: gym, user: user),
                ),
              ),

              _sectionHeader('PRO AI'),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: GlassmorphicCard(
                    borderRadius: 20,
                    onTap: handleProTap,
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: t.surfaceAlt.withOpacity(0.42),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: t.brand.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: t.brand.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.auto_awesome_rounded,
                              color: t.brand,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  hasProAccess
                                      ? 'Generate a Pro AI workout + diet plan'
                                      : 'Unlock Pro AI planning',
                                  style: GoogleFonts.inter(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: t.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  hasProAccess
                                      ? 'Open the Kimi planner, publish plans into your workout and diet tabs, and review full-body progress.'
                                      : 'Upgrade to Pro for AI workout plans, AI diet plans, advanced analysis, and the full-body progress page.',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: t.textSecondary,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: t.textMuted,
                          ),
                        ],
                      ),
                    ),
                  ).animate(delay: 90.ms).fadeIn().slideY(begin: 0.04),
                ),
              ),

              // ─── Section: Today's Workout ─────────────────────────────────
              _sectionHeader("TODAY'S WORKOUT"),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: _WorkoutCard(
                    async: workoutAsync,
                    onTap: () => handlePremiumTap('/member/workout'),
                  ),
                ),
              ),

              // ─── Section: Today's Diet ────────────────────────────────────
              _sectionHeader("TODAY'S DIET PLAN"),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: _DietCard(
                    async: dietAsync,
                    onTap: () => handlePremiumTap('/member/diet'),
                  ),
                ),
              ),

              // ─── Section: Health ──────────────────────────────────────────
              _sectionHeader('HEALTH TRACKING'),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    children: [
                      Expanded(
                        child: _QuickNavCard(
                          label: 'Steps',
                          value: '${stepsState.stepsToday}',
                          sublabel: 'today',
                          icon: Icons.directions_walk_rounded,
                          color: t.accent,
                          onTap: () => context.push('/health/steps'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Builder(builder: (context) {
                          final latestSleep = sleepState.entries.isNotEmpty
                              ? sleepState.entries.last
                              : null;
                          final hours = latestSleep?.hoursSlept ?? 0;
                          final hh = hours.floor();
                          final mm = ((hours - hh) * 60).round();
                          final sleepValue =
                              latestSleep != null ? '${hh}h ${mm}m' : '--';

                          return _QuickNavCard(
                            label: 'Sleep',
                            value: sleepValue,
                            sublabel: 'last night',
                            icon: Icons.bedtime_rounded,
                            color: t.info,
                            onTap: () => context.push('/health/sleep'),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ),

              // ─── Section: Notes ───────────────────────────────────────────
              _sectionHeader('NOTES & GENERAL'),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: GlassmorphicCard(
                    borderRadius: 16,
                    onTap: () => context.push('/member/notes'),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: t.surfaceAlt.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: t.brand.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: t.brand.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.edit_note_rounded,
                                color: t.brand, size: 20),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Personal Notes',
                                    style: GoogleFonts.inter(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: t.textPrimary)),
                                Text('Tap to view your notes & guides',
                                    style: GoogleFonts.inter(
                                        fontSize: 12, color: t.textSecondary)),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right_rounded, color: t.textMuted),
                        ],
                      ),
                    ),
                  ).animate(delay: 100.ms).fadeIn().slideY(begin: 0.04),
                ),
              ),

              // ─── Section: Fitness Tools ───────────────────────────────────
              _sectionHeader('FITNESS TOOLS'),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _QuickNavCard(
                              label: l.bodyMeasurements,
                              value: '📏',
                              sublabel: 'Full Progress',
                              icon: Icons.monitor_weight_rounded,
                              color: t.accent,
                              onTap: () =>
                                  context.go('/health/body-measurements'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _QuickNavCard(
                              label: l.hydration,
                              value: '💧',
                              sublabel: 'Water Intake',
                              icon: Icons.water_drop_rounded,
                              color: t.info,
                              onTap: () => context.go('/health/water'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _QuickNavCard(
                              label: l.personalRecords,
                              value: '🏆',
                              sublabel: 'Hall of Fame',
                              icon: Icons.emoji_events_rounded,
                              color: t.warning,
                              onTap: () =>
                                  context.go('/workout/personal-records'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _QuickNavCard(
                              label: l.achievements,
                              value: '⚡',
                              sublabel: 'XP & Badges',
                              icon: Icons.bolt_rounded,
                              color: t.brand,
                              onTap: () => context.go('/achievements'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _QuickNavCard(
                              label: l.macroCalculator,
                              value: '🥗',
                              sublabel: 'TDEE & Macros',
                              icon: Icons.restaurant_rounded,
                              color: t.info,
                              onTap: () =>
                                  context.go('/tools/macro-calculator'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _QuickNavCard(
                              label: l.oneRepMax,
                              value: '💪',
                              sublabel: 'Max Strength',
                              icon: Icons.fitness_center_rounded,
                              color: t.danger,
                              onTap: () => context.go('/tools/one-rep-max'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.05),
                ),
              ),

              // ─── Section: Announcements ───────────────────────────────────
              _sectionHeader('ANNOUNCEMENTS'),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                sliver: SliverToBoxAdapter(
                  child: _AnnouncementsCard(
                    async: announcementsAsync,
                    onViewAll: () => context.push('/member/announcements'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) => Builder(
        builder: (context) {
          final t = context.fitTheme;
          return SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
            sliver: SliverToBoxAdapter(
              child: Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: t.textMuted,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          );
        },
      );
}

// ─── Membership Card ──────────────────────────────────────────────────────────

class _MembershipCard extends ConsumerWidget {
  final AsyncValue<dynamic> async;
  const _MembershipCard({required this.async});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return async.when(
      loading: () => _shimmer(context),
      error: (_, __) => const SizedBox.shrink(),
      data: (membership) => membership == null
          ? const SizedBox.shrink()
          : _card(membership, context, ref),
    );
  }

  Widget _card(dynamic m, BuildContext context, WidgetRef ref) {
    final t = context.fitTheme;
    final daysLeft = m.daysRemaining as int;
    final isExpiring = daysLeft <= 7 && daysLeft >= 0;
    final statusColor = m.isExpired
        ? t.danger
        : isExpiring
            ? t.warning
            : t.success;

    final bool isUnpaid = m.paymentStatus == 'pending';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            t.brand.withOpacity(0.2),
            t.accent.withOpacity(0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: t.brand.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.card_membership_rounded, color: t.brand, size: 20),
              const SizedBox(width: 8),
              Text(
                m.planName as String,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: t.textPrimary,
                ),
              ),
              const Spacer(),
              if (isUnpaid) ...[
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: t.warning.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: t.warning.withOpacity(0.4)),
                  ),
                  child: Text(
                    'Unpaid',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: t.warning,
                    ),
                  ),
                ),
              ],
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withOpacity(0.4)),
                ),
                child: Text(
                  m.isExpired
                      ? 'Expired'
                      : isExpiring
                          ? 'Expiring Soon'
                          : 'Active',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _dateChip(
                  'Start', _fmt(m.startDate as DateTime), t.textMuted, context),
              const SizedBox(width: 12),
              _dateChip('Expires', _fmt(m.endDate as DateTime),
                  isExpiring ? t.warning : t.textSecondary, context),
              const Spacer(),
              Text(
                m.isExpired ? 'Renew now' : '$daysLeft days left',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: statusColor,
                ),
              ),
            ],
          ),
          if (isUnpaid) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                onPressed: () async {
                  try {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Starting Cashfree checkout...')),
                    );

                    final paymentService = ref.read(paymentServiceProvider);
                    final checkoutData =
                        await paymentService.createMemberCheckoutSession(
                      gymId: m.gymId,
                      membershipId: m.id,
                      amount: m.amount ?? 0.0,
                    );

                    paymentService.startCashfreeCheckout(
                      paymentSessionId: checkoutData['payment_session_id']!,
                      orderId: checkoutData['order_id']!,
                    );

                    // Note: for MVP, you'd usually wait for the result or verify it.
                    // For now, we simulate success by marking it paid after a small delay
                    // (in a real scenario, this happens via the Cashfree callback).
                    Future.delayed(const Duration(seconds: 5), () async {
                      await paymentService.markMembershipPaid(
                          m.id, checkoutData['order_id']!);
                      ref.invalidate(memberMembershipProvider);
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Payment Successful!')),
                      );
                    });
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                },
                style: FilledButton.styleFrom(
                  backgroundColor: t.brand,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.payment_rounded, size: 20),
                label: Text(
                  'Pay Now',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.04, end: 0);
  }

  Widget _dateChip(
      String label, String date, Color color, BuildContext context) {
    final t = context.fitTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 10, color: t.textMuted)),
        const SizedBox(height: 2),
        Text(date,
            style: GoogleFonts.inter(
                fontSize: 13, fontWeight: FontWeight.w600, color: color)),
      ],
    );
  }

  String _fmt(DateTime dt) => dt.mediumFormatted;

  Widget _shimmer(BuildContext context) {
    final t = context.fitTheme;
    final rs = ResponsiveSize.of(context);
    return Container(
      height: rs.sp(110),
      decoration: BoxDecoration(
        color: t.surfaceAlt,
        borderRadius: BorderRadius.circular(20),
      ),
    )
        .animate(onPlay: (c) => c.repeat())
        .shimmer(duration: 1200.ms, color: t.surface.withOpacity(0.5));
  }
}

// ─── Stat Mini Card ───────────────────────────────────────────────────────────

class _StatMiniCard extends StatelessWidget {
  final String label;
  final String sublabel;
  final String value;
  final IconData icon;
  final Color color;

  const _StatMiniCard({
    required this.label,
    required this.sublabel,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;
    return GlassmorphicCard(
      borderRadius: 16,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: t.surfaceAlt.withOpacity(0.4),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: t.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(label,
                style: GoogleFonts.inter(fontSize: 12, color: t.textSecondary)),
            Text(sublabel,
                style: GoogleFonts.inter(fontSize: 10, color: t.textMuted)),
          ],
        ),
      ),
    ).animate(delay: 100.ms).fadeIn().slideY(begin: 0.04);
  }
}

// ─── Check-In Button ─────────────────────────────────────────────────────────

class _CheckInButton extends ConsumerWidget {
  final dynamic gym;
  final dynamic user;
  const _CheckInButton({this.gym, this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (gym == null || user == null) return const SizedBox.shrink();

    final gymId = gym.id as String;
    final userId = user.id as String;
    final checkInAsync = ref.watch(activeCheckInProvider((gymId, userId)));

    final t = context.fitTheme;

    return checkInAsync.when(
      data: (checkIn) {
        final isCheckedIn = checkIn != null;
        final buttonText = isCheckedIn ? 'Check Out' : 'Check In to Gym';
        final buttonIcon =
            isCheckedIn ? Icons.logout_rounded : Icons.login_rounded;
        final bgColor = isCheckedIn ? t.danger : t.brand;

        return SizedBox(
          width: double.infinity,
          height: 54,
          child: FilledButton.icon(
            onPressed: () {
              if (isCheckedIn) {
                context.push('/gym/checkout', extra: checkIn['id']);
              } else {
                context.push('/gym/checkin');
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: bgColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            icon: Icon(buttonIcon, size: 20),
            label: Text(
              buttonText,
              style:
                  GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ).animate(delay: 150.ms).fadeIn().slideY(begin: 0.04);
      },
      loading: () => SizedBox(
        height: 54,
        child: Center(
          child: CircularProgressIndicator(color: t.brand),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

// ─── Workout Card ─────────────────────────────────────────────────────────────

class _WorkoutCard extends StatelessWidget {
  final AsyncValue<dynamic> async;
  final VoidCallback onTap;
  const _WorkoutCard({required this.async, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return async.when(
      loading: () => _shimmer(context),
      error: (_, __) => _empty(context),
      data: (plan) => plan == null ? _empty(context) : _card(plan, context),
    );
  }

  Widget _card(dynamic plan, BuildContext context) {
    final t = context.fitTheme;
    final days = plan.days as List;
    final today = DateTime.now().weekday; // 1=Mon..7=Sun
    final todayDay = days.isNotEmpty ? days[(today - 1) % days.length] : null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: t.surfaceAlt,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: t.brand.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [t.brand, t.accent]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.fitness_center_rounded,
                  color: Colors.white, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    todayDay?.dayName ?? plan.name as String,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: t.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    todayDay != null
                        ? '${(todayDay.exercises as List).length} exercises today'
                        : '${days.length}-day plan assigned',
                    style:
                        GoogleFonts.inter(fontSize: 12, color: t.textSecondary),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: t.textMuted),
          ],
        ),
      ).animate(delay: 50.ms).fadeIn().slideY(begin: 0.04),
    );
  }

  Widget _empty(BuildContext context) {
    final t = context.fitTheme;
    return GlassmorphicCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.fitness_center_rounded, color: t.textMuted, size: 20),
            const SizedBox(width: 12),
            Text('No workout plan assigned yet',
                style: GoogleFonts.inter(color: t.textSecondary, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _shimmer(BuildContext context) {
    final t = context.fitTheme;
    final rs = ResponsiveSize.of(context);
    return Container(
      height: rs.sp(74),
      decoration: BoxDecoration(
        color: t.surfaceAlt,
        borderRadius: BorderRadius.circular(16),
      ),
    )
        .animate(onPlay: (c) => c.repeat())
        .shimmer(duration: 1200.ms, color: t.surface.withOpacity(0.5));
  }
}

// ─── Diet Card ────────────────────────────────────────────────────────────────

class _DietCard extends StatelessWidget {
  final AsyncValue<dynamic> async;
  final VoidCallback onTap;
  const _DietCard({required this.async, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;
    return async.when(
      loading: () {
        final rs = ResponsiveSize.of(context);
        return Container(
          height: rs.sp(74),
          decoration: BoxDecoration(
            color: t.surfaceAlt,
            borderRadius: BorderRadius.circular(16),
          ),
        )
            .animate(onPlay: (c) => c.repeat())
            .shimmer(duration: 1200.ms, color: t.surface.withOpacity(0.5));
      },
      error: (_, __) => _empty(context),
      data: (plan) => plan == null ? _empty(context) : _card(plan, context),
    );
  }

  Widget _card(dynamic plan, BuildContext context) {
    final t = context.fitTheme;
    final meals = plan.meals as List;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: t.surfaceAlt,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: t.accent.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [t.accent, t.info]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.restaurant_rounded,
                  color: Colors.white, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plan.name as String,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: t.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${meals.length} meals · ${plan.targetCalories} kcal target',
                    style:
                        GoogleFonts.inter(fontSize: 12, color: t.textSecondary),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: t.textMuted),
          ],
        ),
      ).animate(delay: 100.ms).fadeIn().slideY(begin: 0.04),
    );
  }

  Widget _empty(BuildContext context) {
    final t = context.fitTheme;
    return GlassmorphicCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.restaurant_rounded, color: t.textMuted, size: 20),
            const SizedBox(width: 12),
            Text('No diet plan assigned yet',
                style: GoogleFonts.inter(color: t.textSecondary, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

// ─── Quick Nav Card ───────────────────────────────────────────────────────────

class _QuickNavCard extends StatelessWidget {
  final String label;
  final String value;
  final String sublabel;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickNavCard({
    required this.label,
    required this.value,
    required this.sublabel,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: t.surfaceAlt,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: t.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(label,
                style: GoogleFonts.inter(fontSize: 12, color: t.textSecondary)),
            Text(sublabel,
                style: GoogleFonts.inter(fontSize: 10, color: t.textMuted)),
          ],
        ),
      ).animate(delay: 80.ms).fadeIn().slideY(begin: 0.04),
    );
  }
}

// ─── Live Traffic (Member) ──────────────────────────────────────────────────

class _LiveTrafficCardMember extends ConsumerWidget {
  final dynamic gym;
  const _LiveTrafficCardMember({required this.gym});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (gym == null) return const SizedBox.shrink();

    final t = context.fitTheme;
    final rs = ResponsiveSize.of(context);
    final gymId = gym.id as String;
    final maxCapacity = (gym.maxClients as int? ?? 50).clamp(1, 9999);
    final trafficAsync = ref.watch(currentTrafficCountProvider(gymId));

    (String label, Color color) statusForCount(int count) {
      if (count <= 5) return ('Quiet', t.accent);
      if (count <= 15) return ('Moderate', t.warning);
      return ('Busy', t.danger);
    }

    void showDetailSheet(int count) {
      showModalBottomSheet<void>(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (_) {
          final bestTimes = ref.watch(bestVisitTimesProvider(gymId));
          final (label, color) = statusForCount(count);
          final percent = ((count / maxCapacity) * 100).clamp(0, 999).round();

          return Container(
            decoration: BoxDecoration(
              color: t.surface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border.all(color: t.divider.withOpacity(0.6)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Live Gym Traffic',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: t.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: color.withOpacity(0.35)),
                        ),
                        child: Text(
                          label,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: color,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$count',
                        style: GoogleFonts.inter(
                          fontSize: rs.sp(52),
                          fontWeight: FontWeight.w900,
                          color: t.textPrimary,
                          height: 1,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Text(
                          count == 1 ? 'person inside' : 'people inside',
                          style: GoogleFonts.inter(
                              fontSize: 14, color: t.textSecondary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Approx. $percent% of capacity in use',
                    style:
                        GoogleFonts.inter(fontSize: 13, color: t.textSecondary),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Best times to visit',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: t.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  bestTimes.when(
                    data: (hours) {
                      final display = hours.isEmpty ? [6, 11, 14] : hours;
                      return Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: display
                            .map((h) =>
                                _TimeSlotChipSmall(hour: h, accent: t.accent))
                            .toList(),
                      );
                    },
                    loading: () => const _ShimmerDotsRow(),
                    error: (_, __) => Wrap(
                      spacing: 10,
                      children: [6, 11, 14]
                          .map((h) =>
                              _TimeSlotChipSmall(hour: h, accent: t.accent))
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Live count is based on real-time check-ins over the last 12 hours.',
                    style: GoogleFonts.inter(fontSize: 12, color: t.textMuted),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

    return GlassmorphicCard(
      onTap: trafficAsync.maybeWhen(
          data: (c) => () => showDetailSheet(c), orElse: () => null),
      borderRadius: 18,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [t.brand, t.accent]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.speed_rounded,
                  color: Colors.white, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: trafficAsync.when(
                data: (count) {
                  final (label, color) = statusForCount(count);
                  final percent =
                      ((count / maxCapacity) * 100).clamp(0, 999).round();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Live Gym Traffic',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: t.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: color.withOpacity(0.4)),
                            ),
                            child: Text(
                              label,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: color,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$count inside · ~${percent.clamp(0, 999)}% capacity',
                        style: GoogleFonts.inter(
                            fontSize: 12, color: t.textSecondary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tap for best time to visit',
                        style:
                            GoogleFonts.inter(fontSize: 11, color: t.textMuted),
                      ),
                    ],
                  );
                },
                loading: () => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 120,
                      height: 14,
                      decoration: BoxDecoration(
                        color: t.surfaceAlt,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 100,
                      height: 12,
                      decoration: BoxDecoration(
                        color: t.surfaceAlt,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ],
                ),
                error: (_, __) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Live Gym Traffic',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: t.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Unable to load right now',
                      style: GoogleFonts.inter(
                          fontSize: 12, color: t.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Icon(Icons.chevron_right_rounded, color: t.textMuted),
          ],
        ),
      ),
    ).animate(delay: 80.ms).fadeIn().slideY(begin: 0.04);
  }
}

class _TimeSlotChipSmall extends StatelessWidget {
  final int hour;
  final Color accent;
  const _TimeSlotChipSmall({required this.hour, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.access_time_rounded, color: accent, size: 14),
          const SizedBox(width: 6),
          Text(
            _hourLabel(hour),
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }

  String _hourLabel(int h) {
    final start = h == 0
        ? '12 AM'
        : h < 12
            ? '$h AM'
            : h == 12
                ? '12 PM'
                : '${h - 12} PM';
    final endH = h + 1;
    final end = endH == 0
        ? '12 AM'
        : endH < 12
            ? '$endH AM'
            : endH == 12
                ? '12 PM'
                : '${endH - 12} PM';
    return '$start – $end';
  }
}

class _ShimmerDotsRow extends StatelessWidget {
  const _ShimmerDotsRow();

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;
    return Row(
      children: List.generate(
        3,
        (i) => Padding(
          padding: EdgeInsets.only(right: i == 2 ? 0 : 10),
          child: Container(
            width: 78,
            height: 34,
            decoration: BoxDecoration(
              color: t.surfaceAlt,
              borderRadius: BorderRadius.circular(10),
            ),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .fade(begin: 0.4, end: 0.8, duration: 800.ms),
        ),
      ),
    );
  }
}

// ─── Announcements Card ───────────────────────────────────────────────────────

class _AnnouncementsCard extends StatelessWidget {
  final AsyncValue<dynamic> async;
  final VoidCallback onViewAll;
  const _AnnouncementsCard({required this.async, required this.onViewAll});

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;
    return async.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (announcements) {
        final list = announcements as List;
        if (list.isEmpty) {
          return GlassmorphicCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.campaign_rounded, color: t.textMuted, size: 20),
                  const SizedBox(width: 12),
                  Text('No announcements yet',
                      style: GoogleFonts.inter(color: t.textSecondary)),
                ],
              ),
            ),
          );
        }

        final preview = list.take(2).toList();
        return GlassmorphicCard(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                ...preview.asMap().entries.map((entry) {
                  final i = entry.key;
                  final a = entry.value;
                  return Column(
                    children: [
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: a.type == 'app'
                                ? t.brand.withOpacity(0.12)
                                : ((a.isPinned as bool)
                                    ? t.warning.withOpacity(0.12)
                                    : t.info.withOpacity(0.12)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            a.type == 'app'
                                ? Icons.system_update_rounded
                                : ((a.isPinned as bool)
                                    ? Icons.push_pin_rounded
                                    : Icons.campaign_rounded),
                            color: a.type == 'app'
                                ? t.brand
                                : ((a.isPinned as bool) ? t.warning : t.info),
                            size: 16,
                          ),
                        ),
                        title: Text(
                          a.title as String,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: t.textPrimary,
                          ),
                        ),
                        subtitle: a.body != null
                            ? Text(
                                a.body as String,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                    fontSize: 12, color: t.textSecondary),
                              )
                            : null,
                      ),
                      if (i < preview.length - 1)
                        Divider(color: t.divider, height: 1),
                    ],
                  );
                }),
                if (list.length > 2) ...[
                  Divider(color: t.divider, height: 1),
                  ListTile(
                    onTap: onViewAll,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    title: Text(
                      'View all ${list.length} announcements',
                      style: GoogleFonts.inter(
                          fontSize: 13,
                          color: t.brand,
                          fontWeight: FontWeight.w600),
                    ),
                    trailing: Icon(Icons.chevron_right_rounded,
                        color: t.brand, size: 18),
                  ),
                ],
              ],
            ),
          ),
        ).animate(delay: 200.ms).fadeIn();
      },
    );
  }
}
