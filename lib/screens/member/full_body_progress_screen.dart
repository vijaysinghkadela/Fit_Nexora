// lib/screens/member/full_body_progress_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/extensions.dart';
import '../../models/muscle_group_model.dart';
import '../../providers/member_provider.dart';
import '../../providers/muscle_progress_provider.dart';
import '../../widgets/body_diagram_painter.dart';
import '../../widgets/circular_gauge.dart';
import '../../widgets/glassmorphic_card.dart';
import '../../widgets/macro_progress_bar.dart';

class FullBodyProgressScreen extends ConsumerWidget {
  const FullBodyProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.fitTheme;
    final musclesAsync = ref.watch(muscleProgressProvider);

    return Scaffold(
      backgroundColor: t.background,
      body: musclesAsync.when(
        loading: () => Center(
            child:
                CircularProgressIndicator(color: t.brand)),
        error: (e, _) => Center(
          child: Text('Failed to load: $e',
              style: GoogleFonts.inter(
                  color: t.danger, fontSize: 14)),
        ),
        data: (muscles) => _ProgressBody(muscles: muscles),
      ),
    );
  }
}

// ── Main body ────────────────────────────────────────────────────────────────

class _ProgressBody extends ConsumerStatefulWidget {
  final List<MuscleGroupProgress> muscles;
  const _ProgressBody({required this.muscles});

  @override
  ConsumerState<_ProgressBody> createState() =>
      _ProgressBodyState();
}

class _ProgressBodyState extends ConsumerState<_ProgressBody> {
  String? _selectedMuscleId;

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;
    final overallScore = ref.watch(overallMuscleScoreProvider);
    final weakMuscles = ref.watch(weakMusclesProvider);
    final attendanceAsync = ref.watch(memberAttendanceProvider);
    final historyAsync = ref.watch(workoutHistoryProvider);
    final dietAsync = ref.watch(memberDietPlanProvider);

    // Streak: consecutive days with workout (simplified)
    final history = historyAsync.value ?? [];
    final weeklyFreq =
        (history.length / 4.0).clamp(0.0, 7.0).toStringAsFixed(1);

