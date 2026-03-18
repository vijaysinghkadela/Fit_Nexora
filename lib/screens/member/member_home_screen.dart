import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/dev_bypass.dart';
import '../../core/extensions.dart';
import '../../core/responsive.dart';
import '../../providers/auth_provider.dart';
import '../../providers/gym_provider.dart';
import '../../providers/member_provider.dart';
import '../../providers/notifications_provider.dart';
import '../../widgets/glassmorphic_card.dart';
import '../../widgets/loading_widgets.dart';
import '../../widgets/member_bottom_nav.dart';
import 'member_paywall_screen.dart';


/// Entry point for the member-facing experience.
/// Shows the paywall if no active membership, otherwise shows the home dashboard.
class MemberHomeScreen extends ConsumerWidget {
  const MemberHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accessAsync = ref.watch(memberHasAccessProvider);

    return accessAsync.when(
      loading: () => const DashboardSkeletonScaffold(),
      error: (e, _) => const MemberPaywallScreen(),
      data: (hasAccess) {
        if (!hasAccess) return const MemberPaywallScreen();
        return const _MemberDashboard();
      },
    );
  }
}

// ─── Member Dashboard ─────────────────────────────────────────────────────────

class _MemberDashboard extends ConsumerWidget {
  const _MemberDashboard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.fitTheme;
    final user = ref.watch(currentUserProvider).value;
    final gym = ref.watch(selectedGymProvider);
    final membershipAsync = ref.watch(memberMembershipProvider);
    final workoutAsync = ref.watch(memberWorkoutPlanProvider);
    final dietAsync = ref.watch(memberDietPlanProvider);
    final progressAsync = ref.watch(memberProgressProvider);
    final attendanceAsync = ref.watch(memberAttendanceProvider);
    final announcementsAsync = ref.watch(memberAnnouncementsProvider);

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
                        data: (p) => p.isNotEmpty &&
                                p.first['weight_kg'] != null
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

