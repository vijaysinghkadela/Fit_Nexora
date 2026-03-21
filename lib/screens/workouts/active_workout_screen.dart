import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/extensions.dart';
import '../../models/workout_plan_model.dart';
import '../../providers/member_provider.dart';
import '../../widgets/glassmorphic_card.dart';
import '../../widgets/workout_set_tracker.dart';
import '../../widgets/add_pr_sheet.dart';

/// Active workout screen — live exercise logging with timer.
/// Route: `/workout/active`
class ActiveWorkoutScreen extends ConsumerStatefulWidget {
  const ActiveWorkoutScreen({super.key});

  @override
  ConsumerState<ActiveWorkoutScreen> createState() =>
      _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends ConsumerState<ActiveWorkoutScreen>
    with SingleTickerProviderStateMixin {
  final _weightController = TextEditingController(text: '0');
  final _repsController = TextEditingController(text: '0');

  // Workout timer state
  int _elapsedSeconds = 0;
  Timer? _workoutTimer;

  // Set state
  int _currentExerciseIndex = 0;
  int _completedSets = 0;
  int _currentSet = 1;

  // Live badge pulse
  late AnimationController _livePulseController;
  late Animation<double> _livePulseAnimation;

  @override
  void initState() {
    super.initState();
    _livePulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _livePulseAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _livePulseController, curve: Curves.easeInOut),
    );
    _workoutTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsedSeconds++);
    });
  }

  @override
  void dispose() {
    _weightController.dispose();
    _repsController.dispose();
    _workoutTimer?.cancel();
    _livePulseController.dispose();
    super.dispose();
  }

  String get _formattedTime {
    final m = (_elapsedSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (_elapsedSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String _extractReps(String raw) {
    final match = RegExp(r'\d+').firstMatch(raw);
    if (match != null) return match.group(0)!;
    return '10';
  }

  void _nextSet(List<Exercise> exercises) {
    if (exercises.isEmpty) return;
    // Clamp index in case exercises list changed between frames
    if (_currentExerciseIndex >= exercises.length) {
      setState(() => _currentExerciseIndex = 0);
      return;
    }
    final ex = exercises[_currentExerciseIndex];
    FocusScope.of(context).unfocus();

    setState(() {
      if (_completedSets < ex.sets) {
        _completedSets++;
        if (_completedSets == ex.sets) {
          // Finished exercise
          if (_currentExerciseIndex < exercises.length - 1) {
            _currentExerciseIndex++;
            _completedSets = 0;
            _currentSet = 1;
            final nextEx = exercises[_currentExerciseIndex];
            _repsController.text = _extractReps(nextEx.reps);
            context.push('/workout/timer');
          } else {
            // Workout done
            context.push('/workout/done');
          }
        } else {
          _currentSet = _completedSets + 1;
          context.push('/workout/timer');
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;
    final planAsync = ref.watch(memberWorkoutPlanProvider);

    return Scaffold(
      backgroundColor: t.background,
      body: planAsync.when(
        loading: () => Center(child: CircularProgressIndicator(color: t.brand)),
        error: (e, _) => Center(child: Text('Error: $e', style: GoogleFonts.inter(color: t.danger))),
        data: (plan) {
          if (plan == null || plan.days.isEmpty) {
            return _buildNoPlanFallback(t);
          }

          final today = DateTime.now().weekday;
          final currentDayIndex = ((today - 1) % plan.days.length);
          final dayPlan = plan.days[currentDayIndex];
          final exercises = dayPlan.exercises;

          if (exercises.isEmpty) {
            return _buildNoExercisesFallback(t, dayPlan.dayName);
          }

          // Clamp the index to valid range to avoid RangeError
          final safeIndex = _currentExerciseIndex.clamp(0, exercises.length - 1);
          if (safeIndex != _currentExerciseIndex) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _currentExerciseIndex = safeIndex);
            });
          }
          final ex = exercises[safeIndex];

          if (_repsController.text == '0') {
             _repsController.text = _extractReps(ex.reps);
          }

          return CustomScrollView(
            slivers: [
              // ── App Bar ──────────────────────────────────────────────────────
              SliverAppBar(
                pinned: true,
                backgroundColor: t.surface,
                leading: IconButton(
                  icon: Icon(Icons.arrow_back_rounded, color: t.textPrimary),
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/dashboard');
                    }
                  },
                ),
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dayPlan.dayName,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: t.textPrimary,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          _formattedTime,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: t.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _LiveBadge(
                          pulseAnimation: _livePulseAnimation,
                          accentColor: t.accent,
                        ),
                      ],
                    ),
                  ],
                ),
                actions: [
                  IconButton(
                    icon: Icon(Icons.more_vert_rounded, color: t.textSecondary),
                    onPressed: () {},
                  ),
                ],
              ),

              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // ── Exercise Card ─────────────────────────────────────────
                    _ExerciseHeroCard(
                      exercise: ex,
                      currentIndex: safeIndex,
                      total: exercises.length,
                    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),

                    const SizedBox(height: 16),

                    // ── Set Tracker ──────────────────────────────────────────
                    _buildTracker(t, ex.sets),

                    const SizedBox(height: 12),

                    // ── Weight & Reps Input ──────────────────────────────────
                    _buildInputs(t),

                    const SizedBox(height: 12),

                    // ── Advanced Metrics ─────────────────────────────────────
                    if (ex.tempo != null || ex.rpe != null || ex.setTime != null || ex.supersetGroupId != null)
                      _buildAdvancedMetrics(t, ex),

                    if (ex.tempo != null || ex.rpe != null || ex.setTime != null || ex.supersetGroupId != null)
                      const SizedBox(height: 12),

                    // ── Previous Set Data ────────────────────────────────────
                    _buildPreviousSet(t, ex),

                    const SizedBox(height: 24),

                    // ── Action Buttons ────────────────────────────────────────
                    _buildActionButtons(t, exercises),

                    const SizedBox(height: 32),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildNoPlanFallback(dynamic t) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.monitor_heart_outlined, size: 64, color: t.textSecondary.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(
            'No Active Plan',
            style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: t.textPrimary),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.go('/member'),
            child: const Text('Go Home'),
          ),
        ],
      ),
    );
  }

  Widget _buildNoExercisesFallback(dynamic t, String dayName) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.directions_run_rounded, size: 64, color: t.textSecondary.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(
            'Rest Day: $dayName',
            style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: t.textPrimary),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.go('/member'),
            child: const Text('Go Home'),
          ),
        ],
      ),
    );
  }

  Widget _buildTracker(dynamic t, int totalSets) {
    return GlassmorphicCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sets',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: t.textMuted,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                WorkoutSetTracker(
                  totalSets: totalSets,
                  completedSets: _completedSets,
                  currentSet: _currentSet,
                  dotSize: 14,
                ),
                const SizedBox(width: 12),
                Text(
                  'Set $_currentSet of $totalSets',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: t.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate(delay: 100.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1);
  }

  Widget _buildAdvancedMetrics(dynamic t, Exercise ex) {
    return GlassmorphicCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Workout Targets',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: t.textMuted,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (ex.rpe != null)
                  _DetailChip(label: 'RPE ${ex.rpe}', icon: Icons.speed_rounded, color: t.brand),
                if (ex.tempo != null && ex.tempo!.isNotEmpty)
                  _DetailChip(label: 'Tempo ${ex.tempo}', icon: Icons.hourglass_bottom_rounded, color: t.info),
                if (ex.setTime != null && ex.setTime!.isNotEmpty)
                  _DetailChip(label: 'Time: ${ex.setTime}', icon: Icons.timer_outlined, color: t.warning),
                if (ex.supersetGroupId != null && ex.supersetGroupId!.isNotEmpty)
                  _DetailChip(label: 'Superset ${ex.supersetGroupId}', icon: Icons.link_rounded, color: t.accent),
              ],
            ),
          ],
        ),
      ),
    ).animate(delay: 175.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1);
  }

  Widget _buildInputs(dynamic t) {
    return Row(
      children: [
        Expanded(
          child: GlassmorphicCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Weight (kg)',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: t.textMuted,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _weightController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: t.textPrimary,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _StepButton(
                        icon: Icons.remove,
                        color: t.textMuted,
                        onTap: () {
                          final v = double.tryParse(_weightController.text) ?? 0;
                          _weightController.text = (v - 2.5).clamp(0, 999).toString();
                        },
                      ),
                      _StepButton(
                        icon: Icons.add,
                        color: t.brand,
                        onTap: () {
                          final v = double.tryParse(_weightController.text) ?? 0;
                          _weightController.text = (v + 2.5).toString();
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GlassmorphicCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Reps',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: t.textMuted,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _repsController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: t.textPrimary,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _StepButton(
                        icon: Icons.remove,
                        color: t.textMuted,
                        onTap: () {
                          final v = int.tryParse(_repsController.text) ?? 0;
                          _repsController.text = (v - 1).clamp(0, 999).toString();
                        },
                      ),
                      _StepButton(
                        icon: Icons.add,
                        color: t.accent,
                        onTap: () {
                          final v = int.tryParse(_repsController.text) ?? 0;
                          _repsController.text = (v + 1).toString();
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ).animate(delay: 150.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1);
  }

  Widget _buildPreviousSet(dynamic t, Exercise ex) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: t.surfaceMuted,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: t.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Target per Set',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: t.textMuted,
            ),
          ),
          Row(
            children: [
              _PrevSetChip(label: ex.reps, icon: Icons.repeat_rounded, color: t.accent),
              const SizedBox(width: 8),
              _PrevSetChip(label: '${ex.restSeconds}s rest', icon: Icons.timer_outlined, color: t.brand),
            ],
          ),
        ],
      ),
    ).animate(delay: 200.ms).fadeIn(duration: 400.ms);
  }

  Widget _buildActionButtons(dynamic t, List<Exercise> exercises) {
    if (exercises.isEmpty) return const SizedBox.shrink();
    final safeIdx = _currentExerciseIndex.clamp(0, exercises.length - 1);
    final ex = exercises[safeIdx];
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: () => context.push('/workout/timer'),
                icon: const Icon(Icons.timer_outlined, size: 16),
                label: Text(
                  'START REST',
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: t.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _nextSet(exercises),
                icon: Icon(Icons.skip_next_rounded, size: 16, color: t.textPrimary),
                label: Text(
                  'NEXT',
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: t.textPrimary),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: t.border),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  final weight = double.tryParse(_weightController.text);
                  final reps = int.tryParse(_repsController.text);
                  AddPRSheet.show(context, exercise: ex.name, weight: weight, reps: reps);
                },
                icon: Icon(Icons.emoji_events_rounded, size: 16, color: t.warning),
                label: Text(
                  'LOG PR',
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: t.warning),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: t.warning.withOpacity(0.5)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: () => context.push('/workout/done'),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: t.danger),
                  foregroundColor: t.danger,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'FINISH WORKOUT',
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ],
    ).animate(delay: 250.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1);
  }
}