    return SafeArea(
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // ── App Bar ────────────────────────────────────────────────────
          SliverAppBar(
            floating: true,
            backgroundColor: t.background,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_rounded,
                  color: t.textSecondary),
              onPressed: () => context.canPop()
                  ? context.pop()
                  : context.go('/member'),
            ),
            title: Text(
              'Full Body Progress',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: t.textPrimary,
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: t.brand.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: t.brand.withOpacity(0.4)),
                  ),
                  child: Text(
                    '${overallScore.round()}% Overall',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: t.brand,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SliverPadding(
              padding: EdgeInsets.only(top: 8)),

          // ── Section 1: Body Diagram ────────────────────────────────────
          SliverPadding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverToBoxAdapter(
              child: _SectionHeader(
                  label: 'FULL BODY MAP', theme: t),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            sliver: SliverToBoxAdapter(
              child: GlassmorphicCard(
                borderRadius: 24,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                      16, 16, 16, 12),
                  child: Column(
                    children: [
                      // Description
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          'Major muscle groups highlighted from training exposure, measurements, recovery, and protein support.',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: t.textMuted,
                            height: 1.4,
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 520,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4),
                          child: BodyDiagramWidget(
                            muscles: widget.muscles,
                            theme: t,
                            showLabels: true,
                            onMuscleTap: (muscle) {
                              setState(() =>
                                  _selectedMuscleId =
                                      muscle.id);
                              _showMuscleDetail(
                                  context, muscle, t);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      MuscleScoreChipRow(
                        muscles: widget.muscles,
                        theme: t,
                        selectedId: _selectedMuscleId,
                        onTap: (muscle) {
                          setState(() =>
                              _selectedMuscleId = muscle.id);
                          _showMuscleDetail(
                              context, muscle, t);
                        },
                      ),
                    ],
                  ),
                ),
              )
                  .animate()
                  .fadeIn(duration: 400.ms)
                  .slideY(begin: 0.04),
            ),
          ),

          // ── Section 2: Overall Performance ────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
            sliver: SliverToBoxAdapter(
              child: _SectionHeader(
                  label: 'OVERALL PERFORMANCE', theme: t),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            sliver: SliverToBoxAdapter(
              child: GlassmorphicCard(
                borderRadius: 24,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      CircularGauge(
                        value: (overallScore / 100)
                            .clamp(0.0, 1.0),
                        size: 110,
                        strokeWidth: 10,
                        centerText:
                            '${overallScore.round()}',
                        label: 'Score',
                        gradientColors: [
                          t.brand,
                          t.success
                        ],
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            _PerformanceRow(
                              icon: Icons
                                  .calendar_today_rounded,
                              label: 'Monthly Attendance',
                              value: attendanceAsync.when(
                                data: (v) => '$v days',
                                loading: () => '...',
                                error: (_, __) => '—',
                              ),
                              color: t.info,
                              theme: t,
                            ),
                            const SizedBox(height: 12),
                            _PerformanceRow(
                              icon: Icons
                                  .fitness_center_rounded,
                              label: 'Weekly Frequency',
                              value: '$weeklyFreq× / week',
                              color: t.accent,
                              theme: t,
                            ),
                            const SizedBox(height: 12),
                            _PerformanceRow(
                              icon: Icons
                                  .trending_up_rounded,
                              label: 'Muscles Tracked',
                              value:
                                  '${widget.muscles.length} groups',
                              color: t.success,
                              theme: t,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              )
                  .animate(delay: 80.ms)
                  .fadeIn(duration: 300.ms)
                  .slideY(begin: 0.04),
            ),
          ),

          // ── Section 3: Nutrition ───────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
            sliver: SliverToBoxAdapter(
              child: _SectionHeader(
                  label: 'NUTRITION OVERVIEW', theme: t),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            sliver: SliverToBoxAdapter(
              child: dietAsync.when(
                loading: () => const SizedBox(
                    height: 80,
                    child: Center(
                        child: CircularProgressIndicator())),
                error: (_, __) =>
                    _NutritionEmptyState(theme: t),
                data: (plan) => plan == null
                    ? _NutritionEmptyState(theme: t)
                    : GlassmorphicCard(
                        borderRadius: 24,
                        child: Padding(
                          padding:
                              const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment:
                                    CrossAxisAlignment
                                        .start,
                                children: [
                                  // Calorie ring
                                  CircularGauge(
                                    value: (plan
                                                .targetCalories >
                                            0)
                                        ? (plan.actualCalories /
                                                plan.targetCalories)
                                            .clamp(
                                                0.0, 1.0)
                                        : 0.0,
                                    size: 90,
                                    strokeWidth: 8,
                                    centerText:
                                        '${plan.actualCalories}',
                                    label: 'kcal',
                                    gradientColors: [
                                      t.warning,
                                      t.brand
                                    ],
                                  ),
                                  const SizedBox(
                                      width: 20),
                                  // Macro bars
                                  Expanded(
                                    child: MacroProgressBar(
                                      proteinG: plan
                                          .actualProtein
                                          .toDouble(),
                                      carbsG: 0,
                                      fatG: 0,
                                      proteinGoalG: plan
                                          .targetProtein
                                          .toDouble(),
                                      carbsGoalG: plan
                                          .targetCarbs
                                          .toDouble(),
                                      fatGoalG: plan
                                          .targetFat
                                          .toDouble(),
                                    ),
                                  ),
                                ],
                              ),
                              // Protein adequacy warning
                              if (plan.targetProtein > 0 &&
                                  plan.actualProtein /
                                          plan.targetProtein <
                                      0.8) ...[
                                const SizedBox(height: 14),
                                _NutritionWarning(
                                  text:
                                      'Protein intake is below 80% of your target. Prioritise high-protein meals to support muscle recovery.',
                                  theme: t,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
              )
                  .animate(delay: 160.ms)
                  .fadeIn(duration: 300.ms)
                  .slideY(begin: 0.04),
            ),
          ),

          // ── Section 4: Weak Spots ──────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
            sliver: SliverToBoxAdapter(
              child: _SectionHeader(
                  label: 'PRIORITY AREAS', theme: t),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            sliver: SliverList.separated(
              itemCount: weakMuscles.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final m = weakMuscles[i];
                return _WeakMuscleCard(
                  muscle: m,
                  theme: t,
                  onTap: () =>
                      _showMuscleDetail(context, m, t),
                )
                    .animate(delay: (240 + i * 60).ms)
                    .fadeIn(duration: 300.ms)
                    .slideX(begin: 0.05);
              },
            ),
          ),

          // ── Section 5: Workout Routine ─────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
            sliver: SliverToBoxAdapter(
              child: _SectionHeader(
                  label: 'WORKOUT ROUTINE', theme: t),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            sliver: SliverToBoxAdapter(
              child: ref.watch(memberWorkoutPlanProvider).when(
                    loading: () => const SizedBox(
                        height: 60,
                        child: Center(
                            child:
                                CircularProgressIndicator())),
                    error: (_, __) =>
                        _WorkoutEmptyState(theme: t),
                    data: (plan) => plan == null
                        ? _WorkoutEmptyState(theme: t)
                        : _WorkoutRoutineCard(
                            plan: plan, theme: t),
                  )
                  .animate(delay: 400.ms)
                  .fadeIn(duration: 300.ms)
                  .slideY(begin: 0.04),
            ),
          ),

          // ── Nutrition Tips ─────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
            sliver: SliverToBoxAdapter(
              child: _SectionHeader(
                  label: 'EXPERT NUTRITION TIPS', theme: t),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            sliver: SliverToBoxAdapter(
              child: _NutritionTipsCard(theme: t)
                  .animate(delay: 480.ms)
                  .fadeIn(duration: 300.ms)
                  .slideY(begin: 0.04),
            ),
          ),

          const SliverPadding(
              padding: EdgeInsets.only(bottom: 100)),
        ],
      ),
    );
  }

  void _showMuscleDetail(
    BuildContext context,
    MuscleGroupProgress muscle,
    dynamic t,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => buildMuscleDetailSheet(
        context: context,
        muscle: muscle,
        theme: t,
      ),
    );
  }
}

