import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/extensions.dart';
import '../../config/theme.dart';
import '../../widgets/glassmorphic_card.dart';

class DailyCalorieGoalScreen extends ConsumerStatefulWidget {
  const DailyCalorieGoalScreen({super.key});

  @override
  ConsumerState<DailyCalorieGoalScreen> createState() =>
      _DailyCalorieGoalScreenState();
}

class _DailyCalorieGoalScreenState
    extends ConsumerState<DailyCalorieGoalScreen> {
  DateTime _selectedDate = DateTime.now();
  int _filledWater = 5; // out of 8

  // Mock data
  static const int _caloriesGoal = 2200;
  static const int _caloriesConsumed = 1480;
  static const int _caloriesRemaining = _caloriesGoal - _caloriesConsumed;

  static const int _proteinGoal = 180;
  static const int _proteinCurrent = 118;
  static const int _carbsGoal = 280;
  static const int _carbsCurrent = 190;
  static const int _fatGoal = 73;
  static const int _fatCurrent = 52;

  static const int _hydrationGoal = 2500;
  static const int _hydrationPerDrop = 312; // 2500 / 8

  void _changeDate(int delta) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: delta));
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;
    final progress = _caloriesConsumed / _caloriesGoal;

    return Scaffold(
      backgroundColor: t.background,
      appBar: AppBar(
        backgroundColor: t.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded,
              color: t.textPrimary, size: 20),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: _DateSelector(
          date: _selectedDate,
          onPrev: () => _changeDate(-1),
          onNext: () => _changeDate(1),
          themeTokens: t,
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.tune_rounded, color: t.textSecondary),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Circular Gauge
            Center(
              child: _CalorieGaugeWidget(
                consumed: _caloriesConsumed,
                goal: _caloriesGoal,
                remaining: _caloriesRemaining,
                progress: progress,
                themeTokens: t,
              ),
            ).animate().fadeIn(duration: 600.ms).scale(
                  begin: const Offset(0.9, 0.9),
                  end: const Offset(1, 1),
                  curve: Curves.easeOutBack,
                ),

            const SizedBox(height: 28),

            // Macro cards row
            Row(
              children: [
                Expanded(
                  child: _MacroCard(
                    label: 'Protein',
                    current: _proteinCurrent,
                    goal: _proteinGoal,
                    unit: 'g',
                    color: t.info,
                    themeTokens: t,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MacroCard(
                    label: 'Carbs',
                    current: _carbsCurrent,
                    goal: _carbsGoal,
                    unit: 'g',
                    color: t.warning,
                    themeTokens: t,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MacroCard(
                    label: 'Fats',
                    current: _fatCurrent,
                    goal: _fatGoal,
                    unit: 'g',
                    color: t.danger,
                    themeTokens: t,
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.08, end: 0),

            const SizedBox(height: 20),

            // AI Insight Card
            GlassmorphicCard(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    colors: [
                      t.brand.withValues(alpha: 0.12),
                      t.brand.withValues(alpha: 0.04),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: t.brand.withValues(alpha: 0.15),
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
                            'AI Insight',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: t.brand,
                              letterSpacing: 0.4,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'You\'re 65% of the way to your protein goal. '
                            'Add a protein shake or grilled chicken to hit your target tonight.',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: t.textSecondary,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 320.ms),

            const SizedBox(height: 20),

            // Hydration Tracker
            GlassmorphicCard(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.water_drop_rounded,
                            color: t.info, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Hydration',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: t.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${_filledWater * _hydrationPerDrop}ml / ${_hydrationGoal}ml',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: t.info,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(8, (index) {
                        final filled = index < _filledWater;
                        return GestureDetector(
                          onTap: () => setState(() {
                            _filledWater =
                                _filledWater == index + 1 ? index : index + 1;
                          }),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            width: 34,
                            height: 44,
                            decoration: BoxDecoration(
                              color: filled
                                  ? t.info.withValues(alpha: 0.15)
                                  : t.surfaceAlt,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: filled
                                    ? t.info.withValues(alpha: 0.5)
                                    : t.border,
                              ),
                            ),
                            child: Icon(
                              filled
                                  ? Icons.water_drop_rounded
                                  : Icons.water_drop_outlined,
                              color: filled
                                  ? t.info
                                  : t.textMuted.withValues(alpha: 0.4),
                              size: 18,
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: _filledWater / 8,
                        minHeight: 6,
                        backgroundColor: t.ringTrack,
                        valueColor: AlwaysStoppedAnimation<Color>(t.info),
                      ),
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 420.ms).slideY(begin: 0.06, end: 0),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

// ── Date Selector ─────────────────────────────────────────────────────────────

class _DateSelector extends StatelessWidget {
  final DateTime date;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final FitNexoraThemeTokens themeTokens;

  const _DateSelector({
    required this.date,
    required this.onPrev,
    required this.onNext,
    required this.themeTokens,
  });

  @override
  Widget build(BuildContext context) {
    final t = themeTokens;
    final isToday = date.day == DateTime.now().day &&
        date.month == DateTime.now().month &&
        date.year == DateTime.now().year;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(Icons.chevron_left_rounded, color: t.textSecondary),
          onPressed: onPrev,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          padding: EdgeInsets.zero,
        ),
        Column(
          children: [
            Text(
              isToday ? 'Today' : date.dayMonth,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: t.textPrimary,
              ),
            ),
            if (!isToday)
              Text(
                date.formatted,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: t.textMuted,
                ),
              ),
          ],
        ),
        IconButton(
          icon: Icon(Icons.chevron_right_rounded, color: t.textSecondary),
          onPressed: onNext,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          padding: EdgeInsets.zero,
        ),
      ],
    );
  }
}

// ── Calorie Gauge ─────────────────────────────────────────────────────────────

class _CalorieGaugeWidget extends StatelessWidget {
  final int consumed;
  final int goal;
  final int remaining;
  final double progress;
  final FitNexoraThemeTokens themeTokens;

  const _CalorieGaugeWidget({
    required this.consumed,
    required this.goal,
    required this.remaining,
    required this.progress,
    required this.themeTokens,
  });

  @override
  Widget build(BuildContext context) {
    final t = themeTokens;
    return Column(
      children: [
        SizedBox(
          width: 220,
          height: 220,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size(220, 220),
                painter: _CalorieGaugePainter(
                  value: progress.clamp(0.0, 1.0),
                  trackColor: t.ringTrack,
                  startColor: t.brand,
                  endColor: t.accent,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$remaining',
                    style: GoogleFonts.inter(
                      fontSize: 42,
                      fontWeight: FontWeight.w900,
                      color: t.textPrimary,
                      height: 1,
                    ),
                  ),
                  Text(
                    'kcal remaining',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: t.textMuted,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: t.accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${(progress * 100).round()}% consumed',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: t.accent,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _GaugeStat(
              label: 'Consumed',
              value: '$consumed',
              unit: 'kcal',
              color: t.brand,
              t: t,
            ),
            Container(
              width: 1,
              height: 32,
              margin: const EdgeInsets.symmetric(horizontal: 20),
              color: t.divider,
            ),
            _GaugeStat(
              label: 'Goal',
              value: '$goal',
              unit: 'kcal',
              color: t.textSecondary,
              t: t,
            ),
            Container(
              width: 1,
              height: 32,
              margin: const EdgeInsets.symmetric(horizontal: 20),
              color: t.divider,
            ),
            _GaugeStat(
              label: 'Burned',
              value: '320',
              unit: 'kcal',
              color: t.accent,
              t: t,
            ),
          ],
        ),
      ],
    );
  }
}

class _GaugeStat extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color color;
  final FitNexoraThemeTokens t;

  const _GaugeStat({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: value,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
              TextSpan(
                text: ' $unit',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: t.textMuted,
                ),
              ),
            ],
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: t.textMuted,
          ),
        ),
      ],
    );
  }
}

