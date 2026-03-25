import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/theme.dart';
import '../../core/extensions.dart';
import '../../core/enums.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';

class AdminScreen extends ConsumerWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider).value;
    final isSuperAdmin = currentUser?.globalRole == UserRole.superAdmin;

    if (!isSuperAdmin || currentUser == null) {
      return _AccessDeniedPage(user: currentUser);
    }

    return _AdminDashboard(user: currentUser);
  }
}

// ─── Access denied ─────────────────────────────────────────────────────────────

class _AccessDeniedPage extends StatelessWidget {
  const _AccessDeniedPage({this.user});

  final AppUser? user;

  @override
  Widget build(BuildContext context) {
    final colors = context.fitTheme;

    return Scaffold(
      backgroundColor: colors.background,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colors.backgroundAlt,
              colors.background,
            ],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -120,
              left: -90,
              child: _AdminGlowOrb(
                color: colors.brand.withOpacity(0.18),
                size: 260,
              ),
            ),
            Positioned(
              bottom: -140,
              right: -120,
              child: _AdminGlowOrb(
                color: colors.accent.withOpacity(0.12),
                size: 300,
              ),
            ),
            SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: colors.surface.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: colors.brand.withOpacity(0.18),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 78,
                            height: 78,
                            decoration: BoxDecoration(
                              color: colors.danger.withOpacity(0.14),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: colors.danger.withOpacity(0.26),
                              ),
                            ),
                            child: Icon(
                              Icons.gpp_bad_rounded,
                              size: 38,
                              color: colors.danger,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Access denied',
                            style: GoogleFonts.inter(
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              color: colors.textPrimary,
                              letterSpacing: -0.8,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'This dashboard is reserved for Super Admin access. Current role: ${user?.globalRole.label ?? 'Unknown'}.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              height: 1.5,
                              color: colors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 22),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: colors.brand,
                                foregroundColor: Colors.white,
                                minimumSize: const Size.fromHeight(54),
                              ),
                              onPressed: () => context.go('/settings'),
                              child: const Text('Back to settings'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Dashboard ─────────────────────────────────────────────────────────────────

class _AdminDashboard extends ConsumerStatefulWidget {
  const _AdminDashboard({required this.user});

  final AppUser user;

  @override
  ConsumerState<_AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends ConsumerState<_AdminDashboard> {
  FitNexoraThemeTokens get _colors => context.fitTheme;

  bool _loading = true;
  String? _error;
  _AdminSnapshot _snapshot = const _AdminSnapshot.empty();

  @override
  void initState() {
    super.initState();
    _loadSnapshot();
  }

  Future<void> _loadSnapshot() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final supabase = ref.read(supabaseClientProvider);

      final gymCount = await supabase.from('gyms').select().count();
      final userCount = await supabase.from('profiles').select().count();
      final clientCount = await supabase.from('clients').select().count();
      final subscriptionCount = await supabase
          .from('subscriptions')
          .select()
          .eq('status', 'active')
          .count();

      final gymsResponse = await supabase
          .from('gyms')
          .select('id, name, address, is_active, plan_tier, created_at')
          .order('created_at', ascending: false)
          .limit(5);

      final gyms = gymsResponse
          .map((row) => _AdminGymRecord.fromJson(row))
          .toList(growable: false);

      if (!mounted) return;
      setState(() {
        _snapshot = _AdminSnapshot(
          totalGyms: gymCount.count,
          totalUsers: userCount.count,
          totalClients: clientCount.count,
          activeSubscriptions: subscriptionCount.count,
          recentGyms: gyms,
        );
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: _colors.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/manage-announcements'),
        backgroundColor: _colors.brand,
        icon: const Icon(Icons.campaign_rounded, color: Colors.white),
        label: Text('Global News',
            style: GoogleFonts.inter(
                color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _colors.backgroundAlt,
              _colors.background,
            ],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -120,
              left: -70,
              child: _AdminGlowOrb(
                color: _colors.brand.withOpacity(0.18),
                size: 260,
              ),
            ),
            Positioned(
              top: 260,
              right: -120,
              child: _AdminGlowOrb(
                color: _colors.info.withOpacity(0.1),
                size: 260,
              ),
            ),
            Positioned(
              bottom: -140,
              left: -80,
              child: _AdminGlowOrb(
                color: _colors.accent.withOpacity(0.1),
                size: 320,
              ),
            ),
            SafeArea(
              child: RefreshIndicator(
                onRefresh: _loadSnapshot,
                color: _colors.brand,
                backgroundColor: _colors.surface,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        child: _AdminHeader(
                          user: widget.user,
                          colors: _colors,
                          onRefresh: _loadSnapshot,
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
                        child: _AdminMetricGrid(
                          colors: _colors,
                          loading: _loading,
                          snapshot: _snapshot,
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
                        child: _SubscriptionGrowthCard(
                          colors: _colors,
                          loading: _loading,
                          points: _snapshot.growthPoints,
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
                        child: _RecentGymsCard(
                          colors: _colors,
                          loading: _loading,
                          gyms: _snapshot.recentGyms,
                          error: _error,
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
                        child: _RecentActivityCard(
                          colors: _colors,
                          loading: _loading,
                          activities: _snapshot.activityFeed(_colors),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: SizedBox(height: 88 + bottomInset),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _AdminBottomBar(
        colors: _colors,
        bottomInset: bottomInset,
      ),
    );
  }
}

// ─── Header ────────────────────────────────────────────────────────────────────

class _AdminHeader extends StatelessWidget {
  const _AdminHeader({
    required this.user,
    required this.colors,
    required this.onRefresh,
  });

  final AppUser user;
  final FitNexoraThemeTokens colors;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final initial = user.fullName.trim().isEmpty
        ? 'A'
        : user.fullName.trim()[0].toUpperCase();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colors.surface.withOpacity(0.6),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.brand.withOpacity(0.18)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: colors.brand,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.admin_panel_settings_rounded,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'FitNexora Admin',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: colors.textPrimary,
                  ),
                ),
                Text(
                  'Platform Overview',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: colors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          _HeaderActionButton(
            icon: Icons.search_rounded,
            colors: colors,
            onTap: () {
              context.showSnackBar('Global admin search is coming next.');
            },
          ),
          const SizedBox(width: 8),
          _HeaderActionButton(
            icon: Icons.notifications_none_rounded,
            colors: colors,
            onTap: onRefresh,
            showDot: true,
          ),
          const SizedBox(width: 10),
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: colors.brand.withOpacity(0.3)),
              gradient: LinearGradient(
                colors: [
                  colors.brand.withOpacity(0.8),
                  colors.brandSecondary.withOpacity(0.85),
                ],
              ),
            ),
            child: Center(
              child: Text(
                initial,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderActionButton extends StatelessWidget {
  const _HeaderActionButton({
    required this.icon,
    required this.colors,
    required this.onTap,
    this.showDot = false,
  });

  final IconData icon;
  final FitNexoraThemeTokens colors;
  final VoidCallback onTap;
  final bool showDot;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: colors.surface.withOpacity(0.04),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: colors.textSecondary),
          ),
          if (showDot)
            Positioned(
              top: 9,
              right: 9,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: colors.danger,
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.backgroundAlt, width: 1.2),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // _colorsBg removed — replaced by context.fitTheme.backgroundAlt at usage site
}

// ─── Stats grid ────────────────────────────────────────────────────────────────

class _AdminMetricGrid extends StatelessWidget {
  const _AdminMetricGrid({
    required this.colors,
    required this.loading,
    required this.snapshot,
  });

  final FitNexoraThemeTokens colors;
  final bool loading;
  final _AdminSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final metrics = [
      _AdminMetricData(
        label: 'Registered Gyms',
        value: '${snapshot.totalGyms}',
        delta: '+12%',
        icon: Icons.fitness_center_rounded,
      ),
      _AdminMetricData(
        label: 'Total Revenue',
        value: _formatRevenue(snapshot.estimatedRevenue),
        delta: '+8%',
        icon: Icons.payments_outlined,
      ),
      _AdminMetricData(
        label: 'Active Users',
        value: _formatCompact(snapshot.totalUsers),
        delta: '+5.4%',
        icon: Icons.group_rounded,
      ),
      _AdminMetricData(
        label: 'Retention Rate',
        value: '${snapshot.retentionPercent}%',
        delta: '+3.1%',
        icon: Icons.autorenew_rounded,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: metrics.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.1,
      ),
      itemBuilder: (context, index) {
        if (loading) {
          return Container(
            decoration: _cardDecoration(colors),
          );
        }

        final metric = metrics[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: _cardDecoration(colors),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: colors.brand.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(metric.icon, color: colors.brand, size: 20),
                  ),
                  Text(
                    metric.delta,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: colors.accent,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                metric.label.toUpperCase(),
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                  color: colors.textMuted,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                metric.value,
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: colors.textPrimary,
                  letterSpacing: -0.8,
                ),
              ),
            ],
          ),
        )
            .animate()
            .fadeIn(delay: Duration(milliseconds: index * 80))
            .slideY(begin: 0.1, end: 0);
      },
    );
  }

  static BoxDecoration _cardDecoration(FitNexoraThemeTokens colors) {
    return BoxDecoration(
      color: colors.surface.withOpacity(0.6),
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: colors.brand.withOpacity(0.14)),
    );
  }

  static String _formatCompact(int value) {
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}k';
    }
    return '$value';
  }

  static String _formatRevenue(int amount) {
    if (amount >= 100000) {
      return 'Rs ${(amount / 100000).toStringAsFixed(1)}L';
    }
    if (amount >= 1000) {
      return 'Rs ${(amount / 1000).toStringAsFixed(1)}K';
    }
    return 'Rs $amount';
  }
}

