import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/theme.dart';
import '../../core/dev_bypass.dart';
import '../../core/extensions.dart';
import '../../providers/auth_provider.dart';
import '../../providers/gym_provider.dart';
import '../../providers/member_provider.dart';
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
