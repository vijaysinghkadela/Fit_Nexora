// lib/models/muscle_group_model.dart
import 'package:flutter/material.dart';
import '../config/theme.dart';

enum MuscleSide { front, back }

enum MuscleStatus { strong, moderate, needsWork }

/// A single muscle group's computed progress for the body diagram.
/// All coordinates are normalized: x / 200, y / 480 of the logical canvas.
class MuscleGroupProgress {
  final String id;
  final String name;
  final MuscleSide side;
  final double gainPercent; // 0.0–1.0
  final MuscleStatus status;
  final String improvementTip;
  final List<String> suggestedExercises;
  final Rect normalizedBounds;
  final Offset normalizedCenter;

  const MuscleGroupProgress({
    required this.id,
    required this.name,
    required this.side,
    required this.gainPercent,
    required this.status,
    required this.improvementTip,
    required this.suggestedExercises,
    required this.normalizedBounds,
    required this.normalizedCenter,
  });

  Color statusColor(FitNexoraThemeTokens t) => switch (status) {
        MuscleStatus.strong => t.success,
        MuscleStatus.moderate => t.warning,
        MuscleStatus.needsWork => t.danger,
      };

  String get statusLabel => switch (status) {
        MuscleStatus.strong => 'Strong',
        MuscleStatus.moderate => 'Developing',
        MuscleStatus.needsWork => 'Needs Work',
      };

  String get gainPercentLabel =>
      '${(gainPercent * 100).round()}%';

  /// Returns a copy with a different gainPercent (and derived status).
  MuscleGroupProgress copyWithScore(double score) {
    final clampedScore = score.clamp(0.0, 1.0);
    final newStatus = clampedScore >= 0.70
        ? MuscleStatus.strong
        : clampedScore >= 0.40
            ? MuscleStatus.moderate
            : MuscleStatus.needsWork;
    return MuscleGroupProgress(
      id: id,
      name: name,
      side: side,
      gainPercent: clampedScore,
      status: newStatus,
      improvementTip: improvementTip,
      suggestedExercises: suggestedExercises,
      normalizedBounds: normalizedBounds,
      normalizedCenter: normalizedCenter,
    );
  }
}

// ─── Default muscle definitions ─────────────────────────────────────────────
// Coordinates in logical 200×480 space, normalized to 0.0–1.0

