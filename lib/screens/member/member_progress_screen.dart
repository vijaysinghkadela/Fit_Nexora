import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../config/theme.dart';
import '../../core/dev_bypass.dart';
import '../../core/extensions.dart';
import '../../models/trainer_analysis_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/gym_provider.dart';
import '../../providers/member_provider.dart';
import '../../providers/trainer_analysis_provider.dart';
import '../../widgets/glassmorphic_card.dart';
import '../../widgets/member_bottom_nav.dart';

/// Weight progress tracking screen — chart + log weight button.
class MemberProgressScreen extends ConsumerStatefulWidget {
  const MemberProgressScreen({super.key});

  @override
  ConsumerState<MemberProgressScreen> createState() =>
      _MemberProgressScreenState();
}

class _MemberProgressScreenState extends ConsumerState<MemberProgressScreen> {
  final _weightController = TextEditingController();

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;
    final progressAsync = ref.watch(memberProgressProvider);

    return Scaffold(
      backgroundColor: t.background,
      bottomNavigationBar: const MemberBottomNav(),
      appBar: AppBar(
        backgroundColor: t.background,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: t.textSecondary),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/member');
            }
          },
        ),
        title: Text('Weight Progress',
            style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: t.textPrimary)),
        actions: [
          TextButton.icon(
            onPressed: () => _showLogSheet(context),
            icon: Icon(Icons.add_rounded, size: 18, color: t.brand),
            label: Text('Log Weight',
                style: GoogleFonts.inter(color: t.brand, fontSize: 13)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: progressAsync.when(
        loading: () => _ProgressSkeleton(t: t),
        error: (e, _) => Center(
            child:
                Text('Error: $e', style: GoogleFonts.inter(color: t.danger))),
        data: (entries) {
          if (entries.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.monitor_weight_rounded,
                      size: 56, color: t.textMuted),
                  const SizedBox(height: 16),
                  Text('No weight entries yet',
                      style: GoogleFonts.inter(
                          color: t.textSecondary, fontSize: 16)),
                  const SizedBox(height: 8),
                  Text('Tap "Log Weight" to start tracking',
                      style:
                          GoogleFonts.inter(color: t.textMuted, fontSize: 13)),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => _showLogSheet(context),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Log First Entry'),
                    style: FilledButton.styleFrom(backgroundColor: t.brand),
                  ),
                ],
              ),
            );
          }

          // Filter entries with weight
          final withWeight =
              entries.where((e) => e['weight_kg'] != null).toList();
          final current =
              withWeight.isNotEmpty ? withWeight.first['weight_kg'] as num : 0;
          final oldest =
              withWeight.isNotEmpty ? withWeight.last['weight_kg'] as num : 0;
          final change = current - oldest;

          return CustomScrollView(
            slivers: [
              // AI Trainer Reports section (visible to members)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: _MemberAiReportsSection(),
                ),
              ),

              // Summary cards
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    children: [
                      Expanded(
                          child: _StatCard(
                        label: 'Current',
                        value: '${current.toStringAsFixed(1)} kg',
                        color: t.brand,
                      )),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _StatCard(
                        label: change <= 0 ? '▼ Lost' : '▲ Gained',
                        value: '${change.abs().toStringAsFixed(1)} kg',
                        color: change <= 0 ? t.success : t.warning,
                      )),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _StatCard(
                        label: 'Entries',
                        value: '${withWeight.length}',
                        color: t.info,
                      )),
                    ],
                  ).animate().fadeIn(),
                ),
              ),

              // Simple chart
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: GlassmorphicCard(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Progress Chart',
                              style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: t.textPrimary)),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 160,
                            child: _WeightChart(
                                entries: withWeight.reversed.toList()),
                          ),
                        ],
                      ),
                    ),
                  ).animate(delay: 100.ms).fadeIn(),
                ),
              ),

              // History list
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                sliver: SliverToBoxAdapter(
                  child: Text('HISTORY',
                      style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: t.textMuted,
                          letterSpacing: 1.2)),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverToBoxAdapter(
                  child: GlassmorphicCard(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        children: withWeight.asMap().entries.map((entry) {
                          final i = entry.key;
                          final e = entry.value;
                          final prevWeight = i < withWeight.length - 1
                              ? withWeight[i + 1]['weight_kg'] as num
                              : null;
                          final w = e['weight_kg'] as num;
                          final diff =
                              prevWeight != null ? w - prevWeight : null;
                          final date = e['checkin_date'] as String;

                          return Column(
                            children: [
                              ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 2),
                                title: Text(
                                  _formatDate(date),
                                  style: GoogleFonts.inter(
                                      fontSize: 14, color: t.textSecondary),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (diff != null)
                                      Text(
                                        diff < 0
                                            ? '▼ ${(-diff).toStringAsFixed(1)}'
                                            : diff > 0
                                                ? '▲ ${diff.toStringAsFixed(1)}'
                                                : '—',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: diff < 0
                                              ? t.success
                                              : diff > 0
                                                  ? t.warning
                                                  : t.textMuted,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    const SizedBox(width: 12),
                                    Text(
                                      '${w.toStringAsFixed(1)} kg',
                                      style: GoogleFonts.inter(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          color: t.textPrimary),
                                    ),
                                  ],
                                ),
                              ),
                              if (i < withWeight.length - 1)
                                Divider(color: t.divider, height: 1),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ).animate(delay: 200.ms).fadeIn(),
                ),
              ),

              const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
            ],
          );
        },
      ),
    );
  }

  String _formatDate(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    return dt.mediumFormatted;
  }

  void _showLogSheet(BuildContext context) {
    final t = context.fitTheme;
    _weightController.clear();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: t.surfaceAlt,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
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
            Text('Log Today\'s Weight',
                style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: t.textPrimary)),
            const SizedBox(height: 20),
            TextFormField(
              controller: _weightController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: GoogleFonts.inter(color: t.textPrimary, fontSize: 24),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: '75.0',
                hintStyle: GoogleFonts.inter(color: t.textMuted),
                suffix: Text(' kg',
                    style: GoogleFonts.inter(
                        color: t.textSecondary, fontSize: 18)),
                filled: true,
                fillColor: t.surfaceMuted,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: t.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: t.brand, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: () => _saveWeight(context),
                style: FilledButton.styleFrom(
                  backgroundColor: t.brand,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: Text('Save Weight',
                    style: GoogleFonts.inter(
                        fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveWeight(BuildContext context) async {
    final t = context.fitTheme;
    final val = double.tryParse(_weightController.text);
    if (val == null || val <= 0) return;

    final user = ref.read(currentUserProvider).value;
    if (user == null) return;

    // Developer Bypass: Simulate saving weight
    if (isDevUser(user.email)) {
      ref.invalidate(memberProgressProvider);
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Weight logged: ${val.toStringAsFixed(1)} kg'),
            backgroundColor: t.success,
          ),
        );
      }
      return;
    }

    final gym = ref.read(selectedGymProvider);
    if (gym == null) return;

    try {
      final membership = ref.read(memberMembershipProvider).valueOrNull;
      final clientId =
          membership?.clientId ?? await ref.read(memberClientIdProvider.future);
      if (clientId == null) {
        throw Exception('Member profile not found for this gym.');
      }

      final db = ref.read(databaseServiceProvider);
      await db.logWeight(
        gymId: gym.id,
        clientId: clientId,
        weightKg: val,
      );
      ref.invalidate(memberProgressProvider);
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Weight logged: ${val.toStringAsFixed(1)} kg'),
            backgroundColor: t.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: t.danger),
        );
      }
    }
  }
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatCard(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        children: [
          Text(value,
              style: GoogleFonts.inter(
                  fontSize: 18, fontWeight: FontWeight.w900, color: color)),
          const SizedBox(height: 2),
          Text(label,
              style: GoogleFonts.inter(fontSize: 11, color: t.textSecondary)),
        ],
      ),
    );
  }
}

