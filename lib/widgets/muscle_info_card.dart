// lib/widgets/muscle_info_card.dart
//
// Expandable card shown when a muscle is selected on the body map.
// Displays development %, recovery status, protein score, training frequency,
// and top PRs for exercises that target this muscle.

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/extensions.dart';
import '../providers/personal_records_provider.dart';
import 'body_map_widget.dart';
import 'body_anatomy_painter.dart';
import 'glassmorphic_card.dart';

// ─── Muscle → exercises map ───────────────────────────────────────────────────

const kMuscleExercises = <String, List<String>>{
  // ── Front ────────────────────────────────────────────────────────────────
  'neck_left':            ['Lateral Neck Stretch', 'Deadlift', 'Shrug'],
  'neck_right':           ['Lateral Neck Stretch', 'Deadlift', 'Shrug'],
  'pec_upper':            ['Incline Bench Press', 'Cable Fly', 'Push Up'],
  'pec_lower':            ['Bench Press', 'Decline Press', 'Chest Dip'],
  'delt_left':            ['Overhead Press', 'Front Raise', 'Arnold Press'],
  'delt_right':           ['Overhead Press', 'Front Raise', 'Arnold Press'],
  'serratus_left':        ['Push Up Plus', 'Cable Serratus Crunch', 'Dips'],
  'serratus_right':       ['Push Up Plus', 'Cable Serratus Crunch', 'Dips'],
  'bicep_left':           ['Bicep Curl', 'Hammer Curl', 'Chin Up'],
  'bicep_right':          ['Bicep Curl', 'Hammer Curl', 'Chin Up'],
  'forearm_left':         ['Wrist Curl', 'Reverse Curl', 'Farmer Walk'],
  'forearm_right':        ['Wrist Curl', 'Reverse Curl', 'Farmer Walk'],
  'abs':                  ['Crunch', 'Plank', 'Leg Raise', 'Cable Crunch'],
  'oblique_left':         ['Russian Twist', 'Side Plank', 'Bicycle Crunch'],
  'oblique_right':        ['Russian Twist', 'Side Plank', 'Bicycle Crunch'],
  'sartorius_left':       ['Lunge', 'Step Up', 'Hip Flexor Stretch'],
  'sartorius_right':      ['Lunge', 'Step Up', 'Hip Flexor Stretch'],
  'adductor_left':        ['Sumo Squat', 'Cable Adduction', 'Side Lunge'],
  'adductor_right':       ['Sumo Squat', 'Cable Adduction', 'Side Lunge'],
  'quad_left':            ['Squat', 'Leg Press', 'Lunge', 'Leg Extension'],
  'quad_right':           ['Squat', 'Leg Press', 'Lunge', 'Leg Extension'],
  'tibialis_left':        ['Tibialis Raise', 'Jump Rope', 'Box Jump'],
  'tibialis_right':       ['Tibialis Raise', 'Jump Rope', 'Box Jump'],
  'soleus_front_left':    ['Seated Calf Raise', 'Donkey Calf Raise'],
  'soleus_front_right':   ['Seated Calf Raise', 'Donkey Calf Raise'],
  // ── Back ─────────────────────────────────────────────────────────────────
  'trap':                 ['Barbell Row', 'Shrug', 'Deadlift', 'Face Pull'],
  'rear_delt_left':       ['Reverse Fly', 'Face Pull', 'Band Pull-Apart'],
  'rear_delt_right':      ['Reverse Fly', 'Face Pull', 'Band Pull-Apart'],
  'infraspinatus_left':   ['Reverse Fly', 'External Rotation', 'Face Pull'],
  'infraspinatus_right':  ['Reverse Fly', 'External Rotation', 'Face Pull'],
  'teres_left':           ['Pull Up', 'Straight Arm Pulldown', 'Lat Pulldown'],
  'teres_right':          ['Pull Up', 'Straight Arm Pulldown', 'Lat Pulldown'],
  'rhomboid':             ['Bent Over Row', 'Face Pull', 'Band Pull-Apart'],
  'lat_left':             ['Pull Up', 'Lat Pulldown', 'Seated Cable Row'],
  'lat_right':            ['Pull Up', 'Lat Pulldown', 'Seated Cable Row'],
  'tricep_left':          ['Tricep Pushdown', 'Skull Crusher', 'Dips'],
  'tricep_right':         ['Tricep Pushdown', 'Skull Crusher', 'Dips'],
  'lower_back':           ['Deadlift', 'Back Extension', 'Good Morning'],
  'glute_med_left':       ['Hip Abduction', 'Clamshell', 'Side-Lying Leg Raise'],
  'glute_med_right':      ['Hip Abduction', 'Clamshell', 'Side-Lying Leg Raise'],
  'glute_left':           ['Hip Thrust', 'Glute Bridge', 'Sumo Squat'],
  'glute_right':          ['Hip Thrust', 'Glute Bridge', 'Sumo Squat'],
  'ham_left':             ['Romanian Deadlift', 'Leg Curl', 'Good Morning'],
  'ham_right':            ['Romanian Deadlift', 'Leg Curl', 'Good Morning'],
  'calf_left':            ['Calf Raise', 'Standing Calf Raise', 'Donkey Calf'],
  'calf_right':           ['Calf Raise', 'Standing Calf Raise', 'Donkey Calf'],
  'soleus_left':          ['Seated Calf Raise', 'Donkey Calf Raise'],
  'soleus_right':         ['Seated Calf Raise', 'Donkey Calf Raise'],
};

