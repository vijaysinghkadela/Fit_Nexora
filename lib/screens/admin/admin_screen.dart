import 'dart:math' as math;

import 'package:flutter/material.dart';
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

class _AccessDeniedPage extends StatelessWidget {
  const _AccessDeniedPage({this.user});

  final AppUser? user;

  @override
  Widget build(BuildContext context) {
    final colors = FitNexoraThemeTokens.dark();

    return Scaffold(
      backgroundColor: colors.background,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF120C22),
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
                color: colors.brand.withValues(alpha: 0.18),
                size: 260,
              ),
            ),
            Positioned(
              bottom: -140,
              right: -120,
              child: _AdminGlowOrb(
                color: colors.accent.withValues(alpha: 0.12),
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
                        color: const Color(0x991B1432),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: colors.brand.withValues(alpha: 0.18),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 78,
                            height: 78,
                            decoration: BoxDecoration(
                              color: colors.danger.withValues(alpha: 0.14),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: colors.danger.withValues(alpha: 0.26),
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

class _AdminDashboard extends ConsumerStatefulWidget {
  const _AdminDashboard({required this.user});

  final AppUser user;

  @override
  ConsumerState<_AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends ConsumerState<_AdminDashboard> {
  final FitNexoraThemeTokens _colors = FitNexoraThemeTokens.dark();

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
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF120B22),
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
                color: _colors.brand.withValues(alpha: 0.18),
                size: 260,
              ),
            ),
            Positioned(
              top: 260,
              right: -120,
              child: _AdminGlowOrb(
                color: _colors.info.withValues(alpha: 0.1),
                size: 260,
              ),
            ),
            Positioned(
              bottom: -140,
              left: -80,
              child: _AdminGlowOrb(
                color: _colors.accent.withValues(alpha: 0.1),
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
                        child: _GrowthCard(
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
                          activities: _snapshot.activityFeed,
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
        color: const Color(0x991B1432),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.brand.withValues(alpha: 0.18)),
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
              border: Border.all(color: colors.brand.withValues(alpha: 0.3)),
              gradient: LinearGradient(
                colors: [
                  colors.brand.withValues(alpha: 0.8),
                  colors.brandSecondary.withValues(alpha: 0.85),
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
              color: Colors.white.withValues(alpha: 0.04),
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
                  color: const Color(0xFFFF5B75),
                  shape: BoxShape.circle,
                  border: Border.all(color: _colorsBg, width: 1.2),
                ),
              ),
            ),
        ],
      ),
    );
  }

  static const _colorsBg = Color(0xFF0F0A1E);
}

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
        label: 'Retention',
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
                      color: colors.brand.withValues(alpha: 0.12),
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
        );
      },
    );
  }

  static BoxDecoration _cardDecoration(FitNexoraThemeTokens colors) {
    return BoxDecoration(
      color: const Color(0x991B1432),
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: colors.brand.withValues(alpha: 0.14)),
    );
  }

  static String _formatCompact(int value) {
    if (value >= 100000) {
      return '${(value / 1000).toStringAsFixed(1)}k';
    }
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

class _GrowthCard extends StatelessWidget {
  const _GrowthCard({
    required this.colors,
    required this.loading,
    required this.points,
  });

  final FitNexoraThemeTokens colors;
  final bool loading;
  final List<double> points;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0x991B1432),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.brand.withValues(alpha: 0.14)),
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
                      'Monthly active subscriptions across India',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: colors.brand.withValues(alpha: 0.12)),
                ),
                child: Text(
                  'Last 30 Days',
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
            height: 180,
            child: loading
                ? Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(18),
                    ),
                  )
                : CustomPaint(
                    painter: _GrowthChartPainter(
                      points: points,
                      color: colors.brand,
                    ),
                    child: const SizedBox.expand(),
                  ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(
              4,
              (index) => Text(
                'WEEK ${index + 1}',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: colors.textMuted,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GrowthChartPainter extends CustomPainter {
  const _GrowthChartPainter({
    required this.points,
    required this.color,
  });

  final List<double> points;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withValues(alpha: 0.3),
          color.withValues(alpha: 0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final maxPoint = points.reduce(math.max);
    final minPoint = points.reduce(math.min);
    final spread = math.max(1.0, maxPoint - minPoint);
    final dx = size.width / math.max(1, points.length - 1);

    final path = Path();
    final fillPath = Path();

    for (var i = 0; i < points.length; i++) {
      final x = dx * i;
      final y = size.height -
          (((points[i] - minPoint) / spread) * (size.height - 24)) -
          12;
      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    fillPath
      ..lineTo(size.width, size.height)
      ..close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _GrowthChartPainter oldDelegate) {
    return oldDelegate.points != points || oldDelegate.color != color;
  }
}

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
        color: const Color(0x991B1432),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.brand.withValues(alpha: 0.14)),
      ),
      child: Column(
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
                    context.showSnackBar('Full registration list is coming next.');
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _TableLabel(label: 'GYM DETAILS', flex: 5, colors: colors),
                _TableLabel(label: 'LOCATION', flex: 3, colors: colors),
                _TableLabel(label: 'STATUS', flex: 2, colors: colors),
              ],
            ),
          ),
          const SizedBox(height: 6),
          if (loading)
            for (var i = 0; i < 3; i++)
              _GymRowPlaceholder(colors: colors)
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
            for (final gym in gyms) _GymRow(colors: colors, gym: gym),
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