          // ─── Section: Today's Workout ─────────────────────────────────
          _sectionHeader("TODAY'S WORKOUT"),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
            sliver: SliverToBoxAdapter(
              child: _WorkoutCard(
                async: workoutAsync,
                onTap: () => context.push('/member/workout'),
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
                onTap: () => context.push('/member/diet'),
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
                      value: '8,420',
                      sublabel: 'today',
                      icon: Icons.directions_walk_rounded,
                      color: t.accent,
                      onTap: () => context.push('/health/steps'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _QuickNavCard(
                      label: 'Sleep',
                      value: '7h 23m',
                      sublabel: 'last night',
                      icon: Icons.bedtime_rounded,
                      color: t.info,
                      onTap: () => context.push('/health/sleep'),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ─── Section: Notes ───────────────────────────────────────────
          _sectionHeader('NOTES & JOURNAL'),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
            sliver: SliverToBoxAdapter(
              child: GestureDetector(
                onTap: () => context.push('/notes'),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: t.surfaceAlt,
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
                            Text('Notes & Journal',
                                style: GoogleFonts.inter(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: t.textPrimary)),
                            Text('Tap to view your notes',
                                style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: t.textSecondary)),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded,
                          color: t.textMuted),
                    ],
                  ),
                ).animate(delay: 100.ms).fadeIn().slideY(begin: 0.04),
              ),
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
                          label: 'Body Stats',
                          value: '📏',
                          sublabel: 'Measurements',
                          icon: Icons.monitor_weight_rounded,
                          color: const Color(0xFF10D88A),
                          onTap: () => context.push('/health/body-measurements'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _QuickNavCard(
                          label: 'Hydration',
                          value: '💧',
                          sublabel: 'Water Intake',
                          icon: Icons.water_drop_rounded,
                          color: const Color(0xFF38BDF8),
                          onTap: () => context.push('/health/water'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _QuickNavCard(
                          label: 'My PRs',
                          value: '🏆',
                          sublabel: 'Personal Records',
                          icon: Icons.emoji_events_rounded,
                          color: const Color(0xFFF6B546),
                          onTap: () => context.push('/workout/personal-records'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _QuickNavCard(
                          label: 'Achievements',
                          value: '⚡',
                          sublabel: 'XP & Badges',
                          icon: Icons.bolt_rounded,
                          color: t.brand,
                          onTap: () => context.push('/achievements'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _QuickNavCard(
                          label: 'Macros',
                          value: '🥗',
                          sublabel: 'TDEE Calculator',
                          icon: Icons.restaurant_rounded,
                          color: const Color(0xFF7A8BFF),
                          onTap: () => context.push('/tools/macro-calculator'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _QuickNavCard(
                          label: '1RM Calc',
                          value: '💪',
                          sublabel: 'Max Strength',
                          icon: Icons.fitness_center_rounded,
                          color: const Color(0xFFFF6B7D),
                          onTap: () => context.push('/tools/one-rep-max'),
                        ),
                      ),
                    ],
                  ),
                ],
              ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.05),
            ),
          ),

          // ─── Section: Gym Access ─────────────────────────────────────
          _sectionHeader('GYM ACCESS'),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  Expanded(
                    child: _QuickNavCard(
                      label: 'QR Check-In',
                      value: '📲',
                      sublabel: 'Scan & Enter',
                      icon: Icons.qr_code_scanner_rounded,
                      color: const Color(0xFF895AF6),
                      onTap: () => context.push('/gym/checkin'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _QuickNavCard(
                      label: 'Equipment',
                      value: '🏋️',
                      sublabel: 'Availability',
                      icon: Icons.fitness_center_rounded,
                      color: const Color(0xFF10D88A),
                      onTap: () => context.push('/gym/equipment'),
                    ),
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

class _MembershipCard extends StatelessWidget {
  final AsyncValue<dynamic> async;
  const _MembershipCard({required this.async});

  @override
  Widget build(BuildContext context) {
    return async.when(
      loading: () => _shimmer(context),
      error: (_, __) => _noMembership(context),
      data: (membership) =>
          membership == null ? _noMembership(context) : _card(membership, context),
    );

  }

  Widget _card(dynamic m, BuildContext context) {
    final t = context.fitTheme;
    final daysLeft = m.daysRemaining as int;
    final isExpiring = daysLeft <= 7 && daysLeft >= 0;
    final statusColor = m.isExpired
        ? t.danger
        : isExpiring
            ? t.warning
            : t.success;

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
        border:
            Border.all(color: t.brand.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.card_membership_rounded,
                  color: t.brand, size: 20),
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
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: statusColor.withOpacity(0.4)),
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
              _dateChip('Start',
                  _fmt(m.startDate as DateTime), t.textMuted, context),
              const SizedBox(width: 12),
              _dateChip(
                  'Expires',
                  _fmt(m.endDate as DateTime),
                  isExpiring ? t.warning : t.textSecondary,
                  context),
              const Spacer(),
              Text(
                m.isExpired
                    ? 'Renew now'
                    : '$daysLeft days left',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: statusColor,
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.04, end: 0);
  }

  Widget _dateChip(String label, String date, Color color, BuildContext context) {
    final t = context.fitTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.inter(
                fontSize: 10, color: t.textMuted)),
        const SizedBox(height: 2),
        Text(date,
            style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color)),
      ],
    );
  }

  String _fmt(DateTime dt) => dt.mediumFormatted;

  Widget _noMembership(BuildContext context) {
    final t = context.fitTheme;
    return GlassmorphicCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.card_membership_rounded,
                color: t.textMuted),
            const SizedBox(width: 12),
            Text(
              'No active membership found',
              style: GoogleFonts.inter(
                  color: t.textSecondary, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _shimmer(BuildContext context) {
    final t = context.fitTheme;
    final rs = ResponsiveSize.of(context);
    return Container(
      height: rs.sp(110),
      decoration: BoxDecoration(
        color: t.surfaceAlt,
        borderRadius: BorderRadius.circular(20),
      ),
    ).animate(onPlay: (c) => c.repeat()).shimmer(
        duration: 1200.ms,
        color: t.surface.withOpacity(0.5));
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
    return Container(
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
              style: GoogleFonts.inter(
                  fontSize: 12, color: t.textSecondary)),
          Text(sublabel,
              style:
                  GoogleFonts.inter(fontSize: 10, color: t.textMuted)),
        ],
      ),
    ).animate(delay: 100.ms).fadeIn().slideY(begin: 0.04);
  }
}