/// Simple weight chart using Canvas.
class _WeightChart extends StatelessWidget {
  final List<Map<String, dynamic>> entries;
  const _WeightChart({required this.entries});

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.shrink();
    final brandColor = context.fitTheme.brand;
    final weights =
        entries.map((e) => (e['weight_kg'] as num).toDouble()).toList();
    return CustomPaint(
      painter: _ChartPainter(weights: weights, brandColor: brandColor),
      size: const Size(double.infinity, 160),
    );
  }
}

class _ChartPainter extends CustomPainter {
  final List<double> weights;
  final Color brandColor;
  _ChartPainter({required this.weights, required this.brandColor});

  @override
  void paint(Canvas canvas, Size size) {
    if (weights.length < 2) return;

    final minW = weights.reduce((a, b) => a < b ? a : b) - 1;
    final maxW = weights.reduce((a, b) => a > b ? a : b) + 1;
    final range = maxW - minW;

    final linePaint = Paint()
      ..color = brandColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final dotPaint = Paint()
      ..color = brandColor
      ..style = PaintingStyle.fill;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          brandColor.withOpacity(0.3),
          brandColor.withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final n = weights.length;
    final path = Path();
    final fillPath = Path();

    for (var i = 0; i < n; i++) {
      final x = i * size.width / (n - 1);
      final y = size.height - ((weights[i] - minW) / range) * size.height;

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }

      canvas.drawCircle(Offset(x, y), 4, dotPaint);
    }