List<MuscleGroupProgress> buildDefaultMuscles() => [
      // ── FRONT ────────────────────────────────────────────────────────────
      // ── FRONT ────────────────────────────────────────────────────────────
      // Bounds match anatomical bezier paths in lib/data/muscle_paths.dart
      const MuscleGroupProgress(
        id: 'neck',
        name: 'Neck',
        side: MuscleSide.front,
        gainPercent: 0.35,
        status: MuscleStatus.needsWork,
        improvementTip:
            'Neck harness work and shoulder shrugs strengthen posture and injury resistance.',
        suggestedExercises: ['Neck Harness', 'Shrugs', 'Rear Delt Fly'],
        normalizedBounds:
            Rect.fromLTWH(0.44, 0.092, 0.12, 0.035),
        normalizedCenter: Offset(0.50, 0.107),
      ),
      const MuscleGroupProgress(
        id: 'shoulders_front',
        name: 'Shoulders',
        side: MuscleSide.front,
        gainPercent: 0.35,
        status: MuscleStatus.needsWork,
        improvementTip:
            'Lateral raises 3–4×/week. Don\'t neglect rear delts — face pulls for shoulder health.',
        suggestedExercises: [
          'Lateral Raise',
          'OHP',
          'Arnold Press',
          'Face Pull'
        ],
        normalizedBounds:
            Rect.fromLTWH(0.11, 0.125, 0.78, 0.065),
        normalizedCenter: Offset(0.50, 0.158),
      ),
      const MuscleGroupProgress(
        id: 'chest',
        name: 'Chest',
        side: MuscleSide.front,
        gainPercent: 0.35,
        status: MuscleStatus.needsWork,
        improvementTip:
            'Add 1–2 incline press sets/week. Prioritize the stretched position for maximum hypertrophy.',
        suggestedExercises: [
          'Bench Press',
          'Incline DB Press',
          'Cable Fly',
          'Dips'
        ],
        normalizedBounds:
            Rect.fromLTWH(0.24, 0.137, 0.52, 0.108),
        normalizedCenter: Offset(0.50, 0.196),
      ),
      const MuscleGroupProgress(
        id: 'biceps',
        name: 'Biceps',
        side: MuscleSide.front,
        gainPercent: 0.35,
        status: MuscleStatus.needsWork,
        improvementTip:
            'Supinated curls with full ROM. Aim for 12–15 working sets/week with progressive overload.',
        suggestedExercises: [
          'Barbell Curl',
          'Hammer Curl',
          'Incline DB Curl',
          'Cable Curl'
        ],
        normalizedBounds:
            Rect.fromLTWH(0.07, 0.196, 0.86, 0.152),
        normalizedCenter: Offset(0.50, 0.270),
      ),
      const MuscleGroupProgress(
        id: 'forearms',
        name: 'Forearms',
        side: MuscleSide.front,
        gainPercent: 0.35,
        status: MuscleStatus.needsWork,
        improvementTip:
            'Wrist curls + farmer carries. Grip training improves all pulling lifts.',
        suggestedExercises: [
          'Wrist Curl',
          'Reverse Curl',
          'Farmer Carry',
          'Dead Hang'
        ],
        normalizedBounds:
            Rect.fromLTWH(0.04, 0.35, 0.92, 0.142),
        normalizedCenter: Offset(0.50, 0.42),
      ),
      const MuscleGroupProgress(
        id: 'abs',
        name: 'Abs',
        side: MuscleSide.front,
        gainPercent: 0.35,
        status: MuscleStatus.needsWork,
        improvementTip:
            'Weighted cable crunches 2×/week. Diet is the primary driver of visible abs.',
        suggestedExercises: [
          'Cable Crunch',
          'Hanging Leg Raise',
          'Plank',
          'Ab Wheel'
        ],
        normalizedBounds:
            Rect.fromLTWH(0.22, 0.246, 0.56, 0.246),
        normalizedCenter: Offset(0.50, 0.370),
      ),
      const MuscleGroupProgress(
        id: 'quads',
        name: 'Quads',
        side: MuscleSide.front,
        gainPercent: 0.35,
        status: MuscleStatus.needsWork,
        improvementTip:
            'Full-depth squats and leg press. Aim for 3–4× per week with progressive overload.',
        suggestedExercises: [
          'Squat',
          'Leg Press',
          'Hack Squat',
          'Leg Extension'
        ],
        normalizedBounds:
            Rect.fromLTWH(0.22, 0.517, 0.56, 0.215),
        normalizedCenter: Offset(0.50, 0.620),
      ),
      const MuscleGroupProgress(
        id: 'calves',
        name: 'Calves',
        side: MuscleSide.front,
        gainPercent: 0.35,
        status: MuscleStatus.needsWork,
        improvementTip:
            'Train both gastrocnemius (straight leg) and soleus (bent leg). 3–4× per week.',
        suggestedExercises: [
          'Standing Calf Raise',
          'Seated Calf Raise',
          'Donkey Calf Raise'
        ],
        normalizedBounds:
            Rect.fromLTWH(0.23, 0.754, 0.54, 0.162),
        normalizedCenter: Offset(0.50, 0.835),
      ),

      // ── BACK ─────────────────────────────────────────────────────────────
      const MuscleGroupProgress(
        id: 'traps',
        name: 'Traps',
        side: MuscleSide.back,
        gainPercent: 0.35,
        status: MuscleStatus.needsWork,
        improvementTip:
            'Mid-trap work via face pulls and Y-raises. Avoid overtraining upper traps with shrugs alone.',
        suggestedExercises: [
          'Barbell Shrug',
          'Face Pull',
          'Y-Raise',
          'Upright Row'
        ],
        normalizedBounds:
            Rect.fromLTWH(0.23, 0.117, 0.54, 0.092),
        normalizedCenter: Offset(0.50, 0.167),
      ),
      const MuscleGroupProgress(
        id: 'lats',
        name: 'Lats',
        side: MuscleSide.back,
        gainPercent: 0.35,
        status: MuscleStatus.needsWork,
        improvementTip:
            'Vertical + horizontal pulls. Aim for 15–20 sets/week of pulling volume.',
        suggestedExercises: [
          'Pull-Up',
          'Lat Pulldown',
          'Barbell Row',
          'Cable Row'
        ],
        normalizedBounds:
            Rect.fromLTWH(0.18, 0.163, 0.64, 0.235),
        normalizedCenter: Offset(0.50, 0.288),
      ),
      const MuscleGroupProgress(
        id: 'triceps',
        name: 'Triceps',
        side: MuscleSide.back,
        gainPercent: 0.35,
        status: MuscleStatus.needsWork,
        improvementTip:
            'Close-grip bench + overhead extension for long-head stretch. 3–4× per week.',
        suggestedExercises: [
          'Tricep Pushdown',
          'Skullcrusher',
          'Overhead Extension',
          'Close-Grip Bench'
        ],
        normalizedBounds:
            Rect.fromLTWH(0.07, 0.192, 0.86, 0.148),
        normalizedCenter: Offset(0.50, 0.267),
      ),
      const MuscleGroupProgress(
        id: 'lower_back',
        name: 'Lower Back',
        side: MuscleSide.back,
        gainPercent: 0.35,
        status: MuscleStatus.needsWork,
        improvementTip:
            'Romanian deadlifts + hyperextensions. Never skip posterior chain on pull day.',
        suggestedExercises: [
          'Deadlift',
          'Romanian DL',
          'Hyperextension',
          'Good Morning'
        ],
        normalizedBounds:
            Rect.fromLTWH(0.33, 0.313, 0.34, 0.188),
        normalizedCenter: Offset(0.50, 0.408),
      ),
      const MuscleGroupProgress(
        id: 'glutes',
        name: 'Glutes',
        side: MuscleSide.back,
        gainPercent: 0.35,
        status: MuscleStatus.needsWork,
        improvementTip:
            'Hip thrusts with full hip extension. Progressive overload every session.',
        suggestedExercises: [
          'Hip Thrust',
          'Glute Bridge',
          'Romanian DL',
          'Bulgarian Split Squat'
        ],
        normalizedBounds:
            Rect.fromLTWH(0.20, 0.450, 0.60, 0.121),
        normalizedCenter: Offset(0.50, 0.510),
      ),
      const MuscleGroupProgress(
        id: 'hamstrings',
        name: 'Hamstrings',
        side: MuscleSide.back,
        gainPercent: 0.35,
        status: MuscleStatus.needsWork,
        improvementTip:
            'Slow eccentric RDLs and Nordic curls. Hamstrings respond best to tempo training.',
        suggestedExercises: [
          'Romanian DL',
          'Leg Curl',
          'Nordic Curl',
          'Sumo Deadlift'
        ],
        normalizedBounds:
            Rect.fromLTWH(0.22, 0.596, 0.56, 0.150),
        normalizedCenter: Offset(0.50, 0.671),
      ),
    ];