class _DetailChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _DetailChip({
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveBadge extends StatelessWidget {
  final Animation<double> pulseAnimation;
  final Color accentColor;

  const _LiveBadge({
    required this.pulseAnimation,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: accentColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: accentColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: pulseAnimation,
            builder: (context, _) {
              return Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accentColor.withOpacity(pulseAnimation.value),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withOpacity(pulseAnimation.value * 0.5),
                      blurRadius: 4,
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(width: 4),
          Text(
            'LIVE',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: accentColor,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExerciseHeroCard extends StatelessWidget {
  final Exercise exercise;
  final int currentIndex;
  final int total;

  const _ExerciseHeroCard({
    required this.exercise,
    required this.currentIndex,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;

    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            t.brand.withOpacity(0.3),
            t.accent.withOpacity(0.15),
          ],
        ),
        border: Border.all(color: t.glassBorder),
      ),
      child: Stack(
        children: [
          // Background pattern
          Positioned(
            right: -20,
            top: -20,
            child: Icon(
              Icons.fitness_center_rounded,
              size: 160,
              color: t.brand.withOpacity(0.06),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (exercise.intensity != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: t.brand.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: t.brand.withOpacity(0.4)),
                    ),
                    child: Text(
                      exercise.intensity!.toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: t.brand,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                Text(
                  exercise.name,
                  style: GoogleFonts.inter(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: t.textPrimary,
                    height: 1.15,
                    letterSpacing: -0.5,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                Wrap(
                  spacing: 8,
                  children: [
                    if (exercise.equipment != null && exercise.equipment!.isNotEmpty)
                      _MuscleBadge(label: exercise.equipment!, color: t.info),
                    _MuscleBadge(label: '${exercise.sets} × ${exercise.reps}', color: t.accent),
                  ],
                ),
              ],
            ),
          ),
          // Exercise number indicator
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: t.surface.withOpacity(0.8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${currentIndex + 1} / $total',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: t.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MuscleBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _MuscleBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _StepButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }
}

class _PrevSetChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _PrevSetChip({
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
