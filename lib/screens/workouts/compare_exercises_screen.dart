import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/theme.dart';
import '../../core/extensions.dart';
import '../../widgets/glassmorphic_card.dart';

class CompareExercisesScreen extends ConsumerStatefulWidget {
  const CompareExercisesScreen({super.key});

  @override
  ConsumerState<CompareExercisesScreen> createState() => _CompareExercisesScreenState();
}

class _CompareExercisesScreenState extends ConsumerState<CompareExercisesScreen> {
  String _exercise1 = 'Bench Press';
  String _exercise2 = 'Overhead Press';

  final _metrics = const [
    _Metric(label: 'Max Weight', val1: '90 kg', val2: '70 kg', raw1: 90, raw2: 70),
    _Metric(label: 'Best Reps', val1: '8', val2: '10', raw1: 8, raw2: 10),
    _Metric(label: 'Total Volume', val1: '14,400', val2: '9,800', raw1: 14400, raw2: 9800),
    _Metric(label: 'Frequency/wk', val1: '2.1×', val2: '1.8×', raw1: 2.1, raw2: 1.8),
  ];

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;
    return Scaffold(
      backgroundColor: t.background,
      appBar: AppBar(
        backgroundColor: t.surface,
        title: Text('Compare Exercises', style: Theme.of(context).textTheme.titleLarge),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Exercise selectors
            Row(
              children: [
                Expanded(child: _ExerciseSelector(
                  label: 'Exercise A',
                  value: _exercise1,
                  color: t.brand,
                  onChanged: (v) => setState(() => _exercise1 = v),
                )),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text('VS', style: GoogleFonts.inter(
                    fontSize: 14, fontWeight: FontWeight.w900, color: t.textMuted)),
                ),
                Expanded(child: _ExerciseSelector(
                  label: 'Exercise B',
                  value: _exercise2,
                  color: t.accent,
                  onChanged: (v) => setState(() => _exercise2 = v),
                )),
              ],
            ).animate().fadeIn(duration: 350.ms),
            const SizedBox(height: 20),

            // Legend
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _LegendItem(color: t.brand, label: _exercise1),
                const SizedBox(width: 20),
                _LegendItem(color: t.accent, label: _exercise2),
              ],
            ),
            const SizedBox(height: 20),

            // Bar chart
            GlassmorphicCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Volume Comparison (last 4 weeks)',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 180,
                      child: BarChart(
                        BarChartData(
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            getDrawingHorizontalLine: (_) => FlLine(color: t.border, strokeWidth: 1),
                          ),
                          titlesData: FlTitlesData(
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (v, _) {
                                  const weeks = ['Wk 1', 'Wk 2', 'Wk 3', 'Wk 4'];
                                  final i = v.toInt();
                                  if (i < 0 || i >= weeks.length) return const SizedBox();
                                  return Text(weeks[i], style: GoogleFonts.inter(
                                    fontSize: 11, color: t.textMuted));
                                },
                              ),
                            ),
                            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          ),
                          borderData: FlBorderData(show: false),
                          barGroups: List.generate(4, (i) {
                            final vals1 = [3200.0, 3600.0, 3400.0, 3800.0];
                            final vals2 = [2400.0, 2600.0, 2800.0, 2900.0];
                            return BarChartGroupData(x: i, barRods: [
                              BarChartRodData(toY: vals1[i], color: t.brand, width: 14,
                                borderRadius: BorderRadius.circular(4)),
                              BarChartRodData(toY: vals2[i], color: t.accent, width: 14,
                                borderRadius: BorderRadius.circular(4)),
                            ], barsSpace: 4);
                          }),
                          groupsSpace: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(duration: 450.ms, delay: 100.ms),
            const SizedBox(height: 16),

            // Metrics comparison table
            Text('Key Metrics', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            GlassmorphicCard(
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Column(
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: Row(
                        children: [
                          Expanded(child: Text('Metric',
                              style: GoogleFonts.inter(fontSize: 12, color: t.textMuted, fontWeight: FontWeight.w600))),
                          SizedBox(width: 80, child: Text(_exercise1,
                              style: GoogleFonts.inter(fontSize: 11, color: t.brand, fontWeight: FontWeight.w700),
                              textAlign: TextAlign.center, overflow: TextOverflow.ellipsis)),
                          SizedBox(width: 80, child: Text(_exercise2,
                              style: GoogleFonts.inter(fontSize: 11, color: t.accent, fontWeight: FontWeight.w700),
                              textAlign: TextAlign.center, overflow: TextOverflow.ellipsis)),
                        ],
                      ),
                    ),
                    Divider(color: t.divider, height: 1),
                    ..._metrics.map((m) => Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              Expanded(child: Text(m.label,
                                  style: GoogleFonts.inter(fontSize: 13, color: t.textSecondary))),
                              SizedBox(width: 80, child: Text(m.val1,
                                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700,
                                      color: m.raw1 >= m.raw2 ? t.brand : t.textPrimary),
                                  textAlign: TextAlign.center)),
                              SizedBox(width: 80, child: Text(m.val2,
                                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700,
                                      color: m.raw2 > m.raw1 ? t.accent : t.textPrimary),
                                  textAlign: TextAlign.center)),
                            ],
                          ),
                        ),
                        Divider(color: t.divider.withOpacity(0.5), height: 1),
                      ],
                    )),
                  ],
                ),
              ),
            ).animate().fadeIn(duration: 500.ms, delay: 200.ms),
          ],
        ),
      ),
    );
  }
}

class _ExerciseSelector extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final ValueChanged<String> onChanged;
  const _ExerciseSelector({
    required this.label, required this.value, required this.color, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;
    return GlassmorphicCard(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: GoogleFonts.inter(fontSize: 11, color: t.textMuted)),
            const SizedBox(height: 6),
            Row(
              children: [
                Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Expanded(child: Text(value, style: GoogleFonts.inter(
                  fontSize: 13, fontWeight: FontWeight.w700, color: t.textPrimary),
                  overflow: TextOverflow.ellipsis)),
                Icon(Icons.expand_more_rounded, color: t.textMuted, size: 16),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 6),
        Text(label, style: GoogleFonts.inter(
          fontSize: 12, color: Theme.of(context).extension<FitNexoraThemeTokens>()!.textSecondary),
          overflow: TextOverflow.ellipsis),
      ],
    );
  }
}

class _Metric {
  final String label, val1, val2;
  final double raw1, raw2;
  const _Metric({required this.label, required this.val1, required this.val2, required this.raw1, required this.raw2});
}
