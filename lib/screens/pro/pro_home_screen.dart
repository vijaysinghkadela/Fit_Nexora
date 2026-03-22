import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;

import '../../core/extensions.dart';
import '../../models/food_log_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/gym_provider.dart';
import '../../providers/member_provider.dart';
import '../../providers/pro_member_provider.dart';
import '../../widgets/glassmorphic_card.dart';
import '../../widgets/loading_widgets.dart';
import '../../core/responsive.dart';
import '../member/member_paywall_screen.dart';

import 'pro_paywall_screen.dart';
import 'pro_nutrition_screen.dart';
import 'pro_measurements_screen.dart';
import 'pro_ai_screen.dart';

/// Pro Plan Home — shows paywall if not Pro, falls back to Basic if only Basic.
class ProHomeScreen extends ConsumerWidget {
  const ProHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final basicAccessAsync = ref.watch(memberHasAccessProvider);
    final proAccessAsync = ref.watch(memberHasProAccessProvider);

    // Wait for both
    return basicAccessAsync.when(
      loading: () => const DashboardSkeletonScaffold(),
      error: (_, __) => const MemberPaywallScreen(),
      data: (hasBasic) {
        if (!hasBasic) return const MemberPaywallScreen();
        return proAccessAsync.when(
          loading: () => const DashboardSkeletonScaffold(),
          error: (_, __) => const ProPaywallScreen(),
          data: (hasPro) {
            if (!hasPro) return const ProPaywallScreen();
            return const _ProDashboard();
          },
        );
      },
    );
  }
}

// ─── Pro Dashboard ────────────────────────────────────────────────────────────

class _ProDashboard extends ConsumerWidget {
  const _ProDashboard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.fitTheme;
    final user = ref.watch(currentUserProvider).value;
    final _ = ref.watch(selectedGymProvider); // gym data used by sub-widgets
    final membershipAsync = ref.watch(memberMembershipProvider);
    final nutritionAsync = ref.watch(proTodayNutritionProvider);
    final weeklyAsync = ref.watch(proWeeklyCaloriesProvider);
    final measurementsAsync = ref.watch(proBodyMeasurementsProvider);
    final attendanceAsync = ref.watch(memberAttendanceProvider);

    final firstName = user?.fullName.split(' ').first ?? 'Member';
    final rs = ResponsiveSize.of(context);

    Future<void> refreshAll() async {
      ref.invalidate(memberMembershipProvider);
      ref.invalidate(proTodayNutritionProvider);
      ref.invalidate(proTodayFoodLogsProvider);
      ref.invalidate(proWeeklyCaloriesProvider);
      ref.invalidate(proBodyMeasurementsProvider);
      ref.invalidate(memberAttendanceProvider);
      await Future.wait([
        ref.read(memberMembershipProvider.future),
        ref.read(proTodayNutritionProvider.future),
        ref.read(proWeeklyCaloriesProvider.future),
        ref.read(proBodyMeasurementsProvider.future),
        ref.read(memberAttendanceProvider.future),
      ]);
    }

