import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/plan_limits.dart';
import '../../core/enums.dart';
import '../../core/extensions.dart';
import '../../config/theme.dart';
import '../../models/client_profile_model.dart';
import '../../models/membership_model.dart';
import '../../models/subscription_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/client_provider.dart';
import '../../providers/gym_provider.dart';
import '../../widgets/ai_usage_meter.dart';
import '../../widgets/fit_management_scaffold.dart';
import '../../widgets/glassmorphic_card.dart';
import '../clients/add_client_screen.dart';

final dashboardMembershipPreviewProvider =
    FutureProvider.autoDispose<List<Membership>>((ref) async {
  final gym = ref.watch(selectedGymProvider);
  if (gym == null) return [];

  final memberships =
      await ref.read(databaseServiceProvider).getMembershipsForGym(gym.id);
  memberships.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return memberships.take(4).toList();
});

const managementDestinations = [
  FitShellDestination(
    icon: Icons.dashboard_rounded,
    label: 'Dashboard',
    route: '/dashboard',
  ),
  FitShellDestination(
    icon: Icons.people_alt_rounded,
    label: 'Clients',
    route: '/clients',
  ),
  FitShellDestination(
    icon: Icons.card_membership_rounded,
    label: 'Memberships',
    route: '/memberships',
  ),
  FitShellDestination(
    icon: Icons.fitness_center_rounded,
    label: 'Workouts',
    route: '/workouts',
  ),
  FitShellDestination(
    icon: Icons.restaurant_menu_rounded,
    label: 'Diet Plans',
    route: '/diet-plans',
  ),
  FitShellDestination(
    icon: Icons.settings_rounded,
    label: 'Settings',
    route: '/settings',
  ),
];

const managementMobileDestinations = [
  FitShellDestination(
    icon: Icons.dashboard_rounded,
    label: 'Dashboard',
    route: '/dashboard',
  ),
  FitShellDestination(
    icon: Icons.people_alt_rounded,
    label: 'Clients',
    route: '/clients',
  ),
  FitShellDestination(
    icon: Icons.fitness_center_rounded,
    label: 'Workouts',
    route: '/workouts',
  ),
  FitShellDestination(
    icon: Icons.tune_rounded,
    label: 'Config',
    route: '/settings',
  ),
];

/// Gym-owner dashboard rebuilt around the stitched FitNexora management layout.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider).value;
    final userName = (currentUser?.fullName ?? '').trim().isEmpty
        ? 'FitNexora Owner'
        : currentUser!.fullName;
    final userEmail = currentUser?.email ?? '';

    return FitManagementScaffold(
      currentRoute: '/dashboard',
      destinations: managementDestinations,
      mobileDestinations: managementMobileDestinations,
      userName: userName,
      userEmail: userEmail,
      centerAction: FitShellCenterAction(
        icon: Icons.add_rounded,
        label: 'Add',
        onTap: () => _openAddClientSheet(context),
      ),
      onSignOut: () {
        ref.read(currentUserProvider.notifier).signOut().then((_) {
          if (context.mounted) {
            context.go('/login');
          }
        });
      },
      child: _DashboardBody(
        userName: userName,
        onAddClient: () => _openAddClientSheet(context),
      ),
    );
  }

  void _openAddClientSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddClientScreen(),
    );
  }
}

// ─── Body ─────────────────────────────────────────────────────────────────────

class _DashboardBody extends ConsumerWidget {
  const _DashboardBody({
    required this.userName,
    required this.onAddClient,
  });

  final String userName;
  final VoidCallback onAddClient;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.fitTheme;
    final gym = ref.watch(selectedGymProvider);
    final statsAsync = ref.watch(dashboardStatsProvider);
    final subscriptionAsync = ref.watch(currentGymSubscriptionProvider);
    final trafficAsync = ref.watch(recentGymCheckInsProvider);
    final membershipsAsync = ref.watch(dashboardMembershipPreviewProvider);
    final clientsAsync = ref.watch(gymClientsProvider);

