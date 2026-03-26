import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import '../../core/extensions.dart';
import '../../models/progress_checkin_model.dart';
import '../../providers/master_member_provider.dart';
import '../../providers/pro_member_provider.dart';
import '../../widgets/glassmorphic_card.dart';

/// Master: Advanced Analytics Dashboard — deep performance metrics.
class MasterAnalyticsScreen extends ConsumerWidget {
  const MasterAnalyticsScreen({super.key});

  static const _masterPrimary = Color(0xFFE84F00);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(masterAnalyticsProvider);
    final nutritionAsync = ref.watch(proWeeklyCaloriesProvider);
    final t = context.fitTheme;

    return Scaffold(
      backgroundColor: t.background,
      appBar: AppBar(
        backgroundColor: t.background,
        leading: BackButton(color: t.textSecondary),
        title: Text('Advanced Analytics',
            style: GoogleFonts.inter(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: t.textPrimary)),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(masterAnalyticsProvider);
          // Optional: also invalidate nutrition provider if we want everything to refresh
          ref.invalidate(proWeeklyCaloriesProvider);
        },
        backgroundColor: t.surfaceAlt,
        color: t.accent,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // ─── Weekly calorie chart
            _hdr(context, 'WEEKLY CALORIES'),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverToBoxAdapter(
                child: nutritionAsync.when(
                  loading: () => _shimmer(context, 140),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (daySummaries) {
                    final data = daySummaries.map((d) => d.kcal).toList();
                    final avg = data.isEmpty
                        ? 0
                        : (data.reduce((a, b) => a + b) / data.length).round();
                    return GlassmorphicCard(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Text('7-Day Intake',
                                    style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: t.textPrimary)),
                                const Spacer(),
                                Text('avg $avg kcal',
                                    style: GoogleFonts.inter(
                                        fontSize: 12, color: t.textSecondary)),
                              ]),
                              const SizedBox(height: 14),
                              RepaintBoundary(
                                child: SizedBox(
                                  height: 120,
                                  child: _BarChart(
                                      values: data, color: _masterPrimary),
                                ),
                              ),
                            ]),
                      ),
                    ).animate().fadeIn();
                  },
                ),
              ),
            ),

            // ─── Body composition summary
            _hdr(context, 'BODY COMPOSITION'),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverToBoxAdapter(
                child: analyticsAsync.when(
                  loading: () => _shimmer(context, 120),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (entries) => _BodyCompositionCard(entries: entries),
                ),
              ),
            ),

            // ─── Performance metrics
            _hdr(context, 'PERFORMANCE METRICS'),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverToBoxAdapter(
                child: analyticsAsync.when(
                  loading: () => _shimmer(context, 200),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (entries) => _MetricsGrid(entries: entries),
                ),
              ),
            ),

            // ─── Progress trend (weight over time)
            _hdr(context, 'WEIGHT TREND (ALL TIME)'),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
              sliver: SliverToBoxAdapter(
                child: analyticsAsync.when(
                  loading: () => _shimmer(context, 160),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (entries) {
                    final pts = entries
                        .where((e) => e.weightKg != null)
                        .map((e) => e.weightKg!)
                        .toList()
                        .reversed
                        .toList();
                    if (pts.length < 2) {
                      return GlassmorphicCard(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Center(
                            child: Text('Need at least 2 check-ins for trend',
                                style: GoogleFonts.inter(
                                    color: t.textSecondary, fontSize: 13)),
                          ),
                        ),
                      );
                    }
                    final total = pts.last - pts.first;
                    return GlassmorphicCard(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Text('Weight Journey',
                                    style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: t.textPrimary)),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: (total < 0 ? t.success : t.danger)
                                        .withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${total > 0 ? '+' : ''}${total.toStringAsFixed(1)} kg total',
                                    style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color:
                                            total < 0 ? t.success : t.danger),
                                  ),
                                ),
                              ]),
                              const SizedBox(height: 14),
                              RepaintBoundary(
                                child: SizedBox(
                                  height: 120,
                                  child: CustomPaint(
                                    size: const Size(double.infinity, 120),
                                    painter: _LineChart(
                                        data: pts,
                                        color: _masterPrimary,
                                        dotStrokeColor: t.background),
                                  ),
                                ),
                              ),
                            ]),
                      ),
                    ).animate(delay: 80.ms).fadeIn();
                  },
                ),
              ),
            ),
            const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
          ],
        ),
      ),
    );
  }

  Widget _hdr(BuildContext context, String label) => SliverPadding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        sliver: SliverToBoxAdapter(
          child: Text(label,
              style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: context.fitTheme.textMuted,
                  letterSpacing: 1.2)),
        ),
      );

  Widget _shimmer(BuildContext context, double h) {
    final t = context.fitTheme;
    return Container(
      height: h,
      decoration: BoxDecoration(
          color: t.surface, borderRadius: BorderRadius.circular(16)),
    )
        .animate(onPlay: (c) => c.repeat())
        .shimmer(duration: 1200.ms, color: t.surfaceAlt.withOpacity(0.5));
  }
}