    fillPath.lineTo((n - 1) * size.width / (n - 1), size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ─── Skeleton Loading State ───────────────────────────────────────────────────

class _ProgressSkeleton extends StatefulWidget {
  const _ProgressSkeleton({required this.t});
  final FitNexoraThemeTokens t;

  @override
  State<_ProgressSkeleton> createState() => _ProgressSkeletonState();
}

class _ProgressSkeletonState extends State<_ProgressSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Widget _bone(double w, double h, {double radius = 10}) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          color: widget.t.surfaceMuted.withOpacity(_anim.value),
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.t;
    return CustomScrollView(
      physics: const NeverScrollableScrollPhysics(),
      slivers: [
        // Stat cards
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          sliver: SliverToBoxAdapter(
            child: Row(
              children: List.generate(
                  3,
                  (i) => Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                              left: i == 0 ? 0 : 6, right: i == 2 ? 0 : 6),
                          child: Container(
                            height: 80,
                            decoration: BoxDecoration(
                              color: t.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: t.border),
                            ),
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _bone(40, 10),
                                _bone(55, 18, radius: 6),
                              ],
                            ),
                          ),
                        ),
                      )),
            ),
          ),
        ),
        // Chart skeleton
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          sliver: SliverToBoxAdapter(
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                color: t.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: t.border),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _bone(100, 14),
                  const Spacer(),
                  _bone(double.infinity, 80, radius: 8),
                ],
              ),
            ),
          ),
        ),
        // History rows
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          sliver: SliverList.builder(
            itemCount: 5,
            itemBuilder: (_, i) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: t.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: t.border),
              ),
              child: Row(
                children: [
                  _bone(42, 42, radius: 12),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _bone(80, 12),
                        const SizedBox(height: 6),
                        _bone(120, 10),
                      ],
                    ),
                  ),
                  _bone(50, 14, radius: 6),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Section showing AI trainer reports for members
class _MemberAiReportsSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.fitTheme;
    final user = ref.watch(currentUserProvider).value;

    if (user == null) return const SizedBox.shrink();

    final reportsAsync = ref.watch(clientAnalysisReportsProvider(user.id));

    return reportsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (reports) {
        if (reports.isEmpty) return const SizedBox.shrink();

        // Show only the latest 3 reports
        final latestReports = reports.take(3).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome_rounded, size: 18, color: t.brand),
                const SizedBox(width: 8),
                Text(
                  'Trainer AI Reports',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: t.textPrimary,
                  ),
                ),
                const Spacer(),
                if (reports.length > 3)
                  TextButton(
                    onPressed: () => _showAllReports(context, reports),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'View All',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: t.brand,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            for (var i = 0; i < latestReports.length; i++) ...[
              _MemberReportCard(report: latestReports[i])
                  .animate(delay: (i * 100).ms)
                  .fadeIn()
                  .slideX(begin: 0.05),
              if (i < latestReports.length - 1) const SizedBox(height: 10),
            ],
            const SizedBox(height: 20),
          ],
        );
      },
    );
  }

  void _showAllReports(
      BuildContext context, List<TrainerAnalysisReport> reports) {
    final t = context.fitTheme;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, scrollController) => Container(
          decoration: BoxDecoration(
            color: t.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: t.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome_rounded, color: t.brand, size: 22),
                    const SizedBox(width: 10),
                    Text(
                      'All Trainer Reports',
                      style: GoogleFonts.inter(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: t.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // List
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  itemCount: reports.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, index) => _MemberReportCard(
                    report: reports[index],
                    onTap: () => _showReportDetail(ctx, reports[index]),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showReportDetail(BuildContext context, TrainerAnalysisReport report) {
    final t = context.fitTheme;
    Navigator.pop(context); // Close the list sheet
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, scrollController) => Container(
          decoration: BoxDecoration(
            color: t.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(20),
            child: _MemberReportDetailView(report: report),
          ),
        ),
      ),
    );
  }
}

/// Compact report card for member view
class _MemberReportCard extends StatelessWidget {
  final TrainerAnalysisReport report;
  final VoidCallback? onTap;

  const _MemberReportCard({required this.report, this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;
    final dateStr = DateFormat('MMM d, yyyy').format(report.createdAt);
    final scoreColor = _getScoreColor(report.overallScore, t);

    return GlassmorphicCard(
      onTap: onTap ?? () => _showDetail(context),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Score circle
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: scoreColor, width: 2.5),
              ),
              child: Center(
                child: Text(
                  '${report.overallScore}',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: scoreColor,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        report.scoreCategory,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: scoreColor,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        dateStr,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: t.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (report.clientMessage != null &&
                      report.clientMessage!.isNotEmpty)
                    Text(
                      report.clientMessage!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: t.textSecondary,
                        height: 1.3,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded, color: t.textMuted, size: 20),
          ],
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    final t = context.fitTheme;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, scrollController) => Container(
          decoration: BoxDecoration(
            color: t.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(20),
            child: _MemberReportDetailView(report: report),
          ),
        ),
      ),
    );
  }

  Color _getScoreColor(int score, FitNexoraThemeTokens colors) {
    if (score >= 80) return colors.accent;
    if (score >= 60) return colors.brand;
    if (score >= 40) return colors.warning;
    return colors.danger;
  }
}