    Future<void> refreshAll() async {
      ref.invalidate(dashboardStatsProvider);
      ref.invalidate(currentGymSubscriptionProvider);
      ref.invalidate(recentGymCheckInsProvider);
      ref.invalidate(gymClientsProvider);
      ref.invalidate(dashboardMembershipPreviewProvider);

      await Future.wait([
        ref.read(dashboardStatsProvider.future),
        ref.read(currentGymSubscriptionProvider.future),
        ref.read(recentGymCheckInsProvider.future),
        ref.read(gymClientsProvider.future),
        ref.read(dashboardMembershipPreviewProvider.future),
      ]);
    }

    // Show setup prompt if gym is still loading/not configured
    final userGymsAsync = ref.watch(userGymsProvider);

    return RefreshIndicator(
      onRefresh: refreshAll,
      color: colors.brand,
      backgroundColor: colors.surface,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // ── App bar ──────────────────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            floating: true,
            backgroundColor: colors.background.withOpacity(0.92),
            toolbarHeight: 82,
            titleSpacing: 20,
            title: _BrandHeader(
              title: 'FitNexora',
              subtitle: gym?.name ?? 'Admin Dashboard',
            ),
            actions: [
              if (!context.isMobile)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilledButton.icon(
                    onPressed: onAddClient,
                    icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                    label: const Text('Add Client'),
                  ),
                ),
              _HeaderIcon(
                icon: Icons.search_rounded,
                onTap: () => context.go('/clients'),
              ),
              const SizedBox(width: 8),
              _NotificationIcon(
                dotColor: colors.accent,
                onTap: () => context.push('/notifications'),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(right: 20),
                child: _UserBadge(name: userName),
              ),
            ],
          ),

          // ── No gym banner ────────────────────────────────────────────────
          if (gym == null && userGymsAsync.isLoading)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              sliver: SliverToBoxAdapter(
                child: _NoGymBanner(isLoading: true),
              ),
            )
          else if (gym == null && !userGymsAsync.isLoading)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              sliver: SliverToBoxAdapter(
                child: _NoGymBanner(isLoading: false),
              ),
            ),

          // ── Quick stats 2x2 grid ─────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            sliver: SliverToBoxAdapter(
              child: statsAsync.when(
                loading: () => const _StatsShimmer(),
                error: (e, _) => _StatsErrorBanner(message: e.toString()),
                data: (stats) => _StatsGrid(
                  stats: stats,
                  subscriptionAsync: subscriptionAsync,
                ),
              ),
            ),
          ),

          // ── Gym occupancy bar chart ───────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            sliver: SliverToBoxAdapter(
              child: _GymOccupancyCard(
                trafficAsync: trafficAsync,
                statsAsync: statsAsync,
              ),
            ),
          ),

          // ── AI usage meters + recent memberships ─────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            sliver: SliverToBoxAdapter(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final useRow = constraints.maxWidth >= 1024;
                  final aiCard = _AiInsightsCard(
                    subscriptionAsync: subscriptionAsync,
                    statsAsync: statsAsync,
                  );
                  final membershipsCard = _RenewalQueueCard(
                    membershipsAsync: membershipsAsync,
                    clientsAsync: clientsAsync,
                  );

                  if (!useRow) {
                    return Column(
                      children: [
                        aiCard,
                        const SizedBox(height: 20),
                        membershipsCard,
                      ],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: aiCard),
                      const SizedBox(width: 20),
                      Expanded(flex: 2, child: membershipsCard),
                    ],
                  );
                },
              ),
            ),
          ),

          // ── Quick actions ────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            sliver: SliverToBoxAdapter(
              child: _DashboardQuickActions(
                onAddClient: onAddClient,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Brand header ──────────────────────────────────────────────────────────────

class _BrandHeader extends StatelessWidget {
  const _BrandHeader({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colors = context.fitTheme;

    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            gradient: colors.brandGradient,
            borderRadius: BorderRadius.circular(14),
          ),
          alignment: Alignment.center,
          child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 22),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: colors.textPrimary,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: colors.textMuted,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Header icons ──────────────────────────────────────────────────────────────

class _HeaderIcon extends StatelessWidget {
  const _HeaderIcon({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.fitTheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: colors.glassFill,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: colors.glassBorder),
          ),
          child: Center(
            child: Icon(icon, color: colors.textSecondary, size: 20),
          ),
        ),
      ),
    );
  }
}

