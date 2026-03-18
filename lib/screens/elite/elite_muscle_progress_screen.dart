import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;

import '../../core/extensions.dart';
import '../../models/progress_checkin_model.dart';
import '../../providers/elite_member_provider.dart';
import '../../widgets/glassmorphic_card.dart';

/// Elite: Muscle group progress + body fat analysis with graphs.
class EliteMuscleProgressScreen extends ConsumerWidget {
  const EliteMuscleProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.fitTheme;
    final allAsync = ref.watch(eliteMuscleProgressProvider);

    return Scaffold(
      backgroundColor: t.background,
      appBar: AppBar(
        backgroundColor: t.background,
        leading: BackButton(color: t.textSecondary),
        title: Text('Muscle & Body Progress',
            style: GoogleFonts.inter(
                fontSize: 19, fontWeight: FontWeight.w800,
                color: t.textPrimary)),
      ),
      body: allAsync.when(
        loading: () => Center(
            child: CircularProgressIndicator(color: t.brand)),
        error: (e, _) => Center(
            child: Text('$e',
                style: GoogleFonts.inter(color: t.danger))),
        data: (entries) {
          if (entries.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.fitness_center_rounded,
                      size: 56, color: t.textMuted),
                  const SizedBox(height: 16),
                  Text('No progress data yet',
                      style: GoogleFonts.inter(
                          color: t.textSecondary, fontSize: 16)),
                  const SizedBox(height: 8),
                  Text('Log measurements in Body Measurements\nto see your progress here',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                          color: t.textMuted, fontSize: 13, height: 1.5)),
                ],
              ),
            );
          }

          final weightData = entries
              .where((e) => e.weightKg != null)
              .toList();
          final fatData = entries
              .where((e) => e.bodyFatPercent != null)
              .toList();

          return CustomScrollView(
            slivers: [
              // Body Fat trend
              _header('BODY FAT % TREND'),
              if (fatData.isNotEmpty)
                SliverPadding(
                  padding:
                      const EdgeInsets.fromLTRB(20, 0, 20, 0),
                  sliver: SliverToBoxAdapter(
                    child: GlassmorphicCard(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Text('Body Fat %',
                                  style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: t.textPrimary)),
                              const Spacer(),
                              Text(
                                '${fatData.first.bodyFatPercent!.toStringAsFixed(1)}%',
                                style: GoogleFonts.inter(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: t.warning),
                              ),
                            ]),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 120,
                              child: CustomPaint(
                                size: const Size(double.infinity, 120),
                                painter: _LineChartPainter(
                                  data: fatData
                                      .reversed
                                      .map((e) => e.bodyFatPercent!)
                                      .toList(),
                                  color: t.warning,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ).animate().fadeIn(),
                  ),
                ),

              // Weight trend chart
              _header('WEIGHT TREND'),
              if (weightData.isNotEmpty)
                SliverPadding(
                  padding:
                      const EdgeInsets.fromLTRB(20, 0, 20, 0),
                  sliver: SliverToBoxAdapter(
                    child: GlassmorphicCard(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Text('Weight (kg)',
                                  style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: t.textPrimary)),
                              const Spacer(),
                              Text(
                                '${weightData.first.weightKg!.toStringAsFixed(1)} kg',
                                style: GoogleFonts.inter(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: t.brand),
                              ),
                            ]),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 120,
                              child: CustomPaint(
                                size: const Size(double.infinity, 120),
                                painter: _LineChartPainter(
                                  data: weightData
                                      .reversed
                                      .map((e) => e.weightKg!)
                                      .toList(),
                                  color: t.brand,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ).animate(delay: 80.ms).fadeIn(),
                  ),
                ),

              // Muscle group visual
              _header('MUSCLE GROUP OVERVIEW'),
              SliverPadding(
                padding:
                    const EdgeInsets.fromLTRB(20, 0, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: GlassmorphicCard(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Latest measurements',
                              style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: t.textSecondary)),
                          const SizedBox(height: 14),
                          _muscleRow('Chest', entries.first.chestCm,
                              t.brand),
                          _muscleRow('Waist', entries.first.waistCm,
                              t.danger),
                          _muscleRow('Arms', entries.first.armCm,
                              t.accent),
                          _muscleRow('Thigh', entries.first.thighCm,
                              t.info),
                          _muscleRow('Hips', entries.first.hipsCm,
                              t.warning),
                        ],
                      ),
                    ),
                  ).animate(delay: 120.ms).fadeIn(),
                ),
              ),

              // History list
              _header('CHECK-IN HISTORY'),
              SliverPadding(
                padding:
                    const EdgeInsets.fromLTRB(20, 0, 20, 40),
                sliver: SliverToBoxAdapter(
                  child: GlassmorphicCard(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        children: entries.asMap().entries.map((e) {
                          final i = e.key;
                          final m = e.value;
                          return Column(children: [
                            ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              title: Text(_fmt(m.checkInDate),
                                  style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: t.textPrimary)),
                              subtitle: Text(_buildSub(m),
                                  style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: t.textSecondary)),
                              trailing: m.weightKg != null
                                  ? Text(
                                      '${m.weightKg!.toStringAsFixed(1)} kg',
                                      style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                          color: t.brand))
                                  : null,
                            ),
                            if (i < entries.length - 1)
                              Divider(
                                  color: t.divider, height: 1),
                          ]);
                        }).toList(),
                      ),
                    ),
                  ).animate(delay: 150.ms).fadeIn(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _muscleRow(String label, double? value, Color color) {
    if (value == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Builder(builder: (ctx) {
        final tt = ctx.fitTheme;
        return Row(children: [
        SizedBox(
          width: 70,
          child: Text(label,
              style: GoogleFonts.inter(
                  fontSize: 13, color: tt.textSecondary)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (value / 120).clamp(0.0, 1.0),
              backgroundColor: color.withOpacity(0.12),
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 8,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text('${value.toStringAsFixed(1)} cm',
            style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color)),
      ]);
      }),
    );
  }

  Widget _header(String title) => SliverPadding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        sliver: SliverToBoxAdapter(
          child: Builder(builder: (ctx) {
            final tt = ctx.fitTheme;
            return Text(title,
                style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: tt.textMuted,
                    letterSpacing: 1.2));
          }),
        ),
      );

  String _buildSub(ProgressCheckIn m) {
    final parts = <String>[];
    if (m.bodyFatPercent != null) {
      parts.add('Fat:${m.bodyFatPercent!.toStringAsFixed(1)}%');
    }
    if (m.chestCm != null) {
      parts.add('Chest:${m.chestCm!.toStringAsFixed(0)}');
    }
    if (m.armCm != null) {
      parts.add('Arms:${m.armCm!.toStringAsFixed(0)}');
    }
    return parts.join(' · ');
  }

  String _fmt(DateTime d) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun',
        'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }
}

