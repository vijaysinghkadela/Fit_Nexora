import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/extensions.dart';
import '../../widgets/glassmorphic_card.dart';

/// Exercise progress chart screen with fl_chart line chart.
/// Route: `/workout/exercise-progress`
class ExerciseProgressScreen extends ConsumerStatefulWidget {
  const ExerciseProgressScreen({super.key});

  @override
  ConsumerState<ExerciseProgressScreen> createState() =>
      _ExerciseProgressScreenState();
}

class _ExerciseProgressScreenState
    extends ConsumerState<ExerciseProgressScreen> {
  String _selectedPeriod = '1M';
  final List<String> _periods = ['1W', '1M', '3M', 'All'];

  // Sample data for different periods
  final Map<String, List<FlSpot>> _periodData = {
    '1W': [
      const FlSpot(0, 77.5),
      const FlSpot(1, 77.5),
      const FlSpot(2, 80.0),
      const FlSpot(3, 80.0),
      const FlSpot(4, 80.0),
      const FlSpot(5, 82.5),
      const FlSpot(6, 82.5),
    ],
    '1M': [
      const FlSpot(0, 72.5),
      const FlSpot(1, 75.0),
      const FlSpot(2, 75.0),
      const FlSpot(3, 77.5),
      const FlSpot(4, 77.5),
      const FlSpot(5, 77.5),
      const FlSpot(6, 80.0),
      const FlSpot(7, 80.0),
      const FlSpot(8, 82.5),
      const FlSpot(9, 82.5),
    ],
    '3M': [
      const FlSpot(0, 62.5),
      const FlSpot(2, 65.0),
      const FlSpot(4, 67.5),
      const FlSpot(6, 70.0),
      const FlSpot(8, 70.0),
      const FlSpot(10, 72.5),
      const FlSpot(12, 75.0),
    ],
    'All': [
      const FlSpot(0, 50.0),
      const FlSpot(3, 55.0),
      const FlSpot(6, 60.0),
      const FlSpot(9, 65.0),
      const FlSpot(12, 70.0),
      const FlSpot(15, 75.0),
      const FlSpot(18, 80.0),
      const FlSpot(20, 82.5),
    ],
  };

  List<FlSpot> get _currentData => _periodData[_selectedPeriod] ?? [];

  double get _maxY {
    if (_currentData.isEmpty) return 100;
    return (_currentData.map((s) => s.y).reduce((a, b) => a > b ? a : b) + 10)
        .ceilToDouble();
  }

  double get _minY {
    if (_currentData.isEmpty) return 0;
    return (_currentData.map((s) => s.y).reduce((a, b) => a < b ? a : b) - 10)
        .floorToDouble();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;

    return Scaffold(
      backgroundColor: t.background,
      body: CustomScrollView(
        slivers: [
          // ── App Bar ────────────────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            backgroundColor: t.surface,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_rounded, color: t.textPrimary),
              onPressed: () => Navigator.maybePop(context),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Barbell Bench Press',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: t.textPrimary,
                  ),
                ),
                Text(
                  'Progress over time',
                  style: GoogleFonts.inter(
                      fontSize: 11, color: t.textSecondary),
                ),
              ],
            ),
            actions: [
              // PR Badge
              Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFFFD700),
                      Color(0xFFFFA500),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFD700).withOpacity(0.3),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.emoji_events_rounded,
                        color: Colors.white, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      'PR 82.5 kg',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Period Tabs ─────────────────────────────────────────
                GlassmorphicCard(
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: _periods.map((p) {
                        final isSelected = _selectedPeriod == p;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _selectedPeriod = p),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected ? t.brand : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                p,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected
                                      ? Colors.white
                                      : t.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ).animate().fadeIn(duration: 400.ms),

                const SizedBox(height: 16),

                // ── Line Chart ────────────────────────────────────────────
                GlassmorphicCard(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 20, 12),
                    child: RepaintBoundary(
                      child: SizedBox(
                      height: 220,
                      child: LineChart(
                        LineChartData(
                          minY: _minY,
                          maxY: _maxY,
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            horizontalInterval: 10,
                            getDrawingHorizontalLine: (value) => FlLine(
                              color: t.border.withOpacity(0.5),
                              strokeWidth: 1,
                              dashArray: [4, 4],
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 40,
                                interval: 10,
                                getTitlesWidget: (val, meta) => Text(
                                  '${val.toInt()}kg',
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: t.textMuted,
                                  ),
                                ),
                              ),
                            ),
                            bottomTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
                          lineTouchData: LineTouchData(
                            touchTooltipData: LineTouchTooltipData(
                              getTooltipColor: (_) => t.surfaceAlt,
                              getTooltipItems: (touchedSpots) {
                                return touchedSpots
                                    .map((s) => LineTooltipItem(
                                          '${s.y} kg',
                                          GoogleFonts.inter(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: t.brand,
                                          ),
                                        ))
                                    .toList();
                              },
                            ),
                          ),
                          lineBarsData: [
                            LineChartBarData(
                              spots: _currentData,
                              isCurved: true,
                              curveSmoothness: 0.3,
                              color: t.brand,
                              barWidth: 2.5,
                              isStrokeCapRound: true,
                              dotData: FlDotData(
                                show: true,
                                getDotPainter: (spot, percent, bar, index) {
                                  final isLast =
                                      index == _currentData.length - 1;
                                  return FlDotCirclePainter(
                                    radius: isLast ? 5 : 3,
                                    color: isLast ? t.accent : t.brand,
                                    strokeWidth: isLast ? 2 : 0,
                                    strokeColor: Colors.white,
                                  );
                                },
                              ),
                              belowBarData: BarAreaData(
                                show: true,
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    t.brand.withOpacity(0.2),
                                    t.brand.withOpacity(0.0),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    ),
                  ),
                ).animate(delay: 100.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1),

                const SizedBox(height: 16),

                // ── Stats Row ─────────────────────────────────────────────
                Row(
                  children: [
                    const Expanded(
                      child: _ProgressStatCard(
                        label: 'Best Weight',
                        value: '82.5 kg',
                        icon: Icons.emoji_events_rounded,
                        color: Color(0xFFFFD700),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ProgressStatCard(
                        label: 'Best Reps',
                        value: '12',
                        icon: Icons.repeat_rounded,
                        color: t.info,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ProgressStatCard(
                        label: 'Total Sets',
                        value: '142',
                        icon: Icons.layers_rounded,
                        color: t.accent,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ProgressStatCard(
                        label: 'Improvement',
                        value: '+32%',
                        icon: Icons.trending_up_rounded,
                        color: t.brand,
                      ),
                    ),
                  ],
                ).animate(delay: 200.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1),

                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _ProgressStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: t.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 9, color: t.textMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
