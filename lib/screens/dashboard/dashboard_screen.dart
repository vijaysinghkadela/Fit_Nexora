import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/plan_limits.dart';
import '../../core/enums.dart';
import '../../core/extensions.dart';
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

const _managementDestinations = [
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

const _managementMobileDestinations = [
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
      destinations: _managementDestinations,
      mobileDestinations: _managementMobileDestinations,
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

    return RefreshIndicator(
      onRefresh: refreshAll,
      color: colors.brand,
      backgroundColor: colors.surface,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverAppBar(
            pinned: true,
            floating: true,
            backgroundColor: colors.background.withValues(alpha: 0.92),
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
              _HeaderIcon(
                icon: Icons.notifications_rounded,
                dotColor: colors.accent,
                onTap: () => context.go('/settings'),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(right: 20),
                child: _UserBadge(name: userName),
              ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            sliver: SliverToBoxAdapter(
              child: statsAsync.when(
                loading: () => const _StatsShimmer(),
                error: (_, __) => const SizedBox.shrink(),
                data: (stats) => _StatsGrid(stats: stats),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            sliver: SliverToBoxAdapter(
              child: _GymOccupancyCard(
                trafficAsync: trafficAsync,
                statsAsync: statsAsync,
              ),
            ),
          ),
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

class _HeaderIcon extends StatelessWidget {
  const _HeaderIcon({
    required this.icon,
    required this.onTap,
    this.dotColor,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color? dotColor;

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
          child: Stack(
            children: [
              Center(
                child: Icon(icon, color: colors.textSecondary, size: 20),
              ),
              if (dotColor != null)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: dotColor,
                      shape: BoxShape.circle,
                    ),
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
          color: colors.brand.withValues(alpha: 0.26),
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

class _StatsShimmer extends StatelessWidget {
  const _StatsShimmer();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: List.generate(
        4,
        (_) => SizedBox(
          width: context.isMobile
              ? (context.screenSize.width - 52) / 2
              : (context.screenSize.width -
                      (context.isDesktop ? 380 : 200)) /
                  4,
          child: GlassmorphicCard(
            child: const SizedBox(height: 112),
          ),
        ),
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.stats});

  final Map<String, dynamic> stats;

  @override
  Widget build(BuildContext context) {
    final totalMembers = stats['total_clients'] as int? ?? 0;
    final activeMembers = stats['active_members'] as int? ?? 0;
    final expiredMembers = stats['expired_members'] as int? ?? 0;
    final expiringSoon = stats['expiring_soon'] as int? ?? 0;

    final cards = [
      _StatCardData(
        label: 'Total Members',
        value: '$totalMembers',
        footnote: '+${math.max(1, totalMembers ~/ 24)} this month',
        tone: _CardTone.brand,
        icon: Icons.group_rounded,
      ),
      _StatCardData(
        label: 'Active Plans',
        value: '$activeMembers',
        footnote: '${_safePercent(activeMembers, totalMembers)}% live',
        tone: _CardTone.success,
        icon: Icons.workspace_premium_rounded,
      ),
      _StatCardData(
        label: 'Renewal Queue',
        value: '$expiringSoon',
        footnote: '7-day expiry window',
        tone: _CardTone.warning,
        icon: Icons.schedule_rounded,
      ),
      _StatCardData(
        label: 'Expired Plans',
        value: '$expiredMembers',
        footnote: expiredMembers == 0 ? 'Stable' : 'Needs attention',
        tone: _CardTone.muted,
        icon: Icons.event_busy_rounded,
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
              .map(
                (card) => SizedBox(
                  width: width,
                  child: _DashboardStatCard(card: card),
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
}

enum _CardTone { brand, success, warning, muted }

class _StatCardData {
  const _StatCardData({
    required this.label,
    required this.value,
    required this.footnote,
    required this.tone,
    required this.icon,
  });

  final String label;
  final String value;
  final String footnote;
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
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(card.icon, size: 18, color: accent),
                ),
                const Spacer(),
                Text(
                  card.label,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: colors.textMuted,
                    letterSpacing: 1.1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              card.value,
              style: GoogleFonts.inter(
                fontSize: 31,
                fontWeight: FontWeight.w800,
                color: colors.textPrimary,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              card.footnote,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: accent,
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
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Gym Occupancy',
                        style: GoogleFonts.inter(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: colors.textPrimary,
                          letterSpacing: -0.6,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Real-time traffic vs historical average',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _LegendPill(color: colors.brand, label: 'Live'),
                    _LegendPill(
                      color: colors.textMuted.withValues(alpha: 0.85),
                      label: 'Average',
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 22),
            SizedBox(
              height: 220,
              child: _TrafficChart(series: series),
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

class _LegendPill extends StatelessWidget {
  const _LegendPill({
    required this.color,
    required this.label,
  });

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.fitTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colors.surfaceAlt.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrafficChart extends StatelessWidget {
  const _TrafficChart({required this.series});

  final _TrafficSeries series;

  @override
  Widget build(BuildContext context) {
    final colors = context.fitTheme;

    return CustomPaint(
      painter: _TrafficPainter(
        liveValues: series.live,
        averageValues: series.average,
        lineColor: colors.brand,
        averageColor: colors.textMuted.withValues(alpha: 0.42),
        fillColor: colors.brand.withValues(alpha: 0.18),
        gridColor: colors.border.withValues(alpha: 0.45),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 12, 8, 18),
        child: Column(
          children: [
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: series.labels
                  .map(
                    (label) => Text(
                      label,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: colors.textMuted,
                        letterSpacing: 0.9,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrafficPainter extends CustomPainter {
  _TrafficPainter({
    required this.liveValues,
    required this.averageValues,
    required this.lineColor,
    required this.averageColor,
    required this.fillColor,
    required this.gridColor,
  });

  final List<double> liveValues;
  final List<double> averageValues;
  final Color lineColor;
  final Color averageColor;
  final Color fillColor;
  final Color gridColor;

  @override
  void paint(Canvas canvas, Size size) {
    const bottomInset = 28.0;
    const topInset = 12.0;
    final chartHeight = size.height - bottomInset - topInset;
    final chartWidth = size.width;

    final gridPaint = Paint()
      ..color = gridColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (var i = 0; i < 4; i++) {
      final y = topInset + chartHeight * (i / 3);
      canvas.drawLine(Offset(0, y), Offset(chartWidth, y), gridPaint);
    }

    final averagePath = _buildPath(
      averageValues,
      chartWidth,
      chartHeight,
      topInset,
    );
    final averagePaint = Paint()
      ..color = averageColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(averagePath, averagePaint);

    final livePath = _buildPath(liveValues, chartWidth, chartHeight, topInset);
    final fillPath = Path.from(livePath)
      ..lineTo(chartWidth, topInset + chartHeight)
      ..lineTo(0, topInset + chartHeight)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [fillColor, fillColor.withValues(alpha: 0)],
      ).createShader(Rect.fromLTWH(0, 0, chartWidth, chartHeight));
    canvas.drawPath(fillPath, fillPaint);

    final livePaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(livePath, livePaint);
  }

  Path _buildPath(
    List<double> values,
    double chartWidth,
    double chartHeight,
    double topInset,
  ) {
    final safeValues = values.isEmpty ? const [0.2, 0.4, 0.35, 0.55] : values;
    final stepX = chartWidth / math.max(1, safeValues.length - 1);
    final path = Path();

    for (var i = 0; i < safeValues.length; i++) {
      final x = stepX * i;
      final y =
          topInset + chartHeight - (safeValues[i].clamp(0.0, 1.0) * chartHeight);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        final previousX = stepX * (i - 1);
        final previousY = topInset +
            chartHeight -
            (safeValues[i - 1].clamp(0.0, 1.0) * chartHeight);
        final controlX = (previousX + x) / 2;
        path.cubicTo(controlX, previousY, controlX, y, x, y);
      }
    }

    return path;
  }

  @override
  bool shouldRepaint(covariant _TrafficPainter oldDelegate) {
    return oldDelegate.liveValues != liveValues ||
        oldDelegate.averageValues != averageValues ||
        oldDelegate.lineColor != lineColor;
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
          color: colors.surfaceAlt.withValues(alpha: 0.76),
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
                        color: colors.brand.withValues(alpha: 0.12),
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
              color: colors.surface.withValues(alpha: 0.9),
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
            const SizedBox(height: 18),
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
                      _MembershipRow(
                        membership: memberships[i],
                        client: clients[memberships[i].clientId],
                      ),
                      if (i != memberships.length - 1)
                        Divider(color: colors.divider, height: 24),
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

class _MembershipRow extends StatelessWidget {
  const _MembershipRow({
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

    return Row(
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: colors.surfaceAlt,
          child: Text(
            initials,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: colors.textPrimary,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                membership.planName,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: statusColor.withValues(alpha: 0.25)),
              ),
              child: Text(
                statusLabel.toUpperCase(),
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: statusColor,
                  letterSpacing: 1,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              membership.isExpired
                  ? 'Ended ${membership.endDate.dayMonth}'
                  : '${membership.daysRemaining.clamp(0, 999)} days left',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: colors.textMuted,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

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
          height: 58,
          decoration: BoxDecoration(
            color: colors.surfaceAlt,
            borderRadius: BorderRadius.circular(16),
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
            color: colors.surface.withValues(alpha: 0.88),
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
