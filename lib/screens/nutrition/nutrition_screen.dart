import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/extensions.dart';
import '../../config/theme.dart';
import '../../widgets/glassmorphic_card.dart';
import '../../models/food_log_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/nutrition_provider.dart';
import '../../providers/water_tracker_provider.dart';

// ── Meal type metadata ────────────────────────────────────────────────────────

const _mealTypeOrder = ['breakfast', 'lunch', 'dinner', 'snack', 'other'];

IconData _iconForMealType(String type) {
  switch (type.toLowerCase()) {
    case 'breakfast':
      return Icons.wb_sunny_rounded;
    case 'lunch':
      return Icons.wb_cloudy_rounded;
    case 'dinner':
      return Icons.nights_stay_rounded;
    case 'snack':
      return Icons.cookie_rounded;
    default:
      return Icons.restaurant_rounded;
  }
}

String _labelForMealType(String type) {
  final t = type.trim();
  if (t.isEmpty) return 'Other';
  return t[0].toUpperCase() + t.substring(1).toLowerCase();
}

// ── Static fallback sections (shown when no real data is available) ───────────

const _kFallbackSections = [
  _MealSection(
    type: 'Breakfast',
    icon: Icons.wb_sunny_rounded,
    totalKcal: 420,
    items: [
      _FoodItem(
          name: 'Oatmeal with Berries',
          kcal: 280,
          protein: 8,
          carbs: 52,
          fat: 6),
      _FoodItem(name: 'Boiled Egg', kcal: 78, protein: 6, carbs: 1, fat: 5),
      _FoodItem(name: 'Orange Juice', kcal: 62, protein: 1, carbs: 14, fat: 0),
    ],
  ),
  _MealSection(
    type: 'Lunch',
    icon: Icons.wb_cloudy_rounded,
    totalKcal: 680,
    items: [
      _FoodItem(
          name: 'Grilled Chicken Salad',
          kcal: 380,
          protein: 42,
          carbs: 18,
          fat: 12),
      _FoodItem(
          name: 'Brown Rice (150g)', kcal: 165, protein: 4, carbs: 35, fat: 1),
      _FoodItem(name: 'Dal Tadka', kcal: 135, protein: 9, carbs: 22, fat: 3),
    ],
  ),
  _MealSection(
    type: 'Dinner',
    icon: Icons.nights_stay_rounded,
    totalKcal: 620,
    items: [
      _FoodItem(
          name: 'Paneer Bhurji', kcal: 280, protein: 18, carbs: 8, fat: 20),
      _FoodItem(name: 'Chapati x2', kcal: 200, protein: 6, carbs: 40, fat: 2),
      _FoodItem(name: 'Mixed Salad', kcal: 140, protein: 4, carbs: 24, fat: 3),
    ],
  ),
  _MealSection(
    type: 'Snacks',
    icon: Icons.cookie_rounded,
    totalKcal: 120,
    items: [
      _FoodItem(name: 'Greek Yogurt', kcal: 80, protein: 10, carbs: 6, fat: 1),
      _FoodItem(
          name: 'Mixed Nuts (25g)', kcal: 40, protein: 1, carbs: 2, fat: 3),
    ],
  ),
];

/// Convert a list of [FoodLog] entries into [_MealSection] objects grouped by
/// meal type, preserving the canonical ordering defined in [_mealTypeOrder].
List<_MealSection> _buildSectionsFromLogs(List<FoodLog> logs) {
  if (logs.isEmpty) return [];

  final Map<String, List<FoodLog>> grouped = {};
  for (final log in logs) {
    final key = log.mealType.toLowerCase();
    grouped.putIfAbsent(key, () => []).add(log);
  }

  final orderedKeys = [
    ..._mealTypeOrder.where(grouped.containsKey),
    ...grouped.keys.where((k) => !_mealTypeOrder.contains(k)),
  ];

  return orderedKeys.map((key) {
    final mealLogs = grouped[key]!;
    final totalKcal =
        mealLogs.fold<double>(0, (s, l) => s + l.caloriesKcal).round();
    return _MealSection(
      type: _labelForMealType(key),
      icon: _iconForMealType(key),
      totalKcal: totalKcal,
      items: mealLogs
          .map((l) => _FoodItem(
                name: l.productName,
                kcal: l.caloriesKcal.round(),
                protein: l.proteinG.round(),
                carbs: l.carbsG.round(),
                fat: l.fatG.round(),
              ))
          .toList(),
    );
  }).toList();
}