// ─── Body Composition Card ────────────────────────────────────────────────────

class _BodyCompositionCard extends StatelessWidget {
  final List<ProgressCheckIn> entries;
  const _BodyCompositionCard({required this.entries});

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;
    if (entries.isEmpty) {
      return GlassmorphicCard(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Center(
              child: Text(
                  'No data available — log body measurements to see insights',
                  textAlign: TextAlign.center,
                  style:
                      GoogleFonts.inter(color: t.textSecondary, fontSize: 13))),
        ),
      );
    }
    final latest = entries.first;
    return GlassmorphicCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          _metricRow(context, 'Weight',
              latest.weightKg?.toStringAsFixed(1) ?? '—', 'kg', t.brand),
          _metricRow(context, 'Body Fat',
              latest.bodyFatPercent?.toStringAsFixed(1) ?? '—', '%', t.warning),
          _metricRow(context, 'Waist',
              latest.waistCm?.toStringAsFixed(0) ?? '—', 'cm', t.danger),
          _metricRow(context, 'Chest',
              latest.chestCm?.toStringAsFixed(0) ?? '—', 'cm', t.accent),
          _metricRow(context, 'Arms', latest.armCm?.toStringAsFixed(0) ?? '—',
              'cm', t.info),
        ]),
      ),
    ).animate().fadeIn();
  }

  Widget _metricRow(
      BuildContext context, String label, String val, String unit, Color c) {
    final t = context.fitTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        SizedBox(
            width: 70,
            child: Text(label,
                style:
                    GoogleFonts.inter(fontSize: 13, color: t.textSecondary))),
        const SizedBox(width: 8),
        Expanded(
            child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: 0.6,
            backgroundColor: c.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation(c),
            minHeight: 6,
          ),
        )),
        const SizedBox(width: 10),
        Text('$val $unit',
            style: GoogleFonts.inter(
                fontSize: 12, fontWeight: FontWeight.w700, color: c)),
      ]),
    );
  }
}

// ─── Metrics Grid ─────────────────────────────────────────────────────────────

class _MetricsGrid extends StatelessWidget {
  final List<ProgressCheckIn> entries;
  const _MetricsGrid({required this.entries});

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;
    final total = entries.length;
    final avgAdherence = entries.isEmpty
        ? 0
        : entries
                .where((e) => e.adherencePercent != null)
                .fold(0, (sum, e) => sum + (e.adherencePercent ?? 0)) ~/
            math.max(
                1, entries.where((e) => e.adherencePercent != null).length);
    final weightChange = entries.length >= 2 &&
            entries.first.weightKg != null &&
            entries.last.weightKg != null
        ? (entries.first.weightKg! - entries.last.weightKg!).toStringAsFixed(1)
        : '—';

