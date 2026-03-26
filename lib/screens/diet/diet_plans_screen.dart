import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/extensions.dart';
import '../../config/theme.dart';
import '../../config/diet_templates.dart';
import '../../models/diet_plan_model.dart';
import '../../widgets/glassmorphic_card.dart';

class DietPlansScreen extends ConsumerStatefulWidget {
  const DietPlansScreen({super.key});

  @override
  ConsumerState<DietPlansScreen> createState() => _DietPlansScreenState();
}

class _DietPlansScreenState extends ConsumerState<DietPlansScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // Mock data
  static const int _kcalConsumed = 1625;
  static const int _kcalGoal = 2500;
  static const int _kcalRemaining = _kcalGoal - _kcalConsumed;

  static const int _proteinGoal = 180;
  static const int _proteinCurrent = 142;
  static const int _carbsGoal = 280;
  static const int _carbsCurrent = 210;
  static const int _fatGoal = 73;
  static const int _fatCurrent = 58;

  final _meals = const [
    _MealTimelineItem(
      name: 'Oatmeal with Berries',
      mealType: 'Breakfast',
      kcal: 420,
      time: '7:30 AM',
      icon: Icons.wb_sunny_rounded,
      completed: true,
    ),
    _MealTimelineItem(
      name: 'Grilled Chicken Salad',
      mealType: 'Lunch',
      kcal: 580,
      time: '12:30 PM',
      icon: Icons.wb_cloudy_rounded,
      completed: true,
    ),
    _MealTimelineItem(
      name: 'Greek Yogurt',
      mealType: 'Snack',
      kcal: 150,
      time: '4:00 PM',
      icon: Icons.cookie_rounded,
      completed: false,
    ),
    _MealTimelineItem(
      name: 'Salmon with Quinoa',
      mealType: 'Dinner',
      kcal: 680,
      time: '7:30 PM',
      icon: Icons.nights_stay_rounded,
      completed: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAddMealSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddMealSheet(themeTokens: context.fitTheme),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;
    final double gaugeProgress = (_kcalConsumed / _kcalGoal).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: t.background,
      floatingActionButton: AnimatedBuilder(
        animation: _tabController,
        builder: (context, _) {
          // Only show FAB on the Today's Plan tab
          if (_tabController.index != 0) return const SizedBox.shrink();
          return FloatingActionButton.extended(
            onPressed: _showAddMealSheet,
            backgroundColor: t.accent,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add_rounded),
            label: Text(
              'Add Meal',
              style:
                  GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14),
            ),
          );
        },
      ),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            floating: true,
            snap: true,
            pinned: true,
            forceElevated: innerBoxIsScrolled,
            backgroundColor: t.background,
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: BackButton(
              onPressed: () =>
                  context.canPop() ? context.pop() : context.go('/'),
            ),
            automaticallyImplyLeading: true,
            title: Text(
              'Diet Plans',
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: t.textPrimary,
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.settings_rounded, color: t.textSecondary),
                onPressed: () {},
              ),
              const SizedBox(width: 4),
            ],
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: "Today's Plan"),
                Tab(text: 'Templates'),
              ],
              labelColor: t.brand,
              unselectedLabelColor: t.textMuted,
              indicatorColor: t.brand,
              labelStyle: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              unselectedLabelStyle: GoogleFonts.inter(
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            // ── Tab 0: Today's Plan ──────────────────────────────────────────
            _TodaysPlanTab(
              kcalConsumed: _kcalConsumed,
              kcalGoal: _kcalGoal,
              kcalRemaining: _kcalRemaining,
              proteinGoal: _proteinGoal,
              proteinCurrent: _proteinCurrent,
              carbsGoal: _carbsGoal,
              carbsCurrent: _carbsCurrent,
              fatGoal: _fatGoal,
              fatCurrent: _fatCurrent,
              meals: _meals,
              gaugeProgress: gaugeProgress,
              themeTokens: t,
            ),

            // ── Tab 1: Templates ─────────────────────────────────────────────
            _buildTemplatesTab(context),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplatesTab(BuildContext context) {
    final t = context.fitTheme;
    final templates = kDietTemplates;

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          sliver: SliverToBoxAdapter(
            child: Text(
              'Pre-built Nutrition Plans',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: t.textPrimary,
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
          sliver: SliverToBoxAdapter(
            child: Text(
              'Choose a plan to assign to your clients or use as your own guide',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: t.textSecondary,
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 80),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _DietTemplateCard(
                plan: templates[index],
                themeTokens: t,
              ),
              childCount: templates.length,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Today's Plan Tab ──────────────────────────────────────────────────────────

class _TodaysPlanTab extends StatelessWidget {
  final int kcalConsumed;
  final int kcalGoal;
  final int kcalRemaining;
  final int proteinGoal;
  final int proteinCurrent;
  final int carbsGoal;
  final int carbsCurrent;
  final int fatGoal;
  final int fatCurrent;
  final List<_MealTimelineItem> meals;
  final double gaugeProgress;
  final FitNexoraThemeTokens themeTokens;

  const _TodaysPlanTab({
    required this.kcalConsumed,
    required this.kcalGoal,
    required this.kcalRemaining,
    required this.proteinGoal,
    required this.proteinCurrent,
    required this.carbsGoal,
    required this.carbsCurrent,
    required this.fatGoal,
    required this.fatCurrent,
    required this.meals,
    required this.gaugeProgress,
    required this.themeTokens,
  });

  @override
  Widget build(BuildContext context) {
    final t = themeTokens;

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // ── Calorie Gauge ────────────────────────────────────────────
              _DietCalorieGauge(
                consumed: kcalConsumed,
                goal: kcalGoal,
                remaining: kcalRemaining,
                progress: gaugeProgress,
                themeTokens: t,
              ).animate().fadeIn(duration: 500.ms).scale(
                    begin: const Offset(0.92, 0.92),
                    end: const Offset(1, 1),
                    curve: Curves.easeOutBack,
                  ),

              const SizedBox(height: 16),

              // ── Stats Row ────────────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: GlassmorphicCard(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Text(
                              '$kcalRemaining',
                              style: GoogleFonts.inter(
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                color: t.accent,
                              ),
                            ),
                            Text(
                              'remaining',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: t.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GlassmorphicCard(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Text(
                              '${(gaugeProgress * 100).round()}%',
                              style: GoogleFonts.inter(
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                color: t.brand,
                              ),
                            ),
                            Text(
                              'achieved',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: t.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 120.ms).slideY(begin: 0.05, end: 0),

              const SizedBox(height: 20),

              // ── Macro Breakdown ──────────────────────────────────────────
              GlassmorphicCard(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Macro Breakdown',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: t.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: _MacroBarChart(
                              label: 'Protein',
                              current: proteinCurrent,
                              goal: proteinGoal,
                              unit: 'g',
                              color: t.info,
                              t: t,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _MacroBarChart(
                              label: 'Carbs',
                              current: carbsCurrent,
                              goal: carbsGoal,
                              unit: 'g',
                              color: t.warning,
                              t: t,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _MacroBarChart(
                              label: 'Fats',
                              current: fatCurrent,
                              goal: fatGoal,
                              unit: 'g',
                              color: t.danger,
                              t: t,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: 220.ms).slideY(begin: 0.05, end: 0),

              const SizedBox(height: 24),

              // ── Meal Timeline ────────────────────────────────────────────
              Text(
                "Today's Meals",
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: t.textPrimary,
                ),
              ).animate().fadeIn(delay: 280.ms),

              const SizedBox(height: 12),

              ...List.generate(meals.length, (index) {
                return _MealTimelineCard(
                  item: meals[index],
                  themeTokens: t,
                  animDelay: 320 + index * 70,
                );
              }),

              const SizedBox(height: 100),
            ]),
          ),
        ),
      ],
    );
  }
}

// ── Diet Template Card ────────────────────────────────────────────────────────

class _DietTemplateCard extends StatelessWidget {
  final DietPlan plan;
  final FitNexoraThemeTokens themeTokens;

  const _DietTemplateCard({
    required this.plan,
    required this.themeTokens,
  });

  Color _goalColor(FitNexoraThemeTokens t) {
    switch (plan.goal) {
      case 'muscle_gain':
        return t.brand;
      case 'fat_loss':
        return t.danger;
      case 'maintenance':
        return t.info;
      case 'recomp':
        return t.accent;
      default:
        return t.textMuted;
    }
  }

  String _goalLabel() {
    switch (plan.goal) {
      case 'muscle_gain':
        return 'Muscle Gain';
      case 'fat_loss':
        return 'Fat Loss';
      case 'maintenance':
        return 'Maintenance';
      case 'recomp':
        return 'Body Recomp';
      case 'performance':
        return 'Performance';
      default:
        return plan.goal.replaceAll('_', ' ').titleCase;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = themeTokens;
    final goalColor = _goalColor(t);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: GlassmorphicCard(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header row: name + goal badge ──────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      plan.name,
                      style: GoogleFonts.inter(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: t.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: goalColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: goalColor.withOpacity(0.35)),
                    ),
                    child: Text(
                      _goalLabel(),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: goalColor,
                      ),
                    ),
                  ),
                ],
              ),

              // ── Description ───────────────────────────────────────────
              if (plan.description != null && plan.description!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  plan.description!,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: t.textSecondary,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              const SizedBox(height: 12),

              // ── Calorie + macro row ──────────────────────────────────
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _MacroChip(
                    label: '${plan.targetCalories} kcal',
                    color: t.brand,
                    t: t,
                    icon: Icons.local_fire_department_rounded,
                  ),
                  _MacroChip(
                    label: 'P: ${plan.targetProtein}g',
                    color: t.info,
                    t: t,
                  ),
                  _MacroChip(
                    label: 'C: ${plan.targetCarbs}g',
                    color: t.warning,
                    t: t,
                  ),
                  _MacroChip(
                    label: 'F: ${plan.targetFat}g',
                    color: t.danger,
                    t: t,
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // ── Hydration + meal count row ───────────────────────────
              Row(
                children: [
                  Icon(Icons.water_drop_rounded, size: 14, color: t.info),
                  const SizedBox(width: 4),
                  Text(
                    '${plan.hydrationLiters.toStringAsFixed(1)}L / day',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: t.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.restaurant_rounded, size: 14, color: t.textMuted),
                  const SizedBox(width: 4),
                  Text(
                    '${plan.meals.length} meal${plan.meals.length == 1 ? '' : 's'}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: t.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // ── "Use This Plan" button ───────────────────────────────
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton(
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${plan.name} ready to use',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                      ),
                      backgroundColor: context.fitTheme.accent,
                      behavior: SnackBarBehavior.floating,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: t.brand),
                    foregroundColor: t.brand,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: Text(
                    'Use This Plan',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.04, end: 0),
    );
  }
}

// ── Macro Chip ────────────────────────────────────────────────────────────────

class _MacroChip extends StatelessWidget {
  final String label;
  final Color color;
  final FitNexoraThemeTokens t;
  final IconData? icon;

  const _MacroChip({
    required this.label,
    required this.color,
    required this.t,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: color),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Diet Calorie Gauge ────────────────────────────────────────────────────────

class _DietCalorieGauge extends StatelessWidget {
  final int consumed;
  final int goal;
  final int remaining;
  final double progress;
  final FitNexoraThemeTokens themeTokens;

  const _DietCalorieGauge({
    required this.consumed,
    required this.goal,
    required this.remaining,
    required this.progress,
    required this.themeTokens,
  });

  @override
  Widget build(BuildContext context) {
    final t = themeTokens;
    return Center(
      child: SizedBox(
        width: 200,
        height: 200,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: const Size(200, 200),
              painter: _DietGaugePainter(
                value: progress,
                trackColor: t.ringTrack,
                startColor: t.brand,
                endColor: t.accent,
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$consumed',
                  style: GoogleFonts.inter(
                    fontSize: 38,
                    fontWeight: FontWeight.w900,
                    color: t.textPrimary,
                    height: 1,
                  ),
                ),
                Text(
                  '/ $goal kcal',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: t.textMuted,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: t.brand.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: t.brand.withOpacity(0.3)),
                  ),
                  child: Text(
                    '${(progress * 100).round()}% achieved',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: t.brand,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DietGaugePainter extends CustomPainter {
  final double value;
  final Color trackColor;
  final Color startColor;
  final Color endColor;

  _DietGaugePainter({
    required this.value,
    required this.trackColor,
    required this.startColor,
    required this.endColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 14.0;
    const startAngle = 3 * math.pi / 4;
    const sweepAngle = 3 * math.pi / 2;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - strokeWidth / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Track
    final trackPaint = Paint()
      ..color = trackColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, startAngle, sweepAngle, false, trackPaint);

    if (value > 0) {
      final progressSweep = sweepAngle * value;
      final shader = SweepGradient(
        startAngle: startAngle,
        endAngle: startAngle + sweepAngle,
        colors: [startColor, endColor],
      ).createShader(rect);

      final progressPaint = Paint()
        ..shader = shader
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(rect, startAngle, progressSweep, false, progressPaint);

      // End dot
      final endAngle = startAngle + progressSweep;
      final dotX = center.dx + radius * math.cos(endAngle);
      final dotY = center.dy + radius * math.sin(endAngle);

      canvas.drawCircle(
        Offset(dotX, dotY),
        strokeWidth / 2,
        Paint()
          ..color = endColor
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
      canvas.drawCircle(
          Offset(dotX, dotY), strokeWidth / 2, Paint()..color = endColor);
    }
  }

  @override
  bool shouldRepaint(_DietGaugePainter old) => old.value != value;
}

// ── Macro Bar Chart ───────────────────────────────────────────────────────────

class _MacroBarChart extends StatelessWidget {
  final String label;
  final int current;
  final int goal;
  final String unit;
  final Color color;
  final FitNexoraThemeTokens t;

  const _MacroBarChart({
    required this.label,
    required this.current,
    required this.goal,
    required this.unit,
    required this.color,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (current / goal).clamp(0.0, 1.0);
    const barHeight = 100.0;

    return Column(
      children: [
        Text(
          '$current$unit',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Stack(
          alignment: Alignment.bottomCenter,
          children: [
            // Track bar
            Container(
              width: double.infinity,
              height: barHeight,
              decoration: BoxDecoration(
                color: t.ringTrack,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            // Progress bar
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutCubic,
                height: barHeight * progress,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      color,
                      color.withOpacity(0.6),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
              ),
            ),
            // Percentage label inside bar
            if (progress > 0.25)
              Positioned(
                bottom: barHeight * progress / 2 - 8,
                child: Text(
                  '${(progress * 100).round()}%',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: t.textSecondary,
          ),
        ),
        Text(
          '/$goal$unit',
          style: GoogleFonts.inter(fontSize: 10, color: t.textMuted),
        ),
      ],
    );
  }
}

// ── Meal Timeline Card ────────────────────────────────────────────────────────

class _MealTimelineCard extends StatelessWidget {
  final _MealTimelineItem item;
  final FitNexoraThemeTokens themeTokens;
  final int animDelay;

  const _MealTimelineCard({
    required this.item,
    required this.themeTokens,
    required this.animDelay,
  });

  @override
  Widget build(BuildContext context) {
    final t = themeTokens;
    final completed = item.completed;
    final mealColor = completed ? t.accent : t.textMuted.withOpacity(0.5);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassmorphicCard(
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border(
              left: BorderSide(
                color: mealColor,
                width: 3,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: mealColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(item.icon, color: mealColor, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            item.mealType,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: completed ? mealColor : t.textMuted,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(width: 6),
                          if (!completed)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: t.warning.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Upcoming',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: t.warning,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.name,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: completed ? t.textPrimary : t.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${item.kcal} kcal',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: completed ? t.brand : t.textMuted,
                      ),
                    ),
                    Text(
                      item.time,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: t.textMuted,
                      ),
                    ),
                  ],
                ),
                if (completed) ...[
                  const SizedBox(width: 10),
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: t.accent.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.check_rounded, color: t.accent, size: 16),
                  ),
                ],
              ],
            ),
          ),
        ),
      )
          .animate(delay: Duration(milliseconds: animDelay))
          .fadeIn()
          .slideX(begin: 0.04, end: 0),
    );
  }
}

// ── Add Meal Sheet ────────────────────────────────────────────────────────────

class _AddMealSheet extends StatefulWidget {
  final FitNexoraThemeTokens themeTokens;

  const _AddMealSheet({required this.themeTokens});

  @override
  State<_AddMealSheet> createState() => _AddMealSheetState();
}

class _AddMealSheetState extends State<_AddMealSheet> {
  final _nameCtrl = TextEditingController();
  final _kcalCtrl = TextEditingController();
  String _mealType = 'Breakfast';

  @override
  void dispose() {
    _nameCtrl.dispose();
    _kcalCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.themeTokens;
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.65,
      ),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: t.glassBorder)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          20,
          24,
          MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: t.textMuted.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Add Meal',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: t.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            // Meal type chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['Breakfast', 'Lunch', 'Dinner', 'Snack'].map((type) {
                  final selected = type == _mealType;
                  return GestureDetector(
                    onTap: () => setState(() => _mealType = type),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color:
                            selected ? t.brand.withOpacity(0.14) : t.surfaceAlt,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: selected ? t.brand : t.border,
                        ),
                      ),
                      child: Text(
                        type,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w500,
                          color: selected ? t.brand : t.textSecondary,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameCtrl,
              style: GoogleFonts.inter(color: t.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Meal name',
                prefixIcon: Icon(Icons.restaurant_rounded,
                    color: t.textMuted, size: 20),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _kcalCtrl,
              keyboardType: TextInputType.number,
              style: GoogleFonts.inter(color: t.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Calories (kcal)',
                prefixIcon: Icon(Icons.local_fire_department_rounded,
                    color: t.textMuted, size: 20),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${_nameCtrl.text.isEmpty ? _mealType : _nameCtrl.text} added',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                      ),
                      backgroundColor: t.accent,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: t.accent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'Add Meal',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().slideY(begin: 0.04, end: 0, duration: 300.ms).fadeIn();
  }
}

// ── Data classes ──────────────────────────────────────────────────────────────

class _MealTimelineItem {
  final String name;
  final String mealType;
  final int kcal;
  final String time;
  final IconData icon;
  final bool completed;

  const _MealTimelineItem({
    required this.name,
    required this.mealType,
    required this.kcal,
    required this.time,
    required this.icon,
    required this.completed,
  });
}