class NutritionScreen extends ConsumerStatefulWidget {
  const NutritionScreen({super.key});

  @override
  ConsumerState<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends ConsumerState<NutritionScreen> {
  // Fallback calorie goal when no diet plan provider is available.
  static const int _kcalGoal = 2200;
  static const int _kcalBurned = 320;

  // Macro goals (static targets — can be replaced with a diet plan provider).
  static const int _proteinGoal = 180;
  static const int _carbsGoal = 280;
  static const int _fatGoal = 73;

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;

    // ── Real data: water tracker ──────────────────────────────────────────────
    final waterState = ref.watch(waterTrackerProvider);
    final totalWaterMl = waterState.totalTodayMl;
    final waterGoalMl = waterState.dailyGoalMl;

    // ── Real data: today's food logs ──────────────────────────────────────────
    final userId = ref.watch(currentUserProvider).value?.id ?? '';
    final foodLogsAsync =
        userId.isNotEmpty ? ref.watch(todayFoodLogsProvider(userId)) : null;

    final summary = foodLogsAsync?.valueOrNull != null
        ? NutritionSummary.fromLogs(foodLogsAsync!.value!)
        : null;

    final int kcalConsumed =
        summary != null ? summary.calories.round() : 1840; // static fallback

    final int proteinCurrent = summary != null ? summary.protein.round() : 142;
    final int carbsCurrent = summary != null ? summary.carbs.round() : 220;
    final int fatCurrent = summary != null ? summary.fat.round() : 58;

    // Build meal sections from real logs; fall back to static data while
    // loading or when no logs exist yet.
    final List<_MealSection> mealSections;
    if (foodLogsAsync == null || foodLogsAsync.isLoading) {
      mealSections = _kFallbackSections;
    } else {
      final realSections =
          _buildSectionsFromLogs(foodLogsAsync.valueOrNull ?? []);
      mealSections =
          realSections.isNotEmpty ? realSections : _kFallbackSections;
    }

    final double gaugeProgress = (kcalConsumed / _kcalGoal).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: t.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/nutrition/log'),
        backgroundColor: t.accent,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text(
          'Log Food',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          // SliverAppBar
          SliverAppBar(
            expandedHeight: 64,
            floating: true,
            snap: true,
            pinned: false,
            backgroundColor: t.background,
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: BackButton(
              onPressed: () =>
                  context.canPop() ? context.pop() : context.go('/'),
            ),
            automaticallyImplyLeading: true,
            title: Text(
              'Nutrition',
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: t.textPrimary,
              ),
            ),
            actions: [
              Text(
                DateTime.now().dayMonth,
                style: GoogleFonts.inter(
                    fontSize: 14,
                    color: t.textMuted,
                    fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: 12),
              IconButton(
                icon: Icon(Icons.qr_code_scanner_rounded, color: t.brand),
                onPressed: () => context.push('/nutrition/scan'),
                tooltip: 'Scan barcode',
              ),
              const SizedBox(width: 4),
            ],
          ),

          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Calorie Tracker ──────────────────────────────────────────
                _CalorieTrackerSection(
                  consumed: kcalConsumed,
                  goal: _kcalGoal,
                  burned: _kcalBurned,
                  progress: gaugeProgress,
                  themeTokens: t,
                )
                    .animate()
                    .fadeIn(duration: 500.ms)
                    .slideY(begin: 0.06, end: 0),

                const SizedBox(height: 20),

                // ── Macro Progress Bars ──────────────────────────────────────
                GlassmorphicCard(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Macronutrients',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: t.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 14),
                        _MacroProgressBar(
                          label: 'Protein',
                          current: proteinCurrent,
                          goal: _proteinGoal,
                          unit: 'g',
                          color: t.info,
                          t: t,
                        ),
                        const SizedBox(height: 12),
                        _MacroProgressBar(
                          label: 'Carbs',
                          current: carbsCurrent,
                          goal: _carbsGoal,
                          unit: 'g',
                          color: t.warning,
                          t: t,
                        ),
                        const SizedBox(height: 12),
                        _MacroProgressBar(
                          label: 'Fat',
                          current: fatCurrent,
                          goal: _fatGoal,
                          unit: 'g',
                          color: t.danger,
                          t: t,
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.06, end: 0),

                const SizedBox(height: 20),

                // ── AI Meal Suggestion ───────────────────────────────────────
                GlassmorphicCard(
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        colors: [
                          t.brand.withOpacity(0.12),
                          t.brand.withOpacity(0.03),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: t.brand.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.auto_awesome_rounded,
                              color: t.brand, size: 20),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'AI Suggestion',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: t.brand,
                                  letterSpacing: 0.4,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Try: Grilled Chicken Rice Bowl',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: t.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '480 kcal · 42g P · 52g C · 8g F',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: t.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Added to log'),
                                backgroundColor: t.accent,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: t.brand,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                          ),
                          child: Text(
                            'Add to Log',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: t.brand,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(delay: 250.ms),

                const SizedBox(height: 24),

                // ── Meal Sections ────────────────────────────────────────────
                ...List.generate(mealSections.length, (index) {
                  final section = mealSections[index];
                  return _MealSectionWidget(
                    section: section,
                    themeTokens: t,
                    animDelay: 300 + index * 80,
                  );
                }),

                const SizedBox(height: 20),

                // ── Hydration Row ────────────────────────────────────────────
                GlassmorphicCard(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: t.info.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.water_drop_rounded,
                              color: t.info, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Hydration',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: t.textPrimary,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '${totalWaterMl}ml / ${waterGoalMl}ml',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: t.info,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: waterState.progressFraction,
                                  minHeight: 6,
                                  backgroundColor: t.ringTrack,
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(t.info),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () => ref
                              .read(waterTrackerProvider.notifier)
                              .logWater(250),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: t.info.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                              border:
                                  Border.all(color: t.info.withOpacity(0.3)),
                            ),
                            child: Text(
                              '+1',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: t.info,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(delay: 640.ms),

                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Calorie Tracker Section ───────────────────────────────────────────────────

class _CalorieTrackerSection extends StatelessWidget {
  final int consumed;
  final int goal;
  final int burned;
  final double progress;
  final FitNexoraThemeTokens themeTokens;

  const _CalorieTrackerSection({
    required this.consumed,
    required this.goal,
    required this.burned,
    required this.progress,
    required this.themeTokens,
  });

  @override
  Widget build(BuildContext context) {
    final t = themeTokens;
    final remaining = goal - consumed + burned;

    return GlassmorphicCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                // Circular gauge
                SizedBox(
                  width: 120,
                  height: 120,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                        size: const Size(120, 120),
                        painter: _NutritionGaugePainter(
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
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: t.textPrimary,
                              height: 1,
                            ),
                          ),
                          Text(
                            'kcal',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: t.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    children: [
                      _CalorieStat(
                          label: 'Consumed',
                          value: '$consumed',
                          unit: 'kcal',
                          color: t.brand,
                          t: t),
                      const SizedBox(height: 12),
                      _CalorieStat(
                          label: 'Remaining',
                          value: '$remaining',
                          unit: 'kcal',
                          color: t.accent,
                          t: t),
                      const SizedBox(height: 12),
                      _CalorieStat(
                          label: 'Burned',
                          value: '$burned',
                          unit: 'kcal',
                          color: t.warning,
                          t: t),
                    ],
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

class _CalorieStat extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color color;
  final FitNexoraThemeTokens t;

  const _CalorieStat({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 12, color: t.textMuted),
        ),
        const Spacer(),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: value,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              TextSpan(
                text: ' $unit',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: t.textMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Gauge painter ─────────────────────────────────────────────────────────────

class _NutritionGaugePainter extends CustomPainter {
  final double value;
  final Color trackColor;
  final Color startColor;
  final Color endColor;

  _NutritionGaugePainter({
    required this.value,
    required this.trackColor,
    required this.startColor,
    required this.endColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 10.0;
    const startAngle = -math.pi / 2;
    const sweepAngle = 2 * math.pi;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - strokeWidth / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Track
    final trackPaint = Paint()
      ..color = trackColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    canvas.drawArc(rect, startAngle, sweepAngle, false, trackPaint);

    // Progress
    if (value > 0) {
      final shader = SweepGradient(
        startAngle: startAngle,
        endAngle: startAngle + sweepAngle,
        colors: [startColor, endColor, startColor],
        stops: const [0.0, 0.6, 1.0],
        tileMode: TileMode.clamp,
      ).createShader(rect);

      final progressPaint = Paint()
        ..shader = shader
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
          rect, startAngle, sweepAngle * value, false, progressPaint);
    }
  }

  @override
  bool shouldRepaint(_NutritionGaugePainter old) => old.value != value;
}

// ── Macro Progress Bar ────────────────────────────────────────────────────────

class _MacroProgressBar extends StatelessWidget {
  final String label;
  final int current;
  final int goal;
  final String unit;
  final Color color;
  final FitNexoraThemeTokens t;

  const _MacroProgressBar({
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
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: t.textSecondary,
              ),
            ),
            const Spacer(),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '$current',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: t.textPrimary,
                    ),
                  ),
                  TextSpan(
                    text: '/$goal$unit',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: t.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 7,
            backgroundColor: t.ringTrack,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

// ── Meal Section Widget ───────────────────────────────────────────────────────

class _MealSectionWidget extends StatefulWidget {
  final _MealSection section;
  final FitNexoraThemeTokens themeTokens;
  final int animDelay;

  const _MealSectionWidget({
    required this.section,
    required this.themeTokens,
    required this.animDelay,
  });

  @override
  State<_MealSectionWidget> createState() => _MealSectionWidgetState();
}

class _MealSectionWidgetState extends State<_MealSectionWidget> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final t = widget.themeTokens;
    final section = widget.section;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassmorphicCard(
        child: Column(
          children: [
            // Section header
            InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: t.brand.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(section.icon, color: t.brand, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            section.type,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: t.textPrimary,
                            ),
                          ),
                          Text(
                            '${section.items.length} items',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: t.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: t.brand.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${section.totalKcal} kcal',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: t.brand,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    AnimatedRotation(
                      turns: _expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(Icons.keyboard_arrow_down_rounded,
                          color: t.textMuted, size: 20),
                    ),
                  ],
                ),
              ),
            ),

            // Food items horizontal scroll
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: SizedBox(
                height: 116,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                  itemCount: section.items.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final item = section.items[index];
                    return _FoodItemCard(item: item, t: t);
                  },
                ),
              ),
              crossFadeState: _expanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 250),
            ),
          ],
        ),
      )
          .animate(delay: Duration(milliseconds: widget.animDelay))
          .fadeIn()
          .slideY(begin: 0.06, end: 0),
    );
  }
}

class _FoodItemCard extends StatelessWidget {
  final _FoodItem item;
  final FitNexoraThemeTokens t;

  const _FoodItemCard({required this.item, required this.t});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: t.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: t.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.name,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: t.textPrimary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          Text(
            '${item.kcal} kcal',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: t.brand,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'P${item.protein} · C${item.carbs} · F${item.fat}',
            style: GoogleFonts.inter(fontSize: 10, color: t.textMuted),
          ),
        ],
      ),
    );
  }
}

// ── Data classes ──────────────────────────────────────────────────────────────

class _MealSection {
  final String type;
  final IconData icon;
  final int totalKcal;
  final List<_FoodItem> items;

  const _MealSection({
    required this.type,
    required this.icon,
    required this.totalKcal,
    required this.items,
  });
}

class _FoodItem {
  final String name;
  final int kcal;
  final int protein;
  final int carbs;
  final int fat;

  const _FoodItem({
    required this.name,
    required this.kcal,
    required this.protein,
    required this.carbs,
    required this.fat,
  });
}