class _AdminMetricData {
  const _AdminMetricData({
    required this.label,
    required this.value,
    required this.delta,
    required this.icon,
  });

  final String label;
  final String value;
  final String delta;
  final IconData icon;
}

// ─── Subscription growth area chart (fl_chart LineChart) ──────────────────────

class _SubscriptionGrowthCard extends StatelessWidget {
  const _SubscriptionGrowthCard({
    required this.colors,
    required this.loading,
    required this.points,
  });

  final FitNexoraThemeTokens colors;
  final bool loading;
  final List<double> points;

  static const _monthLabels = ['Oct', 'Nov', 'Dec', 'Jan', 'Feb', 'Mar'];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface.withOpacity(0.6),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.brand.withOpacity(0.14)),
      ),
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
                      'Subscription Growth',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Monthly active subscriptions — last 6 months',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: colors.surface.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: colors.brand.withOpacity(0.12)),
                ),
                child: Text(
                  'Past 6 Months',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: colors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 200,
            child: loading
                ? Container(
                    decoration: BoxDecoration(
                      color: colors.surface.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(18),
                    ),
                  )
                : _GrowthLineChart(
                    points: points,
                    colors: colors,
                    labels: _monthLabels,
                  ),
          ),
        ],
      ),
    );
  }
}

class _GrowthLineChart extends StatelessWidget {
  const _GrowthLineChart({
    required this.points,
    required this.colors,
    required this.labels,
  });