class _GymRow extends StatelessWidget {
  const _GymRow({
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
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: colors.brand.withValues(alpha: 0.08)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      colors: [
                        colors.brand.withValues(alpha: 0.3),
                        colors.info.withValues(alpha: 0.3),
                      ],
                    ),
                  ),
                  child: Center(
                    child: Text(
                      gym.name.isEmpty ? 'G' : gym.name[0].toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        gym.name,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        gym.planLabel,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: colors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              gym.locationLabel,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: colors.textSecondary,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  statusLabel,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: statusColor,
                  ),
                ),
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
      height: 72,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}

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
        color: const Color(0x991B1432),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.brand.withValues(alpha: 0.14)),
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
                  color: Colors.white.withValues(alpha: 0.03),
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
              color: item.color.withValues(alpha: 0.16),
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
                    color: colors.brand.withValues(alpha: 0.08),
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

    return Container(
      padding: EdgeInsets.fromLTRB(10, 8, 10, 10 + bottomInset),
      decoration: BoxDecoration(
        color: const Color(0xF20F0A1E),
        border: Border(top: BorderSide(color: colors.brand.withValues(alpha: 0.16))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: items.map((item) {
          final isSelected = item.route == '/admin';
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
    return math.min(99, math.max(0, ((activeSubscriptions / totalGyms) * 100).round()));
  }

  List<double> get growthPoints {
    final baseline = math.max(8, activeSubscriptions).toDouble();
    return [
      baseline * 0.8,
      baseline * 1.1,
      baseline * 0.92,
      baseline * 1.18,
      baseline * 0.76,
      baseline * 0.98,
      baseline * 0.7,
      baseline * 1.24,
    ];
  }

  List<_AdminActivityItem> get activityFeed {
    final firstGym = recentGyms.isNotEmpty ? recentGyms.first : null;
    return [
      _AdminActivityItem(
        icon: Icons.person_add_alt_1_rounded,
        color: const Color(0xFF8B5CF6),
        title: 'New Partner Onboarded',
        subtitle: firstGym == null
            ? 'A new gym completed platform verification.'
            : '${firstGym.name} completed verification.',
        timestamp: '2 hours ago',
      ),
      _AdminActivityItem(
        icon: Icons.verified_rounded,
        color: const Color(0xFF22C55E),
        title: 'Payout Processed',
        subtitle:
            'Rs ${(estimatedRevenue * 0.25).round()} sent to partner settlements.',
        timestamp: '5 hours ago',
      ),
      const _AdminActivityItem(
        icon: Icons.warning_amber_rounded,
        color: Color(0xFFF59E0B),
        title: 'System Alert',
        subtitle: 'Latency spike detected in AP-South-1 region.',
        timestamp: '12 hours ago',
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
  });

  factory _AdminGymRecord.fromJson(Map<String, dynamic> json) {
    return _AdminGymRecord(
      id: (json['id'] ?? '').toString(),
      name: ((json['name'] ?? '') as String).trim(),
      address: ((json['address'] ?? '') as String).trim(),
      isActive: json['is_active'] == true,
      planTier: ((json['plan_tier'] ?? 'basic') as String).trim(),
    );
  }

  final String id;
  final String name;
  final String address;
  final bool isActive;
  final String planTier;

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
