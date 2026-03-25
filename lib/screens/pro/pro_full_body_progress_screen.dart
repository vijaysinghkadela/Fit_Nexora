import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/extensions.dart';
import '../../models/progress_checkin_model.dart';
import '../../providers/pro_member_provider.dart';
import '../../widgets/glassmorphic_card.dart';
import '../pro/pro_paywall_screen.dart';

class ProFullBodyProgressScreen extends ConsumerWidget {
  const ProFullBodyProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.fitTheme;
    final proAccessAsync = ref.watch(memberHasProAccessProvider);

    return proAccessAsync.when(
      loading: () => Scaffold(
        backgroundColor: t.background,
        body: Center(child: CircularProgressIndicator(color: t.brand)),
      ),
      error: (_, __) => const ProPaywallScreen(),
      data: (hasPro) {
        if (!hasPro) return const ProPaywallScreen();

        final planAsync = ref.watch(proLatestAiPlanProvider);
        final measurementsAsync = ref.watch(proAllMeasurementsProvider);

        return Scaffold(
          backgroundColor: t.background,
          appBar: AppBar(
            backgroundColor: t.background,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_rounded, color: t.textSecondary),
              onPressed: () =>
                  context.canPop() ? context.pop() : context.go('/pro'),
            ),
            title: Text(
              'Full-Body Progress',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: t.textPrimary,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => context.push('/pro/ai?step=1'),
                child: Text(
                  'Edit Profile',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: t.brand,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: planAsync.when(
            loading: () =>
                Center(child: CircularProgressIndicator(color: t.brand)),
            error: (error, _) => Center(
              child: Text(
                '$error',
                style: GoogleFonts.inter(color: t.danger),
              ),
            ),
            data: (plan) => measurementsAsync.when(
              loading: () =>
                  Center(child: CircularProgressIndicator(color: t.brand)),
              error: (error, _) => Center(
                child: Text(
                  '$error',
                  style: GoogleFonts.inter(color: t.danger),
                ),
              ),
              data: (measurements) {
                if (plan == null) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.auto_awesome_rounded,
                              size: 56, color: t.textMuted),
                          const SizedBox(height: 16),
                          Text(
                            'No AI plan generated yet',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: t.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Generate a Pro AI plan first to see body analysis, reasoning, workout, diet, and measurement context in one place.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: t.textSecondary,
                              height: 1.55,
                            ),
                          ),
                          const SizedBox(height: 18),
                          FilledButton.icon(
                            onPressed: () => context.push('/pro/ai'),
                            icon: const Icon(Icons.auto_awesome_rounded),
                            label: const Text('Open Pro AI'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final weightSeries = measurements
                    .where((item) => item.weightKg != null)
                    .map((item) => item.weightKg!)
                    .toList()
                    .reversed
                    .toList();
                final fatSeries = measurements
                    .where((item) => item.bodyFatPercent != null)
                    .map((item) => item.bodyFatPercent!)
                    .toList()
                    .reversed
                    .toList();

                return ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  children: [
                    _Card(
                      title: plan.planName ?? 'AI Pro Plan',
                      children: [
                        _Metric('Tier', plan.planTier.toUpperCase()),
                        _Metric('Model', plan.modelUsed),
                        if (plan.tokensUsed != null)
                          _Metric('Tokens', '${plan.tokensUsed}'),
                        if ((plan.planDescription ?? '').trim().isNotEmpty)
                          Text(
                            plan.planDescription!,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: t.textSecondary,
                              height: 1.5,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _Card(
                      title: 'Monthly Report Highlights',
                      children: _monthlyReportChildren(context, plan),
                    ),
                    const SizedBox(height: 12),
                    _Card(
                      title: 'AI Analysis Snapshot',
                      children: [
                        _Metric('Somatotype',
                            '${plan.bodyAnalysis?['somatotype'] ?? '—'}'),
                        _Metric('BMI Category',
                            '${plan.bodyAnalysis?['bmi_category'] ?? '—'}'),
                        _Metric('Recommended Focus',
                            '${plan.bodyAnalysis?['recommended_focus'] ?? '—'}'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _Card(
                      title: 'Workout + Diet Summary',
                      children: [
                        _Metric('Workout Structure',
                            '${plan.workoutPlan?['weekly_structure'] ?? '—'}'),
                        _Metric('Workout Progression',
                            '${plan.workoutPlan?['progression_logic'] ?? '—'}'),
                        _Metric('Calorie Target',
                            '${plan.dietPlan?['calorie_target'] ?? '—'} kcal'),
                        _Metric('Protein Target',
                            '${plan.dietPlan?['protein_g'] ?? '—'} g'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _Card(
                      title: 'Reasoning Summary',
                      children: [
                        Text(
                          _truncate(plan.reasoningContent ??
                              'No reasoning trace returned.'),
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: t.textSecondary,
                            height: 1.55,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _Card(
                      title: 'Generated Tips',
                      children: _tipChildren(context, plan),
                    ),
                    const SizedBox(height: 12),
                    _Card(
                      title: 'Measurement Trends',
                      children: [
                        if (weightSeries.isNotEmpty)
                          _TrendChart(
                              label: 'Weight',
                              unit: 'kg',
                              values: weightSeries),
                        if (fatSeries.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          _TrendChart(
                              label: 'Body Fat', unit: '%', values: fatSeries),
                        ],
                        if (weightSeries.isEmpty && fatSeries.isEmpty)
                          Text(
                            'Log measurements to enrich the full-body progress view.',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: t.textSecondary,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _Card(
                      title: 'Latest Measurement Context',
                      children: [
                        if (measurements.isNotEmpty)
                          ..._latestMeasurementRows(measurements.first)
                        else
                          Text(
                            'No measurement entries yet.',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: t.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  List<Widget> _monthlyReportChildren(
    BuildContext context,
    dynamic plan,
  ) {
    final report = plan.monthlyReport ?? const <String, dynamic>{};
    final highlights = <String>[
      ..._stringList(report['highlights']),
      ..._stringList(report['summary_points']),
      ..._stringList(report['wins']),
      ..._stringList(report['improvements']),
    ].where((item) => item.trim().isNotEmpty).toSet().take(4).toList();

    if (highlights.isEmpty) {
      return [
        Text(
          'The latest AI report did not return a dedicated highlight list.',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: context.fitTheme.textSecondary,
          ),
        ),
      ];
    }

    return highlights
        .map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Icon(
                    Icons.bolt_rounded,
                    size: 14,
                    color: context.fitTheme.brand,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: context.fitTheme.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        )
        .toList();
  }

  List<Widget> _tipChildren(BuildContext context, dynamic plan) {
    final tips =
        plan.tips.where((tip) => tip.trim().isNotEmpty).take(4).toList();
    if (tips.isEmpty) {
      return [
        Text(
          'No additional coach tips were returned on the latest run.',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: context.fitTheme.textSecondary,
          ),
        ),
      ];
    }

    return tips
        .map(
          (tip) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Icon(
                    Icons.check_circle_outline_rounded,
                    size: 14,
                    color: context.fitTheme.success,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    tip,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: context.fitTheme.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        )
        .toList();
  }

  List<String> _stringList(dynamic value) {
    if (value is List) {
      return value.map((item) => item.toString()).toList();
    }
    return const [];
  }

  List<Widget> _latestMeasurementRows(ProgressCheckIn measurement) {
    final rows = <Widget>[];
    if (measurement.weightKg != null) {
      rows.add(
          _Metric('Weight', '${measurement.weightKg!.toStringAsFixed(1)} kg'));
    }
    if (measurement.bodyFatPercent != null) {
      rows.add(_Metric(
          'Body Fat', '${measurement.bodyFatPercent!.toStringAsFixed(1)} %'));
    }
    if (measurement.chestCm != null) {
      rows.add(
          _Metric('Chest', '${measurement.chestCm!.toStringAsFixed(1)} cm'));
    }
    if (measurement.waistCm != null) {
      rows.add(
          _Metric('Waist', '${measurement.waistCm!.toStringAsFixed(1)} cm'));
    }
    if (measurement.armCm != null) {
      rows.add(_Metric('Arms', '${measurement.armCm!.toStringAsFixed(1)} cm'));
    }
    return rows;
  }

  String _truncate(String value) {
    final normalized = value.trim();
    if (normalized.length <= 900) return normalized;
    return '${normalized.substring(0, 900).trim()}...';
  }
}

class _Card extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _Card({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return GlassmorphicCard(
      borderRadius: 24,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: context.fitTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    ).animate().fadeIn(duration: 220.ms).slideY(begin: 0.03);
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;

  const _Metric(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: GoogleFonts.inter(
                    fontSize: 12, color: context.fitTheme.textSecondary)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: context.fitTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendChart extends StatelessWidget {
  final String label;
  final String unit;
  final List<double> values;

  const _TrendChart({
    required this.label,
    required this.unit,
    required this.values,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label Trend',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: context.fitTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 110,
          child: RepaintBoundary(
            child: CustomPaint(
              painter: _LinePainter(
                values: values,
                color: context.fitTheme.brand,
              ),
              child: Align(
                alignment: Alignment.topRight,
                child: Text(
                  '${values.last.toStringAsFixed(1)} $unit',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: context.fitTheme.brand,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LinePainter extends CustomPainter {
  final List<double> values;
  final Color color;

  const _LinePainter({
    required this.values,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final minValue = values.reduce(math.min);
    final maxValue = values.reduce(math.max);
    final range = maxValue - minValue == 0 ? 1.0 : maxValue - minValue;

    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = (i / (values.length - 1)) * size.width;
      final y = size.height - ((values[i] - minValue) / range) * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _LinePainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.color != color;
  }
}