class _CalorieGaugePainter extends CustomPainter {
  final double value;
  final Color trackColor;
  final Color startColor;
  final Color endColor;

  _CalorieGaugePainter({
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

    // Progress gradient arc
    if (value > 0) {
      final progressSweep = sweepAngle * value;

      final shader = SweepGradient(
        startAngle: startAngle,
        endAngle: startAngle + sweepAngle,
        colors: [startColor, endColor],
        tileMode: TileMode.clamp,
      ).createShader(rect);

      final progressPaint = Paint()
        ..shader = shader
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(rect, startAngle, progressSweep, false, progressPaint);

      // Glow dot at end of arc
      final endAngle = startAngle + progressSweep;
      final dotX = center.dx + radius * math.cos(endAngle);
      final dotY = center.dy + radius * math.sin(endAngle);

      final glowPaint = Paint()
        ..color = endColor.withValues(alpha: 0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(Offset(dotX, dotY), strokeWidth / 2 + 2, glowPaint);

      final dotPaint = Paint()..color = endColor;
      canvas.drawCircle(Offset(dotX, dotY), strokeWidth / 2, dotPaint);
    }
  }

  @override
  bool shouldRepaint(_CalorieGaugePainter old) =>
      old.value != value || old.startColor != startColor;
}

// ── Macro Card ────────────────────────────────────────────────────────────────

class _MacroCard extends StatelessWidget {
  final String label;
  final int current;
  final int goal;
  final String unit;
  final Color color;
  final FitNexoraThemeTokens themeTokens;

  const _MacroCard({
    required this.label,
    required this.current,
    required this.goal,
    required this.unit,
    required this.color,
    required this.themeTokens,
  });

  @override
  Widget build(BuildContext context) {
    final t = themeTokens;
    final progress = (current / goal).clamp(0.0, 1.0);

    return GlassmorphicCard(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  label[0],
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: t.textMuted,
              ),
            ),
            const SizedBox(height: 2),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '$current',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: t.textPrimary,
                    ),
                  ),
                  TextSpan(
                    text: '/$goal$unit',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: t.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 5,
                backgroundColor: t.ringTrack,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