    return Scaffold(
      backgroundColor: t.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: refreshAll,
          backgroundColor: t.surface,
          color: t.brand,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
          // ─── Header ─────────────────────────────────────────────
          SliverAppBar(
            floating: true,
            backgroundColor: t.background,
            toolbarHeight: 80,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Welcome, ',
                      style: GoogleFonts.inter(
                        fontSize: 13, color: t.textSecondary),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF3AA8FF), Color(0xFF0066FF)]),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'PRO',
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ],
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
              IconButton(
                icon: Icon(Icons.smart_toy_rounded,
                    color: t.brand),
                tooltip: 'AI Suggestions',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const ProAiScreen()),
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),

          // ─── Membership + Attendance Row ─────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  Expanded(child: _MiniMembershipCard(async: membershipAsync)),
                  const SizedBox(width: 12),
                  _StatChip(
                    icon: Icons.calendar_today_rounded,
                    label: 'Attendance',
                    value: attendanceAsync.when(
                      data: (v) => '$v days',
                      loading: () => '...',
                      error: (_, __) => '—',
                    ),
                    color: t.info,
                  ),
                ],
              ),
            ),
          ),

          // ─── Calories Ring Card ───────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            sliver: SliverToBoxAdapter(
              child: nutritionAsync.when(
                loading: () => _shimmer(context, height: 180, t: t),
                error: (_, __) => const SizedBox.shrink(),

                data: (summary) => _CaloriesCard(
                  summary: summary,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const ProNutritionScreen()),
                  ),
                ),
              ),
            ),
          ),

          // ─── 7-Day Calorie Chart ──────────────────────────────────
          _sectionHeader('WEEKLY CALORIES', t),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
            sliver: SliverToBoxAdapter(
              child: weeklyAsync.when(
                loading: () => _shimmer(context, height: 140, t: t),
                error: (_, __) => const SizedBox.shrink(),

                data: (days) => _WeeklyCaloriesChart(days: days),
              ),
            ),
          ),

          // ─── Body Measurements ───────────────────────────────────
          _sectionHeader('BODY MEASUREMENTS', t),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
            sliver: SliverToBoxAdapter(
              child: measurementsAsync.when(
                loading: () => _shimmer(context, height: 100, t: t),
                error: (_, __) => const SizedBox.shrink(),

                data: (m) => _MeasurementsCard(
                  measurement: m,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const ProMeasurementsScreen()),
                  ),
                ),
              ),
            ),
          ),

          // ─── Quick Actions ────────────────────────────────────────
          _sectionHeader('QUICK ACTIONS', t),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
            sliver: SliverToBoxAdapter(
              child: _QuickActionsGrid(context: context),
            ),
          ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, dynamic t) => SliverPadding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
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

  Widget _shimmer(BuildContext context, {required double height, required dynamic t}) {
    final rs = ResponsiveSize.of(context);
    return Container(
      height: rs.sp(height),
      decoration: BoxDecoration(
        color: t.surfaceAlt,
        borderRadius: BorderRadius.circular(16),
      ),
    ).animate(onPlay: (c) => c.repeat()).shimmer(
        duration: 1200.ms,
        color: t.surface.withOpacity(0.5));
  }
}

// ─── Calories Ring Card ───────────────────────────────────────────────────────

class _CaloriesCard extends StatelessWidget {
  final NutritionSummary summary;
  final VoidCallback onTap;
  const _CaloriesCard({required this.summary, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;
    final consumed = summary.calories;
    final target = DailyTargets.calories;
    final progress = (consumed / target).clamp(0.0, 1.0);
    final remaining = (target - consumed).clamp(0.0, double.infinity);
    final rs = ResponsiveSize.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              t.brand.withOpacity(0.15),
              t.accent.withOpacity(0.06),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: t.brand.withOpacity(0.25)),
        ),
        child: Row(
          children: [
            // Ring
            SizedBox(
              width: rs.sp(110),
              height: rs.sp(110),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: Size(rs.sp(110), rs.sp(110)),
                    painter:
                        _RingPainter(progress: progress, color: t.brand),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        consumed.toStringAsFixed(0),
                        style: GoogleFonts.inter(
                          fontSize: rs.sp(22),
                          fontWeight: FontWeight.w900,
                          color: t.textPrimary,
                        ),
                      ),
                      Text(
                        'kcal',
                        style: GoogleFonts.inter(
                            fontSize: 10, color: t.textMuted),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            // Macros breakdown
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _MacroRow('Protein', summary.protein, DailyTargets.protein,
                      t.brand),
                  const SizedBox(height: 8),
                  _MacroRow('Carbs', summary.carbs, DailyTargets.carbs,
                      t.accent),
                  const SizedBox(height: 8),
                  _MacroRow(
                      'Fat', summary.fat, DailyTargets.fat, t.warning),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: t.surface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${remaining.toStringAsFixed(0)} kcal remaining · Tap to log',
                      style: GoogleFonts.inter(
                          fontSize: 11, color: t.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.04),
    );
  }
}

class _MacroRow extends StatelessWidget {
  final String label;
  final double current;
  final double target;
  final Color color;
  const _MacroRow(this.label, this.current, this.target, this.color);

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;
    final pct = (current / target).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 11, color: t.textSecondary)),
            Text('${current.toStringAsFixed(0)}g',
                style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: color)),
          ],
        ),
        const SizedBox(height: 3),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: pct,
            backgroundColor: color.withOpacity(0.12),
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 5,
          ),
        ),
      ],
    );
  }
}

