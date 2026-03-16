import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/extensions.dart';
import '../../widgets/glassmorphic_card.dart';
import '../../widgets/workout_set_tracker.dart';

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
  final _weightController = TextEditingController(text: '80');
  final _repsController = TextEditingController(text: '10');

  // Workout timer state
  int _elapsedSeconds = 2538; // 42:18
  Timer? _workoutTimer;

  // Set state
  int _completedSets = 1;
  final int _totalSets = 3;
  int _currentSet = 2;

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

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;

    return Scaffold(
      backgroundColor: t.background,
      body: CustomScrollView(
        slivers: [
          // ── App Bar ──────────────────────────────────────────────────────
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
                  'Push Day A',
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
                _ExerciseHeroCard().animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),

                const SizedBox(height: 16),

                // ── Set Tracker ──────────────────────────────────────────
                GlassmorphicCard(
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
                              totalSets: _totalSets,
                              completedSets: _completedSets,
                              currentSet: _currentSet,
                              dotSize: 14,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Set $_currentSet of $_totalSets',
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
                ).animate(delay: 100.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1),

                const SizedBox(height: 12),

                // ── Weight & Reps Input ──────────────────────────────────
                Row(
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
                                      final v = double.tryParse(
                                              _weightController.text) ??
                                          0;
                                      _weightController.text =
                                          (v - 2.5).clamp(0, 999).toString();
                                    },
                                  ),
                                  _StepButton(
                                    icon: Icons.add,
                                    color: t.brand,
                                    onTap: () {
                                      final v = double.tryParse(
                                              _weightController.text) ??
                                          0;
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
                                      final v = int.tryParse(
                                              _repsController.text) ??
                                          0;
                                      _repsController.text =
                                          (v - 1).clamp(0, 999).toString();
                                    },
                                  ),
                                  _StepButton(
                                    icon: Icons.add,
                                    color: t.accent,
                                    onTap: () {
                                      final v = int.tryParse(
                                              _repsController.text) ??
                                          0;
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
                ).animate(delay: 150.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1),

                const SizedBox(height: 12),

                // ── Previous Set Data ────────────────────────────────────
                Container(
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
                        'Previous Set',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: t.textMuted,
                        ),
                      ),
                      Row(
                        children: [
                          _PrevSetChip(label: '77.5 kg', icon: Icons.fitness_center_rounded, color: t.brand),
                          const SizedBox(width: 8),
                          _PrevSetChip(label: '10 reps', icon: Icons.repeat_rounded, color: t.accent),
                        ],
                      ),
                    ],
                  ),
                ).animate(delay: 200.ms).fadeIn(duration: 400.ms),

                const SizedBox(height: 24),

                // ── Action Buttons ────────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () =>
                            Navigator.pushNamed(context, '/workout/timer'),
                        icon: const Icon(Icons.timer_outlined, size: 16),
                        label: Text(
                          'START REST',
                          style: GoogleFonts.inter(
                              fontSize: 13, fontWeight: FontWeight.w700),
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
                        onPressed: () {
                          setState(() {
                            if (_completedSets < _totalSets) {
                              _completedSets++;
                              _currentSet = _completedSets + 1;
                            }
                          });
                        },
                        icon: Icon(Icons.skip_next_rounded,
                            size: 16, color: t.textPrimary),
                        label: Text(
                          'NEXT',
                          style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: t.textPrimary),
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
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () =>
                          Navigator.pushNamed(context, '/workout/done'),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: t.danger),
                        foregroundColor: t.danger,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        'FINISH',
                        style: GoogleFonts.inter(
                            fontSize: 13, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ).animate(delay: 250.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1),

                const SizedBox(height: 32),
              ]),
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
        color: accentColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: accentColor.withValues(alpha: 0.3)),
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
                  color: accentColor
                      .withValues(alpha: pulseAnimation.value),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor
                          .withValues(alpha: pulseAnimation.value * 0.5),
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
            t.brand.withValues(alpha: 0.3),
            t.accent.withValues(alpha: 0.15),
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
              color: t.brand.withValues(alpha: 0.06),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: t.brand.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: t.brand.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    'CHEST • COMPOUND',
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
                  'Barbell Bench\nPress',
                  style: GoogleFonts.inter(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: t.textPrimary,
                    height: 1.15,
                    letterSpacing: -0.5,
                  ),
                ),
                const Spacer(),
                Wrap(
                  spacing: 8,
                  children: [
                    _MuscleBadge(label: 'Pectorals', color: t.info),
                    _MuscleBadge(label: 'Triceps', color: t.accent),
                    _MuscleBadge(label: 'Deltoids', color: t.warning),
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
                color: t.surface.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '2 / 6',
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
        color: color.withValues(alpha: 0.15),
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
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
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
