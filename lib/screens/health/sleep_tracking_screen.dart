import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/extensions.dart';
import '../../providers/health_provider.dart';
import '../../widgets/glassmorphic_card.dart';

class SleepTrackingScreen extends ConsumerStatefulWidget {
  const SleepTrackingScreen({super.key});

  @override
  ConsumerState<SleepTrackingScreen> createState() =>
      _SleepTrackingScreenState();
}

class _SleepTrackingScreenState extends ConsumerState<SleepTrackingScreen> {
  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;
    final state = ref.watch(sleepProvider);

    // Latest entry
    final latest = state.entries.isNotEmpty ? state.entries.last : null;
    final hours = latest?.hoursSlept ?? 0;
    final hh = hours.floor();
    final mm = ((hours - hh) * 60).round();
    final qualityColor = latest?.quality == 'good'
        ? t.success
        : latest?.quality == 'fair'
            ? t.warning
            : t.danger;

    final displayEntries = state.viewMode == 'week'
        ? state.entries.reversed.take(7).toList().reversed.toList()
        : state.entries.reversed.take(28).toList().reversed.toList();

    return Scaffold(
      backgroundColor: t.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showLogSheet(context),
        backgroundColor: t.brand,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.bedtime_rounded),
        label: Text('Log Sleep', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            backgroundColor: t.surface,
            title: Text(
              'Sleep Tracker',
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: t.textPrimary,
              ),
            ),
            leading: IconButton(
              icon: Icon(Icons.arrow_back_rounded, color: t.textPrimary),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),