// ─── Section header ──────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  final dynamic theme;

  const _SectionHeader({required this.label, required this.theme});

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: t.textMuted,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

// ─── Performance row ─────────────────────────────────────────────────────────

class _PerformanceRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final dynamic theme;

  const _PerformanceRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 14, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: t.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: t.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Weak muscle card ─────────────────────────────────────────────────────────

class _WeakMuscleCard extends StatelessWidget {
  final MuscleGroupProgress muscle;
  final dynamic theme;
  final VoidCallback onTap;

  const _WeakMuscleCard({
    required this.muscle,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;
    final color = muscle.statusColor(t);

    return GlassmorphicCard(
      borderRadius: 20,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color: color.withOpacity(0.5),
                          blurRadius: 6)
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  muscle.name,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: t.textPrimary,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    muscle.gainPercentLabel,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Icon(Icons.chevron_right_rounded,
                    size: 16, color: t.textMuted),
              ],
            ),
            const SizedBox(height: 10),

            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: muscle.gainPercent,
                minHeight: 6,
                backgroundColor: t.ringTrack,
                valueColor:
                    AlwaysStoppedAnimation<Color>(color),
              ),
            ),

            const SizedBox(height: 10),
            Text(
              muscle.improvementTip,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: t.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 8),

            // Exercise chips
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children:
                  muscle.suggestedExercises.take(3).map((ex) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: t.surfaceAlt,
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: t.border, width: 1),
                  ),
                  child: Text(
                    ex,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: t.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Nutrition empty state ────────────────────────────────────────────────────

class _NutritionEmptyState extends StatelessWidget {
  final dynamic theme;

  const _NutritionEmptyState({required this.theme});

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;
    return GlassmorphicCard(
      borderRadius: 20,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.restaurant_rounded,
                size: 36, color: t.textMuted),
            const SizedBox(height: 12),
            Text(
              'No Diet Plan Assigned',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: t.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Ask your trainer to assign a diet plan to unlock nutrition tracking.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  fontSize: 12,
                  color: t.textMuted,
                  height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Nutrition warning ────────────────────────────────────────────────────────

class _NutritionWarning extends StatelessWidget {
  final String text;
  final dynamic theme;

  const _NutritionWarning({required this.text, required this.theme});

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: t.warning.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: t.warning.withOpacity(0.3), width: 1),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded,
              size: 16, color: t.warning),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                  fontSize: 11,
                  color: t.textSecondary,
                  height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Workout routine card ─────────────────────────────────────────────────────

class _WorkoutRoutineCard extends StatelessWidget {
  final dynamic plan;
  final dynamic theme;

  const _WorkoutRoutineCard({required this.plan, required this.theme});

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;
    // plan is a WorkoutPlan object; show name + goal + days
    return GlassmorphicCard(
      borderRadius: 24,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: t.brand.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.fitness_center_rounded,
                      size: 20, color: t.brand),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        plan.name ?? 'Your Workout Plan',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: t.textPrimary,
                        ),
                      ),
                      if (plan.goal != null)
                        Text(
                          plan.goal
                              .toString()
                              .replaceAll('_', ' ')
                              .toUpperCase(),
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: t.brand,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Muscle groups targeted
            if (plan.targetMuscleGroups != null &&
                (plan.targetMuscleGroups as List).isNotEmpty) ...[
              Text(
                'TARGET MUSCLES',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: t.textMuted,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: (plan.targetMuscleGroups as List)
                    .take(6)
                    .map<Widget>((mg) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: t.brand.withOpacity(0.10),
                      borderRadius:
                          BorderRadius.circular(16),
                      border: Border.all(
                          color: t.brand.withOpacity(0.25),
                          width: 1),
                    ),
                    child: Text(
                      mg.toString().replaceAll('_', ' '),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: t.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ] else ...[
              Text(
                'Your trainer has assigned a workout plan.\nTap Workouts to see the full schedule.',
                style: GoogleFonts.inter(
                    fontSize: 12,
                    color: t.textSecondary,
                    height: 1.5),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Workout empty state ──────────────────────────────────────────────────────

class _WorkoutEmptyState extends StatelessWidget {
  final dynamic theme;

  const _WorkoutEmptyState({required this.theme});

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;
    return GlassmorphicCard(
      borderRadius: 20,
      onTap: () => context.go('/member/workout'),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.fitness_center_rounded,
                size: 36, color: t.textMuted),
            const SizedBox(height: 12),
            Text(
              'No Workout Plan Yet',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: t.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Tap to view workouts or ask your trainer for a personalised plan.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  fontSize: 12,
                  color: t.textMuted,
                  height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Nutrition tips card ──────────────────────────────────────────────────────

class _NutritionTipsCard extends StatelessWidget {
  final dynamic theme;

  const _NutritionTipsCard({required this.theme});

  static const _tips = [
    (
      icon: Icons.egg_alt_rounded,
      title: 'Protein Timing',
      tip:
          'Consume 20–40g of protein within 2 hours post-workout. Leucine-rich sources (whey, eggs, chicken) trigger peak muscle protein synthesis.',
    ),
    (
      icon: Icons.water_drop_rounded,
      title: 'Hydration',
      tip:
          'Even 2% dehydration reduces strength output by up to 10%. Aim for 35ml of water per kg of bodyweight daily.',
    ),
    (
      icon: Icons.nightlight_rounded,
      title: 'Sleep & Recovery',
      tip:
          'The majority of muscle repair happens during deep sleep. 7–9 hours per night is non-negotiable for serious gains.',
    ),
    (
      icon: Icons.grain_rounded,
      title: 'Carb Strategy',
      tip:
          'Place your highest-carb meals around your workout window (pre + post). Carbs replenish glycogen and improve training performance.',
    ),
    (
      icon: Icons.scale_rounded,
      title: 'Caloric Surplus',
      tip:
          'A moderate surplus of 200–300 kcal/day over TDEE maximises muscle gain while minimising fat accumulation. Track weekly weight trends.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;
    return GlassmorphicCard(
      borderRadius: 24,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: _tips.map((tip) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: t.accent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(tip.icon,
                        size: 16, color: t.accent),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          tip.title,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: t.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          tip.tip,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: t.textSecondary,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