// ─── Line Chart Painter ───────────────────────────────────────────────────────

class _LineChartPainter extends CustomPainter {
  final List<double> data;
  final Color color;
  _LineChartPainter({required this.data, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;
    final min = data.reduce(math.min);
    final max = data.reduce(math.max);
    final range = (max - min).abs();
    final safeRange = range < 0.1 ? 1.0 : range;

    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withOpacity(0.25), color.withOpacity(0.0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;
    final dotPaint = Paint()..color = color;

    final points = <Offset>[];
    for (var i = 0; i < data.length; i++) {
      final x = i * (size.width / (data.length - 1));
      final y = size.height -
          ((data[i] - min) / safeRange) * (size.height - 20) - 10;
      points.add(Offset(x, y));
    }

    // Fill area
    final fillPath = Path()..moveTo(points.first.dx, size.height);
    for (final p in points) {
      fillPath.lineTo(p.dx, p.dy);
    }
    fillPath.lineTo(points.last.dx, size.height);
    fillPath.close();
    canvas.drawPath(fillPath, fillPaint);

    // Line
    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      final cp = Offset((points[i - 1].dx + points[i].dx) / 2,
          (points[i - 1].dy + points[i].dy) / 2);
      linePath.quadraticBezierTo(
          points[i - 1].dx, points[i - 1].dy, cp.dx, cp.dy);
    }
    linePath.lineTo(points.last.dx, points.last.dy);
    canvas.drawPath(linePath, linePaint);

    // Dots
    for (final p in points) {
      canvas.drawCircle(p, 4, dotPaint);
      canvas.drawCircle(
          p, 4, Paint()..color = Colors.transparent..style = PaintingStyle.stroke..strokeWidth = 2);
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter old) =>
      old.data != data;
}