/// Notification icon with animated ping dot.
class _NotificationIcon extends StatefulWidget {
  const _NotificationIcon({
    required this.dotColor,
    required this.onTap,
  });

  final Color dotColor;
  final VoidCallback onTap;

  @override
  State<_NotificationIcon> createState() => _NotificationIconState();
}

class _NotificationIconState extends State<_NotificationIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ping;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ping = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _scale = Tween<double>(begin: 1.0, end: 2.2).animate(
      CurvedAnimation(parent: _ping, curve: Curves.easeOut),
    );
    _opacity = Tween<double>(begin: 0.7, end: 0.0).animate(
      CurvedAnimation(parent: _ping, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ping.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.fitTheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: colors.glassFill,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: colors.glassBorder),
          ),
          child: Stack(
            children: [
              Center(
                child:
                    Icon(Icons.notifications_rounded, color: colors.textSecondary, size: 20),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: _ping,
                      builder: (_, __) => Transform.scale(
                        scale: _scale.value,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: widget.dotColor.withOpacity(_opacity.value),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: widget.dotColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UserBadge extends StatelessWidget {
  const _UserBadge({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final colors = context.fitTheme;
    final initial = name.isEmpty ? 'F' : name[0].toUpperCase();

    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: colors.brand.withOpacity(0.26),
          width: 2,
        ),
        gradient: LinearGradient(
          colors: [colors.surfaceAlt, colors.surface],
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: colors.textPrimary,
        ),
      ),
    );
  }
}

// ─── Stats grid ────────────────────────────────────────────────────────────────

class _StatsShimmer extends StatelessWidget {
  const _StatsShimmer();

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;
    final cardLabels = ['Active Members', 'Total Clients', 'AI Queries', 'Est. Revenue'];
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: List.generate(
        4,
        (i) => SizedBox(
          width: context.isMobile
              ? (context.screenSize.width - 52) / 2
              : (context.screenSize.width -
                      (context.isDesktop ? 380 : 200)) /
                  4,
          child: Container(
            height: 112,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: t.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: t.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: t.brand.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: t.brand,
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  height: 20,
                  width: 60,
                  decoration: BoxDecoration(
                    color: t.surfaceAlt,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  cardLabels[i],
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: t.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── No gym banner ─────────────────────────────────────────────────────────────

class _NoGymBanner extends StatelessWidget {
  const _NoGymBanner({required this.isLoading});
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: t.brand.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: t.brand.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: t.brand.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: isLoading
                ? Padding(
                    padding: const EdgeInsets.all(12),
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: t.brand),
                  )
                : Icon(Icons.storefront_rounded, color: t.brand, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isLoading ? 'Loading your gym…' : 'No gym found',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: t.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isLoading
                      ? 'Setting up your dashboard'
                      : 'Create or join a gym to get started',
                  style: GoogleFonts.inter(
                      fontSize: 12, color: t.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Stats error banner ────────────────────────────────────────────────────────

class _StatsErrorBanner extends StatelessWidget {
  const _StatsErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: t.danger.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: t.danger.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.wifi_off_rounded, color: t.danger, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Could not load stats. Check your connection.',
              style: GoogleFonts.inter(fontSize: 13, color: t.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({
    required this.stats,
    required this.subscriptionAsync,
  });

  final Map<String, dynamic> stats;
  final AsyncValue<Subscription?> subscriptionAsync;

  @override
  Widget build(BuildContext context) {
    final activeMembers = stats['active_members'] as int? ?? 0;
    final subscription = subscriptionAsync.value;
    final tier = subscription?.planTier ?? PlanTier.basic;
    final haikuLimit = PlanLimits.monthlyHaikuCallLimit[tier] ?? 0;
    final haikuUsed = tier == PlanTier.basic
        ? 0
        : math.min(
            haikuLimit == -1 ? activeMembers * 3 : haikuLimit,
            math.max(0, activeMembers * 2),
          );
    final aiQueries = tier == PlanTier.basic ? 0 : haikuUsed;
    final estimatedRevenue = activeMembers * 1200;

    final cards = [
      _StatCardData(
        label: 'Active Members',
        value: '$activeMembers',
        footnote: '↑ 12%',
        footnoteColor: _FootnoteColor.success,
        icon: Icons.group_rounded,
        tone: _CardTone.brand,
      ),
      _StatCardData(
        label: 'Monthly Revenue',
        value: _formatRevenue(estimatedRevenue),
        footnote: '↑ 8%',
        footnoteColor: _FootnoteColor.success,
        icon: Icons.payments_outlined,
        tone: _CardTone.success,
      ),
      _StatCardData(
        label: 'Active Today',
        value: '${math.max(1, activeMembers ~/ 6)}',
        footnote: '↑ 3 from yesterday',
        footnoteColor: _FootnoteColor.success,
        icon: Icons.today_rounded,
        tone: _CardTone.warning,
      ),
      _StatCardData(
        label: 'AI Usage',
        value: '$aiQueries queries',
        footnote: tier == PlanTier.basic ? 'Upgrade to unlock' : '${_safePercent(haikuUsed, haikuLimit == -1 ? haikuUsed * 2 : haikuLimit)}% of limit',
        footnoteColor: _FootnoteColor.muted,
        icon: Icons.auto_awesome_rounded,
        tone: _CardTone.muted,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 860;
        final width =
            wide ? (constraints.maxWidth - 36) / 4 : (constraints.maxWidth - 12) / 2;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: cards
              .asMap()
              .entries
              .map(
                (entry) => SizedBox(
                  width: width,
                  child: _DashboardStatCard(card: entry.value)
                      .animate()
                      .fadeIn(delay: Duration(milliseconds: entry.key * 80))
                      .slideY(begin: 0.12, end: 0),
                ),
              )
              .toList(),
        );
      },
    );
  }

  static int _safePercent(int value, int total) {
    if (total == 0) return 0;
    return ((value / total) * 100).round();
  }

  static String _formatRevenue(int amount) {
    if (amount >= 100000) return '₹${(amount / 100000).toStringAsFixed(1)}L';
    if (amount >= 1000) return '₹${(amount / 1000).toStringAsFixed(1)}K';
    return '₹$amount';
  }
}

enum _CardTone { brand, success, warning, muted }
enum _FootnoteColor { success, muted }

class _StatCardData {
  const _StatCardData({
    required this.label,
    required this.value,
    required this.footnote,
    required this.footnoteColor,
    required this.tone,
    required this.icon,
  });

  final String label;
  final String value;
  final String footnote;
  final _FootnoteColor footnoteColor;
  final _CardTone tone;
  final IconData icon;
}

class _DashboardStatCard extends StatelessWidget {
  const _DashboardStatCard({required this.card});

  final _StatCardData card;

  @override
  Widget build(BuildContext context) {
    final colors = context.fitTheme;
    final accent = switch (card.tone) {
      _CardTone.brand => colors.brand,
      _CardTone.success => colors.accent,
      _CardTone.warning => colors.warning,
      _CardTone.muted => colors.textSecondary,
    };
    final noteColor = switch (card.footnoteColor) {
      _FootnoteColor.success => colors.accent,
      _FootnoteColor.muted => colors.textMuted,
    };

    return GlassmorphicCard(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(card.icon, size: 18, color: accent),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        card.label,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: colors.textMuted,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                card.value,
                style: GoogleFonts.inter(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: colors.textPrimary,
                  letterSpacing: -0.8,
                ),
              ),
            ),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                card.footnote,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: noteColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GymOccupancyCard extends StatelessWidget {
  const _GymOccupancyCard({
    required this.trafficAsync,
    required this.statsAsync,
  });

  final AsyncValue<List<Map<String, dynamic>>> trafficAsync;
  final AsyncValue<Map<String, dynamic>> statsAsync;

  @override
  Widget build(BuildContext context) {
    final colors = context.fitTheme;

    final series = trafficAsync.maybeWhen(
      data: (rows) => _TrafficSeries.fromRows(rows),
      orElse: _TrafficSeries.fallback,
    );
    final stats = statsAsync.value ?? const {};
    final liveMembers = stats['active_members'] as int? ?? 0;
    final totalMembers = stats['total_clients'] as int? ?? 0;

    return GlassmorphicCard(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title + Live badge
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Gym Occupancy',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: colors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: colors.accent.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: colors.accent.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: colors.accent,
                          shape: BoxShape.circle,
                        ),
                      )
                          .animate(onPlay: (c) => c.repeat())
                          .fadeOut(duration: 900.ms)
                          .then()
                          .fadeIn(duration: 900.ms),
                      const SizedBox(width: 6),
                      Text(
                        'Live',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: colors.accent,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Hourly member check-ins across the day',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            // fl_chart BarChart
            SizedBox(
              height: 200,
              child: _OccupancyBarChart(series: series, colors: colors),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _InfoChip(
                  label: 'Live capacity',
                  value:
                      '${math.min(totalMembers, liveMembers + series.peakEstimate)}',
                ),
                const SizedBox(width: 10),
                const _InfoChip(
                  label: 'Peak window',
                  value: '6PM-9PM',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OccupancyBarChart extends StatelessWidget {
  const _OccupancyBarChart({
    required this.series,
    required this.colors,
  });

  final _TrafficSeries series;
  final FitNexoraThemeTokens colors;

  @override
  Widget build(BuildContext context) {
    final liveValues = series.live;
    final labels = series.labels;

    final groups = <BarChartGroupData>[];
    for (var i = 0; i < liveValues.length; i++) {
      final val = liveValues[i] * 20; // scale 0-1 to 0-20
      groups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: val,
              width: 14,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  colors.brand.withOpacity(0.6),
                  colors.brand,
                ],
              ),
            ),
          ],
        ),
      );
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceEvenly,
        maxY: 22,
        minY: 0,
        barGroups: groups,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 5,
          getDrawingHorizontalLine: (_) => FlLine(
            color: colors.border.withOpacity(0.35),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= labels.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    labels[idx],
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: colors.textMuted,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '${rod.toY.round()}',
                GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.fitTheme;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: colors.surfaceAlt.withOpacity(0.76),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: colors.textMuted,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── AI insights card ──────────────────────────────────────────────────────────

class _AiInsightsCard extends StatelessWidget {
  const _AiInsightsCard({
    required this.subscriptionAsync,
    required this.statsAsync,
  });

  final AsyncValue<Subscription?> subscriptionAsync;
  final AsyncValue<Map<String, dynamic>> statsAsync;

  @override
  Widget build(BuildContext context) {
    final colors = context.fitTheme;
    final stats = statsAsync.value ?? const {};
    final activeMembers = stats['active_members'] as int? ?? 0;

    final subscription = subscriptionAsync.value;
    final tier = subscription?.planTier ?? PlanTier.basic;
    final tokenLimit = PlanLimits.monthlyAiTokenLimit[tier] ?? 0;
    final haikuLimit = PlanLimits.monthlyHaikuCallLimit[tier] ?? 0;
    final opusLimit = PlanLimits.monthlyOpusCallLimit[tier] ?? 0;
    final haikuUsed = tier == PlanTier.basic
        ? 0
        : math.min(
            haikuLimit == -1 ? activeMembers * 3 : haikuLimit,
            math.max(0, activeMembers * 2),
          );
    final opusUsed =
        tier == PlanTier.elite ? math.min(opusLimit, math.max(0, activeMembers ~/ 3)) : 0;
    final tokenUsed = tier == PlanTier.basic
        ? 0
        : math.min(tokenLimit, activeMembers * 5200);

    // Derived meter percentages (0.0–1.0)
    final workoutPlansPct = tier == PlanTier.basic
        ? 0.0
        : (haikuLimit <= 0 ? 0.73 : (haikuUsed / haikuLimit).clamp(0.0, 1.0));
    final nutritionAiPct = tier == PlanTier.basic
        ? 0.0
        : (tokenLimit <= 0 ? 0.58 : (tokenUsed / tokenLimit).clamp(0.0, 1.0));

    return Stack(
      children: [
        GlassmorphicCard(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: colors.brand.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.auto_awesome_rounded,
                        color: colors.brand,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AI Usage Meter',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: colors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Model access and generation load',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                // Workout Plans meter
                _AiMeterRow(
                  label: 'Workout Plans',
                  percent: workoutPlansPct,
                  barColor: colors.brand,
                  colors: colors,
                ),
                const SizedBox(height: 16),
                // Nutrition AI meter
                _AiMeterRow(
                  label: 'Nutrition AI',
                  percent: nutritionAiPct,
                  barColor: colors.accent,
                  colors: colors,
                ),
                const SizedBox(height: 18),
                AiUsageMeter(
                  usage: {
                    'has_ai_access': tier != PlanTier.basic,
                    'has_opus_access': tier == PlanTier.elite,
                    'opus_used': opusUsed,
                    'opus_limit': opusLimit,
                    'opus_percent':
                        opusLimit == 0 ? 0 : (opusUsed / opusLimit) * 100,
                    'haiku_used': haikuUsed,
                    'haiku_limit': haikuLimit,
                    'tokens_used': tokenUsed,
                    'token_limit': tokenLimit,
                    'token_percent':
                        tokenLimit == 0 ? 0 : (tokenUsed / tokenLimit) * 100,
                  },
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top: 14,
          right: 14,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: colors.surface.withOpacity(0.9),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: colors.border),
            ),
            child: Text(
              tier.label.toUpperCase(),
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: tier == PlanTier.basic ? colors.textSecondary : colors.brand,
                letterSpacing: 1,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AiMeterRow extends StatelessWidget {
  const _AiMeterRow({
    required this.label,
    required this.percent,
    required this.barColor,
    required this.colors,
  });

  final String label;
  final double percent;
  final Color barColor;
  final FitNexoraThemeTokens colors;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
            Text(
              '${(percent * 100).round()}%',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: barColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: percent,
            minHeight: 8,
            backgroundColor: colors.surfaceAlt,
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
          ),
        ),
      ],
    );
  }
}

// ─── Recent memberships table ───────────────────────────────────────────────────

class _RenewalQueueCard extends StatelessWidget {
  const _RenewalQueueCard({
    required this.membershipsAsync,
    required this.clientsAsync,
  });

  final AsyncValue<List<Membership>> membershipsAsync;
  final AsyncValue<List<ClientProfile>> clientsAsync;

  @override
  Widget build(BuildContext context) {
    final colors = context.fitTheme;
    final clients = {
      for (final client in clientsAsync.value ?? const <ClientProfile>[])
        client.id: client,
    };

    return GlassmorphicCard(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recent Memberships',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Plan status, renewal activity, and attention flags',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => context.go('/memberships'),
                  child: const Text('View all'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Table header
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  _TableHeader(label: 'NAME', flex: 4, colors: colors),
                  _TableHeader(label: 'PLAN', flex: 3, colors: colors),
                  _TableHeader(label: 'STATUS', flex: 2, colors: colors),
                  _TableHeader(label: 'EXPIRY', flex: 3, colors: colors),
                ],
              ),
            ),
            Divider(color: colors.divider, height: 1),
            const SizedBox(height: 8),
            membershipsAsync.when(
              loading: () => const _ListPlaceholder(),
              error: (_, __) => const _EmptyState(
                icon: Icons.workspace_premium_outlined,
                title: 'Membership preview unavailable',
                subtitle: 'We could not load the latest plan activity.',
              ),
              data: (memberships) {
                if (memberships.isEmpty) {
                  return const _EmptyState(
                    icon: Icons.workspace_premium_outlined,
                    title: 'No memberships yet',
                    subtitle:
                        'Create a membership to start tracking renewals.',
                  );
                }

                return Column(
                  children: [
                    for (var i = 0; i < memberships.length; i++) ...[
                      _MembershipTableRow(
                        membership: memberships[i],
                        client: clients[memberships[i].clientId],
                      ),
                      if (i != memberships.length - 1)
                        Divider(color: colors.divider, height: 16),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader({
    required this.label,
    required this.flex,
    required this.colors,
  });

  final String label;
  final int flex;
  final FitNexoraThemeTokens colors;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: colors.textMuted,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

class _MembershipTableRow extends StatelessWidget {
  const _MembershipTableRow({
    required this.membership,
    required this.client,
  });

  final Membership membership;
  final ClientProfile? client;

  @override
  Widget build(BuildContext context) {
    final colors = context.fitTheme;
    final name = (client?.fullName ?? 'Member').trim();
    final initials = name.isEmpty
        ? 'FN'
        : name
            .split(' ')
            .where((part) => part.isNotEmpty)
            .take(2)
            .map((part) => part[0].toUpperCase())
            .join();

    final statusLabel = membership.isExpired
        ? 'Expired'
        : membership.expiresWithin(7)
            ? 'Expiring'
            : 'Active';
    final statusColor = membership.isExpired
        ? colors.danger
        : membership.expiresWithin(7)
            ? colors.warning
            : colors.accent;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          // Name column
          Expanded(
            flex: 4,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: colors.brand.withOpacity(0.18),
                  child: Text(
                    initials,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: colors.brand,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    name,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Plan column
          Expanded(
            flex: 3,
            child: Text(
              membership.planName,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: colors.textSecondary,
              ),
            ),
          ),
          // Status column
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                statusLabel,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: statusColor,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          // Expiry column
          Expanded(
            flex: 3,
            child: Text(
              membership.isExpired
                  ? 'Ended ${membership.endDate.dayMonth}'
                  : '${membership.daysRemaining.clamp(0, 999)}d left',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: colors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Shared helpers ────────────────────────────────────────────────────────────

class _ListPlaceholder extends StatelessWidget {
  const _ListPlaceholder();

  @override
  Widget build(BuildContext context) {
    final colors = context.fitTheme;
    return Column(
      children: List.generate(
        3,
        (index) => Container(
          margin: EdgeInsets.only(bottom: index == 2 ? 0 : 12),
          height: 44,
          decoration: BoxDecoration(
            color: colors.surfaceAlt,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colors = context.fitTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: colors.surfaceAlt,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: colors.textMuted),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: colors.textSecondary,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Quick actions ──────────────────────────────────────────────────────────────

class _DashboardQuickActions extends StatelessWidget {
  const _DashboardQuickActions({required this.onAddClient});

  final VoidCallback onAddClient;

  @override
  Widget build(BuildContext context) {
    final cards = [
      _QuickActionData(
        icon: Icons.person_add_alt_1_rounded,
        label: 'Add Client',
        onTap: onAddClient,
      ),
      _QuickActionData(
        icon: Icons.notifications_active_rounded,
        label: 'Tasks',
        onTap: () => context.go('/todos'),
      ),
      _QuickActionData(
        icon: Icons.sync_alt_rounded,
        label: 'Workouts',
        onTap: () => context.go('/workouts'),
      ),
      _QuickActionData(
        icon: Icons.credit_card_rounded,
        label: 'Billing',
        onTap: () => context.go('/pricing'),
      ),
      _QuickActionData(
        icon: Icons.fitness_center_rounded,
        label: 'Equipment',
        onTap: () => context.go('/gym/equipment'),
      ),
      _QuickActionData(
        icon: Icons.qr_code_scanner_rounded,
        label: 'Check-In',
        onTap: () => context.go('/clients/checkin'),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: context.fitTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final itemWidth = (constraints.maxWidth - 12) / 2;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: cards
                  .map(
                    (card) => SizedBox(
                      width: itemWidth,
                      child: _QuickActionCard(card: card),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

class _QuickActionData {
  const _QuickActionData({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({required this.card});

  final _QuickActionData card;

  @override
  Widget build(BuildContext context) {
    final colors = context.fitTheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: card.onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
          decoration: BoxDecoration(
            color: colors.surface.withOpacity(0.88),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: colors.border),
          ),
          child: Column(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: colors.surfaceAlt,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(card.icon, color: colors.textPrimary, size: 22),
              ),
              const SizedBox(height: 12),
              Text(
                card.label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Traffic series helper ──────────────────────────────────────────────────────

class _TrafficSeries {
  const _TrafficSeries({
    required this.live,
    required this.average,
    required this.labels,
    required this.peakEstimate,
  });

  final List<double> live;
  final List<double> average;
  final List<String> labels;
  final int peakEstimate;

  factory _TrafficSeries.fromRows(List<Map<String, dynamic>> rows) {
    const anchorHours = [6, 9, 12, 15, 18, 21, 24];
    final averageBuckets = List<double>.filled(anchorHours.length, 0.0);
    final todayBuckets = List<double>.filled(anchorHours.length, 0.0);
    final now = DateTime.now();

    int bucketForHour(int hour) {
      if (hour < 8) return 0;
      if (hour < 11) return 1;
      if (hour < 14) return 2;
      if (hour < 17) return 3;
      if (hour < 20) return 4;
      if (hour < 23) return 5;
      return 6;
    }

    for (final row in rows) {
      final raw = row['checked_in_at'];
      if (raw == null) continue;
      final parsed = DateTime.tryParse(raw.toString())?.toLocal();
      if (parsed == null) continue;
      final bucket = bucketForHour(parsed.hour);
      averageBuckets[bucket] += 1;
      if (parsed.year == now.year &&
          parsed.month == now.month &&
          parsed.day == now.day) {
        todayBuckets[bucket] += 1;
      }
    }

    List<double> normalize(List<double> values) {
      final maxValue = values.fold<double>(0, math.max);
      if (maxValue <= 0) {
        return const [0.22, 0.7, 0.55, 0.36, 0.84, 0.3, 0.64];
      }

      return values
          .map(
            (value) =>
                (0.15 + ((value / maxValue) * 0.78)).clamp(0.12, 0.94),
          )
          .toList();
    }

    final live = normalize(
      todayBuckets.every((value) => value == 0) ? averageBuckets : todayBuckets,
    );
    final average = normalize(averageBuckets);

    return _TrafficSeries(
      live: live,
      average: average,
      labels: const ['6AM', '9AM', '12PM', '3PM', '6PM', '9PM', '12AM'],
      peakEstimate: averageBuckets.fold<double>(0, math.max).round(),
    );
  }

  factory _TrafficSeries.fallback() => const _TrafficSeries(
        live: [0.18, 0.74, 0.39, 0.58, 0.27, 0.88, 0.62],
        average: [0.26, 0.54, 0.42, 0.47, 0.56, 0.61, 0.44],
        labels: ['6AM', '9AM', '12PM', '3PM', '6PM', '9PM', '12AM'],
        peakEstimate: 18,
      );
}
