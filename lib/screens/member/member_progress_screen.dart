import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../core/dev_bypass.dart';
import '../../core/extensions.dart';
import '../../providers/auth_provider.dart';
import '../../providers/gym_provider.dart';
import '../../providers/member_provider.dart';
import '../../widgets/glassmorphic_card.dart';

/// Weight progress tracking screen — chart + log weight button.
class MemberProgressScreen extends ConsumerStatefulWidget {
  const MemberProgressScreen({super.key});

  @override
  ConsumerState<MemberProgressScreen> createState() =>
      _MemberProgressScreenState();
}

class _MemberProgressScreenState
    extends ConsumerState<MemberProgressScreen> {
  final _weightController = TextEditingController();

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progressAsync = ref.watch(memberProgressProvider);

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.bgDark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textSecondary),
          onPressed: () => context.pop(),
        ),
        title: Text('Weight Progress',
            style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary)),
        actions: [
          TextButton.icon(
            onPressed: () => _showLogSheet(context),
            icon: const Icon(Icons.add_rounded,
                size: 18, color: AppColors.primary),
            label: Text('Log Weight',
                style:
                    GoogleFonts.inter(color: AppColors.primary, fontSize: 13)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: progressAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(
            child: Text('Error: $e',
                style: GoogleFonts.inter(color: AppColors.error))),
        data: (entries) {
          if (entries.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.monitor_weight_rounded,
                      size: 56, color: AppColors.textMuted),
                  const SizedBox(height: 16),
                  Text('No weight entries yet',
                      style: GoogleFonts.inter(
                          color: AppColors.textSecondary, fontSize: 16)),
                  const SizedBox(height: 8),
                  Text('Tap "Log Weight" to start tracking',
                      style: GoogleFonts.inter(
                          color: AppColors.textMuted, fontSize: 13)),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => _showLogSheet(context),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Log First Entry'),
                    style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary),
                  ),
                ],
              ),
            );
          }

          // Filter entries with weight
          final withWeight = entries
              .where((e) => e['weight_kg'] != null)
              .toList();
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
                        color: AppColors.primary,
                      )),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _StatCard(
                        label: change <= 0 ? '▼ Lost' : '▲ Gained',
                        value: '${change.abs().toStringAsFixed(1)} kg',
                        color: change <= 0 ? AppColors.success : AppColors.warning,
                      )),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _StatCard(
                        label: 'Entries',
                        value: '${withWeight.length}',
                        color: AppColors.info,
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
                                  color: AppColors.textPrimary)),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 160,
                            child: _WeightChart(entries: withWeight.reversed.toList()),
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
                          color: AppColors.textMuted,
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
                        children:
                            withWeight.asMap().entries.map((entry) {
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
                                contentPadding:
                                    const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 2),
                                title: Text(
                                  _formatDate(date),
                                  style: GoogleFonts.inter(
                                      fontSize: 14,
                                      color: AppColors.textSecondary),
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
                                              ? AppColors.success
                                              : diff > 0
                                                  ? AppColors.warning
                                                  : AppColors.textMuted,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    const SizedBox(width: 12),
                                    Text(
                                      '${w.toStringAsFixed(1)} kg',
                                      style: GoogleFonts.inter(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.textPrimary),
                                    ),
                                  ],
                                ),
                              ),
                              if (i < withWeight.length - 1)
                                const Divider(
                                    color: AppColors.divider, height: 1),
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
    _weightController.clear();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgCard,
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
                  color: AppColors.textMuted.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('Log Today\'s Weight',
                style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 20),
            TextFormField(
              controller: _weightController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style:
                  GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 24),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: '75.0',
                hintStyle: GoogleFonts.inter(color: AppColors.textMuted),
                suffix: Text(' kg',
                    style: GoogleFonts.inter(
                        color: AppColors.textSecondary, fontSize: 18)),
                filled: true,
                fillColor: AppColors.bgInput,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                      color: AppColors.primary, width: 2),
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
                  backgroundColor: AppColors.primary,
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
            backgroundColor: AppColors.success,
          ),
        );
      }
      return;
    }

    final gym = ref.read(selectedGymProvider);
    if (gym == null) return;

    try {
      final db = ref.read(databaseServiceProvider);
      await db.logWeight(
        gymId: gym.id,
        clientId: user.id,
        weightKg: val,
      );
      ref.invalidate(memberProgressProvider);
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Weight logged: ${val.toStringAsFixed(1)} kg'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed: $e'),
              backgroundColor: AppColors.error),
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
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Text(value,
              style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: color)),
          const SizedBox(height: 2),
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 11, color: AppColors.textSecondary)),
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
    final weights = entries
        .map((e) => (e['weight_kg'] as num).toDouble())
        .toList();
    return CustomPaint(
      painter: _ChartPainter(weights: weights),
      size: const Size(double.infinity, 160),
    );
  }
}

class _ChartPainter extends CustomPainter {
  final List<double> weights;
  _ChartPainter({required this.weights});

  @override
  void paint(Canvas canvas, Size size) {
    if (weights.length < 2) return;

    final minW = weights.reduce((a, b) => a < b ? a : b) - 1;
    final maxW = weights.reduce((a, b) => a > b ? a : b) + 1;
    final range = maxW - minW;

    final linePaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final dotPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.fill;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.primary.withValues(alpha: 0.3),
          AppColors.primary.withValues(alpha: 0.0),
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