// ─── Check-In Button ─────────────────────────────────────────────────────────

class _CheckInButton extends ConsumerStatefulWidget {
  final dynamic gym;
  final dynamic user;
  const _CheckInButton({this.gym, this.user});

  @override
  ConsumerState<_CheckInButton> createState() => _CheckInButtonState();
}

class _CheckInButtonState extends ConsumerState<_CheckInButton> {
  bool _loading = false;
  bool _checkedIn = false;

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: FilledButton.icon(
        onPressed: _loading || _checkedIn ? null : _doCheckIn,
        style: FilledButton.styleFrom(
          backgroundColor:
              _checkedIn ? t.success : t.brand,
          foregroundColor: Colors.white,
          disabledBackgroundColor: _checkedIn
              ? t.success.withOpacity(0.6)
              : t.brand.withOpacity(0.4),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
        ),
        icon: _loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2),
              )
            : Icon(
                _checkedIn ? Icons.check_circle_rounded : Icons.login_rounded,
                size: 20),
        label: Text(
          _checkedIn ? 'Checked In ✓' : 'Check In to Gym',
          style:
              GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
    ).animate(delay: 150.ms).fadeIn().slideY(begin: 0.04);
  }

  Future<void> _doCheckIn() async {
    if (widget.user == null) return;
    setState(() => _loading = true);
    try {
      // Developer Bypass: Simulate successful check-in
      if (isDevUser(widget.user?.email as String?)) {
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) setState(() => _checkedIn = true);
        return;
      }

      if (widget.gym == null) return;
      final db = ref.read(databaseServiceProvider);
      await db.memberCheckIn(
        gymId: widget.gym.id as String,
        userId: widget.user.id as String,
      );
      ref.invalidate(memberAttendanceProvider);
      if (mounted) setState(() => _checkedIn = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Check-in failed: $e'),
            backgroundColor: context.fitTheme.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
    final todayDay =
        days.isNotEmpty ? days[(today - 1) % days.length] : null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: t.surfaceAlt,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: t.brand.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: [t.brand, t.accent]),
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
                    style: GoogleFonts.inter(
                        fontSize: 12, color: t.textSecondary),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: t.textMuted),
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
            Icon(Icons.fitness_center_rounded,
                color: t.textMuted, size: 20),
            const SizedBox(width: 12),
            Text('No workout plan assigned yet',
                style: GoogleFonts.inter(
                    color: t.textSecondary, fontSize: 14)),
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
    ).animate(onPlay: (c) => c.repeat()).shimmer(
        duration: 1200.ms,
        color: t.surface.withOpacity(0.5));
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
        ).animate(onPlay: (c) => c.repeat()).shimmer(
            duration: 1200.ms,
            color: t.surface.withOpacity(0.5));
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
          border: Border.all(
              color: t.accent.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: [t.accent, t.info]),
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
                    style: GoogleFonts.inter(
                        fontSize: 12, color: t.textSecondary),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: t.textMuted),
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
            Icon(Icons.restaurant_rounded,
                color: t.textMuted, size: 20),
            const SizedBox(width: 12),
            Text('No diet plan assigned yet',
                style: GoogleFonts.inter(
                    color: t.textSecondary, fontSize: 14)),
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
                style: GoogleFonts.inter(
                    fontSize: 12, color: t.textSecondary)),
            Text(sublabel,
                style: GoogleFonts.inter(
                    fontSize: 10, color: t.textMuted)),
          ],
        ),
      ).animate(delay: 80.ms).fadeIn().slideY(begin: 0.04),
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
                  Icon(Icons.campaign_rounded,
                      color: t.textMuted, size: 20),
                  const SizedBox(width: 12),
                  Text('No announcements yet',
                      style: GoogleFonts.inter(
                          color: t.textSecondary)),
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
                            color: (a.isPinned as bool)
                                ? t.warning.withOpacity(0.12)
                                : t.info.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            (a.isPinned as bool)
                                ? Icons.push_pin_rounded
                                : Icons.campaign_rounded,
                            color: (a.isPinned as bool)
                                ? t.warning
                                : t.info,
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
                                    fontSize: 12,
                                    color: t.textSecondary),
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
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12),
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