          // Duration hero
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            sliver: SliverToBoxAdapter(
              child: GlassmorphicCard(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${hh}h ${mm}m',
                            style: GoogleFonts.inter(
                              fontSize: 48,
                              fontWeight: FontWeight.w900,
                              color: t.textPrimary,
                              letterSpacing: -2,
                            ),
                          ),
                          const SizedBox(width: 12),
                          if (latest != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 5),
                              decoration: BoxDecoration(
                                color: qualityColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: qualityColor.withOpacity(0.4)),
                              ),
                              child: Text(
                                (latest.quality).toUpperCase(),
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: qualityColor,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Last night',
                        style: GoogleFonts.inter(
                            fontSize: 13, color: t.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Stats row
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  Expanded(
                    child: _SleepStatTile(
                      label: 'Bedtime',
                      value: latest?.bedtime ?? '--',
                      icon: Icons.nights_stay_rounded,
                      color: t.info,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SleepStatTile(
                      label: 'Wake Time',
                      value: latest?.wakeTime ?? '--',
                      icon: Icons.wb_sunny_rounded,
                      color: t.warning,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SleepStatTile(
                      label: 'Deep Sleep',
                      value: '${(hours * 0.22).toStringAsFixed(1)}h',
                      icon: Icons.waves_rounded,
                      color: t.brand,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Week/Month toggle
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  _ToggleButton(
                    label: 'Week',
                    isSelected: state.viewMode == 'week',
                    onTap: () {
                      if (state.viewMode != 'week') {
                        ref.read(sleepProvider.notifier).toggleView();
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  _ToggleButton(
                    label: 'Month',
                    isSelected: state.viewMode == 'month',
                    onTap: () {
                      if (state.viewMode != 'month') {
                        ref.read(sleepProvider.notifier).toggleView();
                      }
                    },
                  ),
                ],
              ),
            ),
          ),

          // Heatmap grid
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            sliver: SliverToBoxAdapter(
              child: GlassmorphicCard(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        state.viewMode == 'week' ? 'This Week' : 'This Month',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: t.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      GridView.count(
                        crossAxisCount: 7,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 6,
                        crossAxisSpacing: 6,
                        children: displayEntries.map((entry) {
                          final cellColor = entry.hoursSlept >= 7.0
                              ? t.success
                              : entry.hoursSlept >= 6.0
                                  ? t.warning
                                  : t.danger;
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: cellColor.withOpacity(0.55),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${entry.date.day}',
                                style: GoogleFonts.inter(
                                  fontSize: 8,
                                  color: t.textMuted,
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _LegendDot(color: t.success, label: '≥7h'),
                          const SizedBox(width: 12),
                          _LegendDot(color: t.warning, label: '6-7h'),
                          const SizedBox(width: 12),
                          _LegendDot(color: t.danger, label: '<6h'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 7-day trend line chart (simplified)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            sliver: SliverToBoxAdapter(
              child: GlassmorphicCard(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '7-Day Trend',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: t.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      RepaintBoundary(
                        child: _SleepLineChart(
                          entries: state.entries.reversed.take(7).toList().reversed.toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  void _showLogSheet(BuildContext context) {
    final t = context.fitTheme;
    String bedtime = '10:30 PM';
    String wakeTime = '6:00 AM';
    String quality = 'good';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: t.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
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
                Text('Log Sleep',
                    style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: t.textPrimary)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _TimePickerTile(
                        label: 'Bedtime',
                        value: bedtime,
                        icon: Icons.nights_stay_rounded,
                        color: t.info,
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: const TimeOfDay(hour: 22, minute: 30),
                          );
                          if (picked != null) {
                            setState(() {
                              bedtime = picked.format(context);
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _TimePickerTile(
                        label: 'Wake Time',
                        value: wakeTime,
                        icon: Icons.wb_sunny_rounded,
                        color: t.warning,
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: const TimeOfDay(hour: 6, minute: 0),
                          );
                          if (picked != null) {
                            setState(() {
                              wakeTime = picked.format(context);
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text('Sleep Quality',
                    style: GoogleFonts.inter(
                        fontSize: 13, color: t.textSecondary)),
                const SizedBox(height: 8),
                Row(
                  children: ['poor', 'fair', 'good'].map((q) {
                    final isSelected = quality == q;
                    final c = q == 'good'
                        ? t.success
                        : q == 'fair'
                            ? t.warning
                            : t.danger;
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                            right: q != 'good' ? 8 : 0),
                        child: GestureDetector(
                          onTap: () => setState(() => quality = q),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? c.withOpacity(0.15)
                                  : t.surfaceAlt,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: isSelected
                                      ? c
                                      : t.border),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              q.toUpperCase()[0] +
                                  q.substring(1),
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isSelected
                                    ? c
                                    : t.textMuted,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      ref.read(sleepProvider.notifier).logSleep(
                            SleepEntry(
                              date: DateTime.now(),
                              hoursSlept: 7.5,
                              quality: quality,
                              bedtime: bedtime,
                              wakeTime: wakeTime,
                            ),
                          );
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: t.brand,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text('Save Sleep Log',
                        style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SleepStatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _SleepStatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;
    return GlassmorphicCard(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 8),
            Text(value,
                style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: t.textPrimary)),
            Text(label,
                style: GoogleFonts.inter(fontSize: 10, color: t.textMuted)),
          ],
        ),
      ),
    );
  }
}

class _ToggleButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ToggleButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? t.brand : t.surfaceAlt,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : t.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(label,
            style: GoogleFonts.inter(fontSize: 11, color: t.textMuted)),
      ],
    );
  }
}

class _TimePickerTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _TimePickerTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: t.surfaceAlt,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: t.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(height: 6),
            Text(value,
                style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: t.textPrimary)),
            Text(label,
                style:
                    GoogleFonts.inter(fontSize: 10, color: t.textMuted)),
          ],
        ),
      ),
    );
  }
}

/// Simple canvas-drawn line chart for sleep trend.
class _SleepLineChart extends StatelessWidget {
  final List<SleepEntry> entries;
  const _SleepLineChart({required this.entries});

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;
    return SizedBox(
      height: 80,
      child: CustomPaint(
        size: const Size(double.infinity, 80),
        painter: _LinePainter(entries: entries, lineColor: t.brand, gridColor: t.ringTrack),
      ),
    );
  }
}

class _LinePainter extends CustomPainter {
  final List<SleepEntry> entries;
  final Color lineColor;
  final Color gridColor;

  _LinePainter({
    required this.entries,
    required this.lineColor,
    required this.gridColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (entries.isEmpty) return;

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;

    // Draw horizontal grid lines
    for (var i = 0; i <= 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final maxH = 10.0;
    final minH = 4.0;

    final points = List.generate(entries.length, (i) {
      final x = i / (entries.length - 1).clamp(1, entries.length) * size.width;
      final normalised = (entries[i].hoursSlept - minH) / (maxH - minH);
      final y = size.height * (1 - normalised.clamp(0.0, 1.0));
      return Offset(x, y);
    });

    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    if (points.isNotEmpty) {
      path.moveTo(points.first.dx, points.first.dy);
      for (var i = 1; i < points.length; i++) {
        final prev = points[i - 1];
        final curr = points[i];
        final cpX = (prev.dx + curr.dx) / 2;
        path.cubicTo(cpX, prev.dy, cpX, curr.dy, curr.dx, curr.dy);
      }
    }
    canvas.drawPath(path, linePaint);

    // Dot on each data point
    final dotPaint = Paint()..color = lineColor;
    for (final p in points) {
      canvas.drawCircle(p, 3, dotPaint);
    }
  }

  @override
  bool shouldRepaint(_LinePainter old) => old.entries != entries;
}