// ─── State badge color / label ────────────────────────────────────────────────

Color _badgeColor(MuscleState s, Color brand) {
  switch (s) {
    case MuscleState.untrained: return const Color(0xFF6B7280);
    case MuscleState.recovery:  return const Color(0xFF4FC3F7);
    case MuscleState.moderate:  return brand.withOpacity(0.75);
    case MuscleState.active:    return brand;
    case MuscleState.intense:   return const Color(0xFFEF4444);
  }
}

String _badgeLabel(MuscleState s) => kMuscleStateLabel[s] ?? 'Unknown';

// ─── Widget ───────────────────────────────────────────────────────────────────

class MuscleInfoCard extends ConsumerWidget {
  final String muscleId;
  final MuscleData data;

  const MuscleInfoCard({
    required this.muscleId,
    required this.data,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.fitTheme;
    final displayName =
        kMuscleDisplayName[muscleId] ?? _prettify(muscleId);
    final exercises = kMuscleExercises[muscleId] ?? [];
    final allPrs = ref.watch(personalRecordsProvider).valueOrNull ?? [];

    // Filter PRs to exercises that target this muscle
    final musclePrs = allPrs
        .where((pr) => exercises
            .any((ex) => ex.toLowerCase().contains(
                pr.exerciseName.toLowerCase().split(' ').first)))
        .take(3)
        .toList();

    return GlassmorphicCard(
      borderRadius: 20,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ────────────────────────────────────────────────
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: t.brand.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.accessibility_new_rounded,
                      color: t.brand, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: t.textPrimary,
                        ),
                      ),
                      if (data.lastTrained != null)
                        Text(
                          'Last trained ${data.lastTrained}',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: t.textMuted,
                          ),
                        ),
                    ],
                  ),
                ),
                // State badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _badgeColor(data.state, t.brand).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _badgeColor(data.state, t.brand).withOpacity(0.50),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(kMuscleStateIcon[data.state],
                          size: 12,
                          color: _badgeColor(data.state, t.brand)),
                      const SizedBox(width: 4),
                      Text(
                        _badgeLabel(data.state),
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: _badgeColor(data.state, t.brand),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            Divider(color: t.divider, height: 1),
            const SizedBox(height: 14),

            // ── Progress bars ─────────────────────────────────────────
            _ProgressRow(
              label: 'Development',
              value: data.developmentPercent / 100,
              percent: data.developmentPercent,
              color: t.brand,
              icon: Icons.trending_up_rounded,
              t: t,
            ),
            const SizedBox(height: 10),
            _ProgressRow(
              label: 'Recovery',
              value: data.recoveryPercent / 100,
              percent: data.recoveryPercent,
              color: const Color(0xFF4FC3F7),
              icon: Icons.water_drop_rounded,
              t: t,
            ),
            const SizedBox(height: 10),
            _ProgressRow(
              label: 'Protein Support',
              value: data.proteinScore / 100,
              percent: data.proteinScore,
              color: const Color(0xFF4CAF50),
              icon: Icons.egg_alt_rounded,
              t: t,
            ),

            const SizedBox(height: 14),

            // ── Training frequency ────────────────────────────────────
            Row(
              children: [
                Icon(Icons.calendar_month_rounded,
                    size: 14, color: t.textMuted),
                const SizedBox(width: 6),
                Text(
                  'Trained ${data.trainingCountMonth}× this month',
                  style: GoogleFonts.inter(
                      fontSize: 12, color: t.textSecondary),
                ),
              ],
            ),

            if (musclePrs.isNotEmpty) ...[
              const SizedBox(height: 14),
              Divider(color: t.divider, height: 1),
              const SizedBox(height: 10),
              Text(
                'TOP PERSONAL RECORDS',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: t.textMuted,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 8),
              ...musclePrs.map((pr) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Icon(Icons.emoji_events_rounded,
                            size: 14, color: t.warning),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            pr.exerciseName,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: t.textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${pr.weightKg.toStringAsFixed(1)} kg × ${pr.reps}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: t.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  )),
            ],

            const SizedBox(height: 14),

            // ── Action buttons ────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    label: 'Log Measurement',
                    icon: Icons.straighten_rounded,
                    color: t.info,
                    onTap: () => context.push('/health/body-measurements'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ActionButton(
                    label: 'View Records',
                    icon: Icons.bar_chart_rounded,
                    color: t.brand,
                    onTap: () =>
                        context.push('/workout/personal-records'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05);
  }

  String _prettify(String id) => id
      .replaceAll('_', ' ')
      .split(' ')
      .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

class _ProgressRow extends StatelessWidget {
  final String label;
  final double value;
  final double percent;
  final Color color;
  final IconData icon;
  final dynamic t;

  const _ProgressRow({
    required this.label,
    required this.value,
    required this.percent,
    required this.color,
    required this.icon,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.fitTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 5),
            Text(
              label,
              style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: colors.textSecondary),
            ),
            const Spacer(),
            Text(
              '${percent.toStringAsFixed(0)}%',
              style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: color),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value.clamp(0.0, 1.0),
            minHeight: 6,
            backgroundColor: color.withOpacity(0.12),
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.10),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.35)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