    final tiles = [
      ('Check-ins', '$total', t.brand, Icons.assignment_turned_in_rounded),
      ('Avg Adherence', '$avgAdherence%', t.success, Icons.trending_up_rounded),
      (
        'Weight Change',
        '$weightChange kg',
        t.warning,
        Icons.monitor_weight_rounded
      ),
      (
        'Streak',
        '${math.min(total, 14)} days',
        t.accent,
        Icons.local_fire_department_rounded
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.8,
      children: tiles.asMap().entries.map((e) {
        final i = e.key;
        final (label, val, color, icon) = e.value;
        return Container(
          decoration: BoxDecoration(
            color: color.withOpacity(0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 10),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(val,
                      style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: color)),
                  Text(label,
                      style: GoogleFonts.inter(
                          fontSize: 10, color: t.textSecondary)),
                ])),
          ]),
        ).animate(delay: (i * 60).ms).fadeIn();
      }).toList(),
    );
  }
}

// ─── Bar Chart ────────────────────────────────────────────────────────────────

class _BarChart extends StatelessWidget {
  final List<double> values;
  final Color color;
  const _BarChart({required this.values, required this.color});

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;
    if (values.isEmpty) {
      return Center(
          child: Text('No data',
              style: GoogleFonts.inter(color: t.textMuted, fontSize: 13)));
    }
    final max = values.reduce(math.max);
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: values.asMap().entries.map((e) {
        final ratio = max > 0 ? e.value / max : 0.0;
        return Column(mainAxisAlignment: MainAxisAlignment.end, children: [
          Text('${e.value.round()}',
              style: GoogleFonts.inter(fontSize: 8, color: color)),
          const SizedBox(height: 4),
          AnimatedContainer(
            duration: const Duration(milliseconds: 600),
            width: 24,
            height: (100 * ratio).clamp(4.0, 100.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [color, color.withOpacity(0.4)]),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 4),
          Text(e.key < days.length ? days[e.key] : '${e.key + 1}',
              style: GoogleFonts.inter(fontSize: 9, color: t.textMuted)),
        ]);
      }).toList(),
    );
  }
}

// ─── Line Chart ───────────────────────────────────────────────────────────────

class _LineChart extends CustomPainter {
  final List<double> data;
  final Color color;
  final Color dotStrokeColor;
  _LineChart(
      {required this.data, required this.color, required this.dotStrokeColor});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;
    final min = data.reduce(math.min);
    final max = data.reduce(math.max);
    final range = (max - min).abs().clamp(0.1, double.infinity);
    final line = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    final fill = Paint()
      ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [color.withOpacity(0.25), color.withOpacity(0)])
          .createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;
    final pts = <Offset>[
      for (var i = 0; i < data.length; i++)
        Offset(i * size.width / (data.length - 1),
            size.height - (data[i] - min) / range * (size.height - 16) - 8)
    ];
    final fp = Path()..moveTo(pts.first.dx, size.height);
    for (final p in pts) {
      fp.lineTo(p.dx, p.dy);
    }
    fp.lineTo(pts.last.dx, size.height);
    fp.close();
    canvas.drawPath(fp, fill);
    final lp = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var i = 1; i < pts.length; i++) {
      final cp = Offset(
          (pts[i - 1].dx + pts[i].dx) / 2, (pts[i - 1].dy + pts[i].dy) / 2);
      lp.quadraticBezierTo(pts[i - 1].dx, pts[i - 1].dy, cp.dx, cp.dy);
    }
    lp.lineTo(pts.last.dx, pts.last.dy);
    canvas.drawPath(lp, line);
    for (final p in pts) {
      canvas.drawCircle(p, 4, Paint()..color = color);
      canvas.drawCircle(
          p,
          4,
          Paint()
            ..color = dotStrokeColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2);
    }
  }

  @override
  bool shouldRepaint(_LineChart o) => o.data != data;
}