// ─── Tips map keyed by muscle id ────────────────────────────────────────────

const kMuscleDescriptions = <String, String>{
  'neck':
      'The neck muscles stabilize the head and contribute to posture. Strengthening them reduces injury risk in contact sports and heavy lifting.',
  'shoulders_front':
      'The deltoids form the rounded contour of the shoulder. Strong anterior and lateral heads are key for pressing movements and aesthetics.',
  'chest':
      'The pectorals power all horizontal pressing movements. Both upper (clavicular) and lower (sternal) heads need dedicated training.',
  'biceps':
      'The biceps brachii peaks with supinated curls and is critical for pulling strength in rows and pull-ups.',
  'forearms':
      'Forearm strength directly impacts grip, which limits performance in deadlifts, rows, and pull-ups before other muscles fatigue.',
  'abs':
      'The rectus abdominis, obliques, and transverse abdominis stabilize the spine during all compound lifts and directly influence aesthetics.',
  'quads':
      'The quadriceps extend the knee and dominate squatting patterns. Balanced quad development also reduces knee injury risk.',
  'calves':
      'The gastrocnemius and soleus are notoriously stubborn. High frequency (3–4×/week) and full range of motion are essential.',
  'traps':
      'The trapezius spans the upper back and neck. The mid-traps are often underdeveloped — Y-raises and face pulls target them directly.',
  'lats':
      'The latissimus dorsi create the V-taper. They respond well to both vertical (pull-ups) and horizontal (rows) pulling patterns.',
  'triceps':
      'The triceps make up ~2/3 of upper arm mass. The long head is best targeted with overhead extensions in a stretched position.',
  'lower_back':
      'The erector spinae and lumbar muscles protect the spine under load. They are the foundation of every compound posterior chain movement.',
  'glutes':
      'The gluteus maximus is the largest muscle in the body and a primary driver of hip extension in squats, deadlifts, and sprints.',
  'hamstrings':
      'The hamstrings flex the knee and extend the hip. They are most susceptible to injury when undertrained — prioritize eccentric loading.',
};