/// Full report detail view for members (simplified version)
class _MemberReportDetailView extends StatelessWidget {
  final TrainerAnalysisReport report;

  const _MemberReportDetailView({required this.report});

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;
    final dateStr = DateFormat('MMMM d, yyyy').format(report.createdAt);
    final scoreColor = _getScoreColor(report.overallScore, t);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Handle
        Center(
          child: Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: t.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),

        // Header with big score
        Center(
          child: Column(
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: scoreColor, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: scoreColor.withOpacity(0.25),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${report.overallScore}',
                        style: GoogleFonts.inter(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: scoreColor,
                        ),
                      ),
                      Text(
                        'SCORE',
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: t.textMuted,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                report.scoreCategory,
                style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: scoreColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                dateStr,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: t.textMuted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Score breakdown row
        Row(
          children: [
            _ScoreItem(
                label: 'Workout',
                value: report.workoutAdherenceScore,
                color: t.brand),
            _ScoreItem(
                label: 'Diet',
                value: report.dietAdherenceScore,
                color: t.accent),
            _ScoreItem(
                label: 'Progress',
                value: report.progressScore,
                color: t.warning),
            _ScoreItem(
                label: 'Consistency',
                value: report.consistencyScore,
                color: t.info),
          ],
        ),
        const SizedBox(height: 24),

        // Message from trainer (highlighted)
        if (report.clientMessage != null &&
            report.clientMessage!.isNotEmpty) ...[
          _SectionCard(
            icon: Icons.message_rounded,
            title: 'Message from Your Trainer',
            content: report.clientMessage!,
            highlight: true,
            t: t,
          ),
          const SizedBox(height: 16),
        ],

        // Summary
        if (report.summary != null && report.summary!.isNotEmpty) ...[
          _SectionCard(
            icon: Icons.summarize_rounded,
            title: 'Summary',
            content: report.summary!,
            t: t,
          ),
          const SizedBox(height: 16),
        ],

        // Achievements
        if (report.achievements.isNotEmpty) ...[
          _ListSection(
            icon: Icons.emoji_events_rounded,
            title: 'Your Achievements',
            items: report.achievements,
            color: t.warning,
            t: t,
          ),
          const SizedBox(height: 16),
        ],

        // Next month priorities
        if (report.nextMonthPriorities.isNotEmpty) ...[
          _ListSection(
            icon: Icons.flag_rounded,
            title: 'Focus Areas',
            items: report.nextMonthPriorities,
            color: t.brand,
            t: t,
          ),
          const SizedBox(height: 16),
        ],

        // Workout tips
        if (report.workoutAdjustments.isNotEmpty) ...[
          _ListSection(
            icon: Icons.fitness_center_rounded,
            title: 'Workout Tips',
            items: report.workoutAdjustments,
            color: t.brand,
            t: t,
          ),
          const SizedBox(height: 16),
        ],

        // Diet tips
        if (report.dietAdjustments.isNotEmpty) ...[
          _ListSection(
            icon: Icons.restaurant_rounded,
            title: 'Nutrition Tips',
            items: report.dietAdjustments,
            color: t.accent,
            t: t,
          ),
          const SizedBox(height: 16),
        ],

        const SizedBox(height: 20),
      ],
    );
  }

  Color _getScoreColor(int score, FitNexoraThemeTokens colors) {
    if (score >= 80) return colors.accent;
    if (score >= 60) return colors.brand;
    if (score >= 40) return colors.warning;
    return colors.danger;
  }
}

class _ScoreItem extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _ScoreItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;
    return Expanded(
      child: Column(
        children: [
          Text(
            '$value',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: t.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String content;
  final bool highlight;
  final FitNexoraThemeTokens t;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.content,
    this.highlight = false,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    return GlassmorphicCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: highlight ? t.brand : t.textMuted),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: t.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: highlight ? const EdgeInsets.all(12) : null,
              decoration: highlight
                  ? BoxDecoration(
                      color: t.brand.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: t.brand.withOpacity(0.2)),
                    )
                  : null,
              child: Text(
                content,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: t.textSecondary,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ListSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<String> items;
  final Color color;
  final FitNexoraThemeTokens t;

  const _ListSection({
    required this.icon,
    required this.title,
    required this.items,
    required this.color,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    return GlassmorphicCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: t.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            for (final item in items) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle_rounded, size: 16, color: color),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: t.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
              if (item != items.last) const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }
}