// ─── Ring painters ────────────────────────────────────────────────────────────

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  _RingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 12) / 2;
    final bgPaint = Paint()
      ..color = color.withOpacity(0.12)
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final fgPaint = Paint()
      ..shader = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: -math.pi / 2 + 2 * math.pi * progress,
        colors: [color.withOpacity(0.6), color],
        tileMode: TileMode.clamp,
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) => old.progress != progress;
}

// ─── Weekly Calories Chart ────────────────────────────────────────────────────

class _WeeklyCaloriesChart extends StatelessWidget {
  final List<DayCalories> days;
  const _WeeklyCaloriesChart({required this.days});

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;
    final maxKcal = days.fold(0.0, (m, d) => d.kcal > m ? d.kcal : m);
    final target = DailyTargets.calories;
    final chartMax = math.max(maxKcal, target) * 1.15;

    return GlassmorphicCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: t.brand,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 6),
                Text('Calories',
                    style: GoogleFonts.inter(
                        fontSize: 12, color: t.textSecondary)),
                const SizedBox(width: 16),
                Container(
                  width: 10,
                  height: 2,
                  color: t.warning.withOpacity(0.6),
                ),
                const SizedBox(width: 6),
                Text('Target',
                    style: GoogleFonts.inter(
                        fontSize: 12, color: t.textMuted)),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 100,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: days.asMap().entries.map((entry) {
                  final day = entry.value;
                  final barHeight = chartMax > 0
                      ? (day.kcal / chartMax) * 80
                      : 0.0;
                  final isToday = entry.key == days.length - 1;
                  final dayLabel = _dayLabel(day.date);

                  return Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (day.kcal > 0)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 3),
                            child: Text(
                              '${(day.kcal / 1000).toStringAsFixed(1)}k',
                              style: GoogleFonts.inter(
                                  fontSize: 8,
                                  color: isToday
                                      ? t.brand
                                      : t.textMuted),
                            ),
                          ),
                        Container(
                          height: barHeight.clamp(4.0, 80.0),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: isToday
                                  ? [t.brand, t.accent]
                                  : [
                                      t.brand.withOpacity(0.5),
                                      t.brand.withOpacity(0.2),
                                    ],
                            ),
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          dayLabel,
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: isToday
                                ? FontWeight.w800
                                : FontWeight.w400,
                            color: isToday
                                ? t.brand
                                : t.textMuted,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    ).animate(delay: 100.ms).fadeIn();
  }

  String _dayLabel(DateTime d) {
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return days[d.weekday - 1];
  }
}

// ─── Measurements Card ────────────────────────────────────────────────────────