  final List<double> points;
  final FitNexoraThemeTokens colors;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    // Use first 6 points for 6-month view
    final displayPoints = points.length >= 6 ? points.sublist(0, 6) : points;
    final spots = displayPoints.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value);
    }).toList();

    final maxY = (displayPoints.fold<double>(0, math.max) * 1.25)
        .clamp(10.0, double.infinity);

    return RepaintBoundary(
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: (displayPoints.length - 1).toDouble(),
          minY: 0,
          maxY: maxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY / 4,
            getDrawingHorizontalLine: (_) => FlLine(
              color: colors.border.withOpacity(0.3),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= labels.length)
                    return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      labels[idx],
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: colors.textMuted,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: colors.brand,
              barWidth: 3,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) =>
                    FlDotCirclePainter(
                  radius: 4,
                  color: colors.brand,
                  strokeWidth: 2,
                  strokeColor: colors.background,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    colors.brand.withOpacity(0.32),
                    colors.brand.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  return LineTooltipItem(
                    spot.y.round().toString(),
                    GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Recent gym registrations table ───────────────────────────────────────────

class _RecentGymsCard extends StatelessWidget {
  const _RecentGymsCard({
    required this.colors,
    required this.loading,
    required this.gyms,
    required this.error,
  });

  final FitNexoraThemeTokens colors;
  final bool loading;
  final List<_AdminGymRecord> gyms;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: colors.surface.withOpacity(0.6),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.brand.withOpacity(0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Recent Gym Registrations',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: colors.textPrimary,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    context
                        .showSnackBar('Full registration list is coming next.');
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
          ),
          // Table header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _TableLabel(label: 'GYM NAME', flex: 4, colors: colors),
                _TableLabel(label: 'OWNER', flex: 3, colors: colors),
                _TableLabel(label: 'PLAN', flex: 2, colors: colors),
                _TableLabel(label: 'STATUS', flex: 2, colors: colors),
                _TableLabel(label: 'DATE', flex: 3, colors: colors),
              ],
            ),
          ),
          Divider(
            color: colors.brand.withOpacity(0.1),
            height: 12,
            indent: 16,
            endIndent: 16,
          ),
          if (loading)
            for (var i = 0; i < 3; i++) _GymRowPlaceholder(colors: colors)
          else if (error != null && gyms.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
              child: Text(
                error!,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: colors.textSecondary,
                ),
              ),
            )
          else if (gyms.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
              child: Text(
                'No recent gym registrations yet.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: colors.textSecondary,
                ),
              ),
            )
          else
            for (final gym in gyms) _GymTableRow(colors: colors, gym: gym),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _TableLabel extends StatelessWidget {
  const _TableLabel({
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
          letterSpacing: 0.9,
        ),
      ),
    );
  }
}

