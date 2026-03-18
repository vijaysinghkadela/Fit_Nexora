// lib/screens/health/water_tracker_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../core/extensions.dart';
import '../../providers/water_tracker_provider.dart';
import '../../widgets/circular_gauge.dart';
import '../../widgets/glassmorphic_card.dart';

class WaterTrackerScreen extends ConsumerWidget {
  const WaterTrackerScreen({super.key});

  static const _quickAmounts = [150, 250, 350, 500, 750];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.fitTheme;
    final state = ref.watch(waterTrackerProvider);
    final progress = state.progressFraction;

    return Scaffold(
      backgroundColor: t.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            backgroundColor: t.surface,
            title: Text(
              'Hydration',
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: t.textPrimary,
              ),
            ),
            leading: IconButton(
              icon: Icon(Icons.arrow_back_rounded, color: t.textPrimary),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.tune_rounded, color: t.textSecondary),
                onPressed: () => _showGoalSheet(context, ref, state.dailyGoalMl),
              ),
            ],
          ),

          // Hero gauge
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                children: [
                  RepaintBoundary(
                    child: CircularGauge(
                      value: progress,
                      size: 200,
                      centerText: '${state.totalTodayMl}',
                      label: '/ ${state.dailyGoalMl} ml goal',
                      gradientColors: [const Color(0xFF38BDF8), t.brand],
                    ),
                  ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.9, 0.9)),
                  const SizedBox(height: 16),
                  Text(
                    state.totalTodayMl >= state.dailyGoalMl
                        ? '🎉 Daily goal reached!'
                        : '${state.remainingMl} ml remaining',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: state.totalTodayMl >= state.dailyGoalMl
                          ? t.success
                          : t.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Stats row
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  _StatCard(
                    emoji: '🥛',
                    label: 'Glasses',
                    value: '${state.glassesConsumed}',
                    sub: '× 250 ml',
                    color: t.brand,
                  ),
                  const SizedBox(width: 12),
                  _StatCard(
                    emoji: '📊',
                    label: 'Logs today',
                    value: '${state.todayLogs.length}',
                    sub: 'entries',
                    color: t.info,
                  ),
                  const SizedBox(width: 12),
                  _StatCard(
                    emoji: '🎯',
                    label: 'Goal',
                    value: '${(state.dailyGoalMl / 1000).toStringAsFixed(1)}L',
                    sub: 'daily',
                    color: t.success,
                  ),
                ].map((w) => Expanded(child: w)).toList(),
              ),
            ),
          ),

          // Quick add buttons
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'QUICK ADD',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: t.textMuted,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _quickAmounts.map((ml) {
                      return GestureDetector(
                        onTap: () => ref
                            .read(waterTrackerProvider.notifier)
                            .logWater(ml),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF38BDF8).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: const Color(0xFF38BDF8).withOpacity(0.25),
                            ),
                          ),
                          child: Text(
                            ml >= 1000
                                ? '${(ml / 1000).toStringAsFixed(1)} L'
                                : '$ml ml',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF38BDF8),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),

          // Today's log
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            sliver: SliverToBoxAdapter(
              child: Text(
                "TODAY'S LOG",
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: t.textMuted,
                ),
              ),
            ),
          ),

          if (state.todayLogs.isEmpty)
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverToBoxAdapter(
                child: GlassmorphicCard(
                  borderRadius: 16,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        const Text('💧', style: TextStyle(fontSize: 40)),
                        const SizedBox(height: 12),
                        Text(
                          'No water logged yet today',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: t.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
              sliver: SliverList.builder(
                itemCount: state.todayLogs.length,
                itemBuilder: (context, i) {
                  final log = state.todayLogs[i];
                  return Dismissible(
                    key: Key(log.id),
                    direction: DismissDirection.endToStart,
                    onDismissed: (_) => ref
                        .read(waterTrackerProvider.notifier)
                        .removeLog(log.id),
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      margin: const EdgeInsets.symmetric(vertical: 3),
                      decoration: BoxDecoration(
                        color: t.danger.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(Icons.delete_outline_rounded,
                          color: t.danger),
                    ),
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 3),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: t.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: t.border),
                      ),
                      child: Row(
                        children: [
                          const Text('💧',
                              style: TextStyle(fontSize: 22)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              DateFormat('h:mm a').format(log.loggedAt),
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: t.textSecondary,
                              ),
                            ),
                          ),
                          Text(
                            log.amountMl >= 1000
                                ? '${(log.amountMl / 1000).toStringAsFixed(1)} L'
                                : '${log.amountMl} ml',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF38BDF8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ).animate(delay: (i * 30).ms).fadeIn(duration: 200.ms);
                },
              ),
            ),
        ],
      ),
    );
  }

  static Future<void> _showGoalSheet(
    BuildContext context,
    WidgetRef ref,
    int currentGoal,
  ) async {
    final t = context.fitTheme;
    final ctrl = TextEditingController(text: '$currentGoal');

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: t.surface,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          8,
          20,
          20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Daily Water Goal',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: t.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Goal (ml)',
                hintText: '2500',
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                final val = int.tryParse(ctrl.text);
                if (val != null && val > 0) {
                  ref.read(waterTrackerProvider.notifier).setDailyGoal(val);
                }
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52)),
              child: const Text('Save Goal'),
            ),
          ],
        ),
      ),
    );
    ctrl.dispose();
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.emoji,
    required this.label,
    required this.value,
    required this.sub,
    required this.color,
  });
  final String emoji;
  final String label;
  final String value;
  final String sub;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            sub,
            style: GoogleFonts.inter(fontSize: 10, color: t.textMuted),
          ),
        ],
      ),
    );
  }
}