class _MeasurementsCard extends StatelessWidget {
  final dynamic measurement;
  final VoidCallback onTap;
  const _MeasurementsCard(
      {required this.measurement, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;
    if (measurement == null) {
      return GestureDetector(
        onTap: onTap,
        child: GlassmorphicCard(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.straighten_rounded, color: t.accent),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('No measurements yet — tap to log',
                      style: GoogleFonts.inter(
                          color: t.textSecondary, fontSize: 14)),
                ),
                Icon(Icons.chevron_right_rounded,
                    color: t.textMuted),
              ],
            ),
          ),
        ),
      );
    }

    final m = measurement;
    final chips = <String, double?>{
      'Weight': m.weightKg,
      'Body Fat': m.bodyFatPercent,
      'Waist': m.waistCm,
      'Chest': m.chestCm,
      'Arms': m.armCm,
    };

    return GestureDetector(
      onTap: onTap,
      child: GlassmorphicCard(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.straighten_rounded,
                      color: t.accent, size: 18),
                  const SizedBox(width: 8),
                  Text('Latest Measurements',
                      style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: t.textPrimary)),
                  const Spacer(),
                  Text(
                    _formatDate(m.checkInDate as DateTime),
                    style: GoogleFonts.inter(
                        fontSize: 11, color: t.textMuted),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: chips.entries
                    .where((e) => e.value != null)
                    .map((e) => _MeasChip(
                        label: e.key, value: e.value!,
                        unit: e.key == 'Body Fat' ? '%' : e.key == 'Weight' ? ' kg' : ' cm'))
                    .toList(),
              ),
            ],
          ),
        ),
      ).animate(delay: 150.ms).fadeIn(),
    );
  }

  String _formatDate(DateTime dt) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${dt.day} ${months[dt.month - 1]}';
  }
}

class _MeasChip extends StatelessWidget {
  final String label;
  final double value;
  final String unit;
  const _MeasChip(
      {required this.label, required this.value, required this.unit});

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: t.accent.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: t.accent.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(
            '${value.toStringAsFixed(1)}$unit',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: t.accent,
            ),
          ),
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 10, color: t.textSecondary)),
        ],
      ),
    );
  }
}

// ─── Mini Membership Card ─────────────────────────────────────────────────────

class _MiniMembershipCard extends StatelessWidget {
  final AsyncValue<dynamic> async;
  const _MiniMembershipCard({required this.async});

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;
    return async.when(
      loading: () => const SizedBox(height: 60),
      error: (_, __) => const SizedBox.shrink(),
      data: (m) {
        if (m == null) return const SizedBox.shrink();
        final daysLeft = m.daysRemaining as int;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              const Color(0xFF3AA8FF).withOpacity(0.12),
              t.brand.withOpacity(0.06),
            ]),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: const Color(0xFF3AA8FF).withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.workspace_premium_rounded,
                  color: Color(0xFF3AA8FF), size: 18),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(m.planName as String,
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: t.textPrimary)),
                  Text('$daysLeft days left',
                      style: GoogleFonts.inter(
                          fontSize: 10, color: t.textSecondary)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Stat Chip ────────────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _StatChip(
      {required this.icon,
      required this.label,
      required this.value,
      required this.color});

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: color)),
              Text(label,
                  style: GoogleFonts.inter(
                      fontSize: 10, color: t.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Quick Actions Grid ───────────────────────────────────────────────────────

class _QuickActionsGrid extends StatelessWidget {
  final BuildContext context;
  const _QuickActionsGrid({required this.context});

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;
    final actions = [
      (Icons.add_circle_rounded, 'Log Food', t.brand,
          () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProNutritionScreen()))),
      (Icons.qr_code_scanner_rounded, 'Scan Barcode', t.accent,
          () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProNutritionScreen()))),
      (Icons.straighten_rounded, 'Measurements', t.info,
          () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProMeasurementsScreen()))),
      (Icons.smart_toy_rounded, 'AI Advice', t.warning,
          () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProAiScreen()))),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 2.2,
      children: actions.asMap().entries.map((entry) {
        final i = entry.key;
        final (icon, label, color, onTap) = entry.value;
        return GestureDetector(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color.withOpacity(0.22)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: t.textPrimary,
                  ),
                ),
              ],
            ),
          ).animate(delay: (i * 60).ms).fadeIn().slideY(begin: 0.04),
        );
      }).toList(),
    );
  }
}