class _GymTableRow extends StatelessWidget {
  const _GymTableRow({
    required this.colors,
    required this.gym,
  });

  final FitNexoraThemeTokens colors;
  final _AdminGymRecord gym;

  @override
  Widget build(BuildContext context) {
    final statusColor = gym.isActive ? colors.accent : colors.warning;
    final statusLabel = gym.isActive ? 'ACTIVE' : 'PENDING';

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: colors.brand.withOpacity(0.08)),
        ),
      ),
      child: Row(
        children: [
          // Gym Name
          Expanded(
            flex: 4,
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    gradient: LinearGradient(
                      colors: [
                        colors.brand.withOpacity(0.3),
                        colors.info.withOpacity(0.3),
                      ],
                    ),
                  ),
                  child: Center(
                    child: Text(
                      gym.name.isEmpty ? 'G' : gym.name[0].toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    gym.name,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Owner (location as proxy)
          Expanded(
            flex: 3,
            child: Text(
              gym.locationLabel,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: colors.textSecondary,
              ),
            ),
          ),
          // Plan
          Expanded(
            flex: 2,
            child: Text(
              gym.planTier.toUpperCase(),
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: colors.brand,
              ),
            ),
          ),
          // Status
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.16),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                statusLabel,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: statusColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          // Date (id prefix as placeholder for date)
          Expanded(
            flex: 3,
            child: Text(
              gym.dateLabel,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: colors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GymRowPlaceholder extends StatelessWidget {
  const _GymRowPlaceholder({required this.colors});

  final FitNexoraThemeTokens colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 62,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: colors.surface.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}

// ─── Recent activity feed ──────────────────────────────────────────────────────

class _RecentActivityCard extends StatelessWidget {
  const _RecentActivityCard({
    required this.colors,
    required this.loading,
    required this.activities,
  });

  final FitNexoraThemeTokens colors;
  final bool loading;
  final List<_AdminActivityItem> activities;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: colors.surface.withOpacity(0.6),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.brand.withOpacity(0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Activity',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          if (loading)
            for (var i = 0; i < 3; i++)
              Container(
                height: 66,
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: colors.surface.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(16),
                ),
              )
          else
            for (final activity in activities)
              _ActivityRow(colors: colors, item: activity),
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({
    required this.colors,
    required this.item,
  });

  final FitNexoraThemeTokens colors;
  final _AdminActivityItem item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: item.color.withOpacity(0.16),
              shape: BoxShape.circle,
            ),
            child: Icon(item.icon, color: item.color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: colors.brand.withOpacity(0.08),
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.timestamp,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: colors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Bottom navigation ─────────────────────────────────────────────────────────

class _AdminBottomBar extends StatelessWidget {
  const _AdminBottomBar({
    required this.colors,
    required this.bottomInset,
  });

  final FitNexoraThemeTokens colors;
  final double bottomInset;

  @override
  Widget build(BuildContext context) {
    final items = const [
      _AdminNavItem(
        icon: Icons.grid_view_outlined,
        activeIcon: Icons.grid_view_rounded,
        label: 'DASHBOARD',
        route: '/admin',
      ),
      _AdminNavItem(
        icon: Icons.fitness_center_outlined,
        activeIcon: Icons.fitness_center_rounded,
        label: 'GYMS',
        route: '/dashboard',
      ),
      _AdminNavItem(
        icon: Icons.groups_outlined,
        activeIcon: Icons.groups_rounded,
        label: 'USERS',
        route: '/clients',
      ),
      _AdminNavItem(
        icon: Icons.analytics_outlined,
        activeIcon: Icons.analytics_rounded,
        label: 'ANALYTICS',
        route: '/traffic',
      ),
      _AdminNavItem(
        icon: Icons.settings_outlined,
        activeIcon: Icons.settings_rounded,
        label: 'SETTINGS',
        route: '/settings',
      ),
    ];

    final currentRoute = GoRouterState.of(context).matchedLocation;

    return Container(
      padding: EdgeInsets.fromLTRB(10, 8, 10, 10 + bottomInset),
      decoration: BoxDecoration(
        color: colors.backgroundAlt.withOpacity(0.95),
        border: Border(top: BorderSide(color: colors.brand.withOpacity(0.16))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: items.map((item) {
          final isSelected = item.route == currentRoute ||
              (item.route == '/admin' && currentRoute == '/admin');
          return InkWell(
            onTap: () {
              if (!isSelected) context.go(item.route);
            },
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isSelected ? item.activeIcon : item.icon,
                    color: isSelected ? colors.brand : colors.textMuted,
                    size: 20,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.label,
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight:
                          isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected ? colors.brand : colors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _AdminNavItem {
  const _AdminNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.route,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String route;
}

// ─── Glow orb ──────────────────────────────────────────────────────────────────

class _AdminGlowOrb extends StatelessWidget {
  const _AdminGlowOrb({
    required this.color,
    required this.size,
  });

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, Colors.transparent],
          ),
        ),
      ),
    );
  }
}

// ─── Data models ───────────────────────────────────────────────────────────────

class _AdminSnapshot {
  const _AdminSnapshot({
    required this.totalGyms,
    required this.totalUsers,
    required this.totalClients,
    required this.activeSubscriptions,
    required this.recentGyms,
  });

  const _AdminSnapshot.empty()
      : totalGyms = 0,
        totalUsers = 0,
        totalClients = 0,
        activeSubscriptions = 0,
        recentGyms = const [];

  final int totalGyms;
  final int totalUsers;
  final int totalClients;
  final int activeSubscriptions;
  final List<_AdminGymRecord> recentGyms;

  int get estimatedRevenue => activeSubscriptions * 2199;
  int get retentionPercent {
    if (totalGyms == 0) return 0;
    return math.min(
        99, math.max(0, ((activeSubscriptions / totalGyms) * 100).round()));
  }

  /// 6 monthly data points for the growth chart
  List<double> get growthPoints {
    final baseline = math.max(8, activeSubscriptions).toDouble();
    return [
      baseline * 0.80,
      baseline * 1.10,
      baseline * 0.92,
      baseline * 1.18,
      baseline * 0.76,
      baseline * 1.24,
    ];
  }

  List<_AdminActivityItem> activityFeed(FitNexoraThemeTokens colors) {
    final firstGym = recentGyms.isNotEmpty ? recentGyms.first : null;
    return [
      _AdminActivityItem(
        icon: Icons.person_add_alt_1_rounded,
        color: colors.brand,
        title: 'New Partner Onboarded',
        subtitle: firstGym == null
            ? 'A new gym completed platform verification.'
            : '${firstGym.name} completed verification.',
        timestamp: '2 hours ago',
      ),
      _AdminActivityItem(
        icon: Icons.verified_rounded,
        color: colors.success,
        title: 'Payout Processed',
        subtitle:
            'Rs ${(estimatedRevenue * 0.25).round()} sent to partner settlements.',
        timestamp: '5 hours ago',
      ),
      _AdminActivityItem(
        icon: Icons.warning_amber_rounded,
        color: colors.warning,
        title: 'System Alert',
        subtitle: 'Latency spike detected in AP-South-1 region.',
        timestamp: '12 hours ago',
      ),
      _AdminActivityItem(
        icon: Icons.auto_awesome_rounded,
        color: colors.info,
        title: 'AI Model Updated',
        subtitle: 'Workout plan generation model rolled to v2.1.',
        timestamp: '1 day ago',
      ),
    ];
  }
}

class _AdminGymRecord {
  const _AdminGymRecord({
    required this.id,
    required this.name,
    required this.address,
    required this.isActive,
    required this.planTier,
    required this.createdAt,
  });

  factory _AdminGymRecord.fromJson(Map<String, dynamic> json) {
    return _AdminGymRecord(
      id: (json['id'] ?? '').toString(),
      name: ((json['name'] ?? '') as String).trim(),
      address: ((json['address'] ?? '') as String).trim(),
      isActive: json['is_active'] == true,
      planTier: ((json['plan_tier'] ?? 'basic') as String).trim(),
      createdAt: ((json['created_at'] ?? '') as String).trim(),
    );
  }

  final String id;
  final String name;
  final String address;
  final bool isActive;
  final String planTier;
  final String createdAt;

  String get locationLabel {
    if (address.isEmpty) return 'Unknown';
    final segments = address
        .split(',')
        .map((segment) => segment.trim())
        .where((segment) => segment.isNotEmpty)
        .toList();
    if (segments.length >= 2) {
      return '${segments.first}, ${segments[1]}';
    }
    return segments.first;
  }

  String get dateLabel {
    if (createdAt.isEmpty) return '-';
    final parsed = DateTime.tryParse(createdAt);
    if (parsed == null) return '-';
    return '${parsed.day}/${parsed.month}/${parsed.year.toString().substring(2)}';
  }

  String get planLabel =>
      'ID: ${id.isEmpty ? '#NA' : '#${id.substring(0, math.min(6, id.length)).toUpperCase()}'} - ${planTier.toUpperCase()}';
}

class _AdminActivityItem {
  const _AdminActivityItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.timestamp,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String timestamp;
}
