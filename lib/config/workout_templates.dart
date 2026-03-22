import 'package:flutter/material.dart';

import '../models/workout_plan_model.dart';

// ---------------------------------------------------------------------------
// Athlete type catalogue
// ---------------------------------------------------------------------------

const List<String> kAthleteTypes = [
  'Bodybuilding',
  'Powerlifting',
  'Weightlifting',
  'Arm Wrestling',
  'CrossFit',
  'General',
  'Fat Loss',
];

/// Maps each athlete type to an accent colour used in the UI.
const Map<String, Color> kAthleteTypeColors = {
  'Bodybuilding': Color(0xFF7C3AED),
  'Powerlifting': Color(0xFFDC2626),
  'Weightlifting': Color(0xFF0EA5E9),
  'Arm Wrestling': Color(0xFFD97706),
  'CrossFit': Color(0xFF059669),
  'General': Color(0xFF6B7280),
  'Fat Loss': Color(0xFFF59E0B),
};

// ---------------------------------------------------------------------------
// Shared sentinel date — all templates use this so they sort predictably.
// ---------------------------------------------------------------------------

final _kTemplateDate = DateTime(2024, 1, 1);

// ---------------------------------------------------------------------------
// Helper — builds an Exercise with sensible defaults so call-sites are terse.
// ---------------------------------------------------------------------------

Exercise _ex(
  String name, {
  int sets = 3,
  String reps = '10',
  int rest = 90,
  int? rpe,
  String intensity = 'Medium',
  String? equipment,
  String? cue,
  int order = 0,
}) =>
    Exercise(
      name: name,
      sets: sets,
      reps: reps,
      restSeconds: rest,
      rpe: rpe,
      intensity: intensity,
      equipment: equipment,
      cue: cue,
      orderIndex: order,
    );

// ===========================================================================
// 1 — Bodybuilding PPL (6 days)
// ===========================================================================

final _pplPushA = TrainingDay(
  dayName: 'Day 1 — Push A (Chest / Shoulders / Triceps)',
  muscleGroup: 'chest_shoulders_triceps',
  dayIndex: 0,
  exercises: [
    _ex('Bench Press', sets: 4, reps: '8-12', rest: 90, rpe: 8,
        intensity: 'High', equipment: 'Barbell',
        cue: 'Drive through the chest, not the shoulders', order: 0),
    _ex('Incline DB Press', sets: 3, reps: '10-12', rest: 75, rpe: 7,
        intensity: 'Medium', equipment: 'Dumbbells',
        cue: 'Elbows at 45°, full stretch at bottom', order: 1),
    _ex('Cable Fly', sets: 3, reps: '12-15', rest: 60, rpe: 7,
        intensity: 'Medium', equipment: 'Cable machine',
        cue: 'Slight elbow bend, squeeze at peak contraction', order: 2),
    _ex('Shoulder Press', sets: 4, reps: '8-12', rest: 90, rpe: 8,
        intensity: 'High', equipment: 'Dumbbells',
        cue: 'Neutral spine, press straight overhead', order: 3),
    _ex('Tricep Dips', sets: 3, reps: '10-15', rest: 60, rpe: 7,
        intensity: 'Medium', equipment: 'Parallel bars',
        cue: 'Stay upright for tricep focus', order: 4),
  ],
);

final _pplPullA = TrainingDay(
  dayName: 'Day 2 — Pull A (Back / Biceps)',
  muscleGroup: 'back_biceps',
  dayIndex: 1,
  exercises: [
    _ex('Deadlift', sets: 4, reps: '6-8', rest: 120, rpe: 8,
        intensity: 'High', equipment: 'Barbell',
        cue: 'Bar over mid-foot, neutral spine throughout', order: 0),
    _ex('Barbell Row', sets: 4, reps: '8-10', rest: 90, rpe: 8,
        intensity: 'High', equipment: 'Barbell',
        cue: 'Pull to the lower chest, hinge at hips', order: 1),
    _ex('Pull-ups', sets: 3, reps: '8-12', rest: 75, rpe: 7,
        intensity: 'Medium', equipment: 'Pull-up bar',
        cue: 'Full hang at bottom, chin over bar at top', order: 2),
    _ex('Bicep Curl', sets: 3, reps: '10-12', rest: 60, rpe: 7,
        intensity: 'Medium', equipment: 'Dumbbells',
        cue: 'No swinging — strict supination at top', order: 3),
    _ex('Face Pulls', sets: 3, reps: '15-20', rest: 45, rpe: 6,
        intensity: 'Low', equipment: 'Cable machine',
        cue: 'Pull to forehead, external rotate at peak', order: 4),
  ],
);

final _pplLegsA = TrainingDay(
  dayName: 'Day 3 — Legs A (Quads / Hamstrings / Calves)',
  muscleGroup: 'legs',
  dayIndex: 2,
  exercises: [
    _ex('Squat', sets: 4, reps: '8-12', rest: 120, rpe: 8,
        intensity: 'High', equipment: 'Barbell',
        cue: 'Brace the core, knees track over toes', order: 0),
    _ex('Romanian Deadlift', sets: 3, reps: '10-12', rest: 90, rpe: 7,
        intensity: 'Medium', equipment: 'Barbell',
        cue: 'Push hips back, maintain neutral back', order: 1),
    _ex('Leg Press', sets: 3, reps: '12-15', rest: 75, rpe: 7,
        intensity: 'Medium', equipment: 'Leg press machine',
        cue: 'Feet shoulder-width, do not lock knees at top', order: 2),
    _ex('Calf Raises', sets: 4, reps: '15-20', rest: 45, rpe: 6,
        intensity: 'Medium', equipment: 'Standing calf raise machine',
        cue: 'Full stretch at bottom, pause at top', order: 3),
  ],
);

final _pplPushB = TrainingDay(
  dayName: 'Day 4 — Push B (Chest / Shoulders / Triceps)',
  muscleGroup: 'chest_shoulders_triceps',
  dayIndex: 3,
  exercises: [
    _ex('Incline Barbell Press', sets: 4, reps: '8-10', rest: 90, rpe: 8,
        intensity: 'High', equipment: 'Barbell',
        cue: '30–45° incline, bar to upper chest', order: 0),
    _ex('DB Lateral Raises', sets: 4, reps: '12-15', rest: 60, rpe: 7,
        intensity: 'Medium', equipment: 'Dumbbells',
        cue: 'Slight forward lean, lead with elbows', order: 1),
    _ex('Cable Fly', sets: 3, reps: '12-15', rest: 60, rpe: 7,
        intensity: 'Medium', equipment: 'Cable machine',
        cue: 'Cross hands at peak for full pec contraction', order: 2),
    _ex('Shoulder Press', sets: 3, reps: '10-12', rest: 75, rpe: 7,
        intensity: 'Medium', equipment: 'Barbell',
        cue: 'Wide grip, bar to upper chest', order: 3),
    _ex('Tricep Pushdown', sets: 3, reps: '12-15', rest: 60, rpe: 6,
        intensity: 'Medium', equipment: 'Cable machine',
        cue: 'Keep elbows pinned to sides', order: 4),
  ],
);

final _pplPullB = TrainingDay(
  dayName: 'Day 5 — Pull B (Back / Biceps)',
  muscleGroup: 'back_biceps',
  dayIndex: 4,
  exercises: [
    _ex('Seated Cable Row', sets: 4, reps: '10-12', rest: 75, rpe: 7,
        intensity: 'Medium', equipment: 'Cable machine',
        cue: 'Chest up, drive elbows behind torso', order: 0),
    _ex('Lat Pulldown', sets: 4, reps: '10-12', rest: 75, rpe: 7,
        intensity: 'Medium', equipment: 'Cable machine',
        cue: 'Lean back slightly, pull bar to upper chest', order: 1),
    _ex('DB Row', sets: 3, reps: '10-12', rest: 60, rpe: 7,
        intensity: 'Medium', equipment: 'Dumbbells',
        cue: 'Full stretch, elbow past torso', order: 2),
    _ex('Hammer Curl', sets: 3, reps: '10-12', rest: 60, rpe: 6,
        intensity: 'Medium', equipment: 'Dumbbells',
        cue: 'Neutral grip, controlled negative', order: 3),
    _ex('Face Pulls', sets: 3, reps: '15-20', rest: 45, rpe: 6,
        intensity: 'Low', equipment: 'Cable machine',
        cue: 'High anchor, pull to ears', order: 4),
  ],
);

final _pplLegsB = TrainingDay(
  dayName: 'Day 6 — Legs B (Hamstrings / Glutes / Calves)',
  muscleGroup: 'legs',
  dayIndex: 5,
  exercises: [
    _ex('Romanian Deadlift', sets: 4, reps: '8-10', rest: 120, rpe: 8,
        intensity: 'High', equipment: 'Barbell',
        cue: 'Feel the hamstrings load — do not round lower back', order: 0),
    _ex('Leg Curl', sets: 3, reps: '12-15', rest: 60, rpe: 7,
        intensity: 'Medium', equipment: 'Leg curl machine',
        cue: 'Slow eccentric, squeeze at peak', order: 1),
    _ex('Squat', sets: 3, reps: '10-12', rest: 90, rpe: 7,
        intensity: 'Medium', equipment: 'Barbell',
        cue: 'Slightly wider stance for glute emphasis', order: 2),
    _ex('Leg Press', sets: 3, reps: '15-20', rest: 60, rpe: 6,
        intensity: 'Low', equipment: 'Leg press machine',
        cue: 'High foot placement for hamstrings', order: 3),
    _ex('Calf Raises', sets: 4, reps: '15-20', rest: 45, rpe: 6,
        intensity: 'Low', equipment: 'Seated calf raise machine',
        cue: 'Pause for 1 s at stretched position', order: 4),
  ],
);

// ===========================================================================
// 2 — Bro Split Bodybuilding (5 days)
// ===========================================================================

final _broChest = TrainingDay(
  dayName: 'Day 1 — Chest & Triceps',
  muscleGroup: 'chest_triceps',
  dayIndex: 0,
  exercises: [
    _ex('Bench Press', sets: 4, reps: '8-10', rest: 90, rpe: 8,
        intensity: 'High', equipment: 'Barbell',
        cue: 'Retract scapulae before unracking', order: 0),
    _ex('Incline DB Press', sets: 3, reps: '10-12', rest: 75, rpe: 7,
        intensity: 'Medium', equipment: 'Dumbbells',
        cue: '30° incline hits upper pec', order: 1),
    _ex('Pec Deck Fly', sets: 3, reps: '12-15', rest: 60, rpe: 7,
        intensity: 'Medium', equipment: 'Pec deck machine',
        cue: 'Avoid locking elbows — soft bend throughout', order: 2),
    _ex('Tricep Pushdown', sets: 3, reps: '12-15', rest: 60, rpe: 7,
        intensity: 'Medium', equipment: 'Cable machine',
        cue: 'Full extension at bottom', order: 3),
    _ex('Skull Crushers', sets: 3, reps: '10-12', rest: 60, rpe: 7,
        intensity: 'Medium', equipment: 'EZ bar',
        cue: 'Lower to forehead, keep elbows vertical', order: 4),
  ],
);

final _broBack = TrainingDay(
  dayName: 'Day 2 — Back & Biceps',
  muscleGroup: 'back_biceps',
  dayIndex: 1,
  exercises: [
    _ex('Pull-ups', sets: 4, reps: '8-12', rest: 90, rpe: 8,
        intensity: 'High', equipment: 'Pull-up bar',
        cue: 'Dead hang start, full ROM', order: 0),
    _ex('Barbell Row', sets: 4, reps: '8-10', rest: 90, rpe: 8,
        intensity: 'High', equipment: 'Barbell',
        cue: 'Bar path to belly button', order: 1),
    _ex('Lat Pulldown', sets: 3, reps: '10-12', rest: 75, rpe: 7,
        intensity: 'Medium', equipment: 'Cable machine',
        cue: 'Pull elbows to ribs', order: 2),
    _ex('Bicep Curl', sets: 3, reps: '10-12', rest: 60, rpe: 7,
        intensity: 'Medium', equipment: 'EZ bar',
        cue: 'No momentum — strict curl', order: 3),
    _ex('Incline DB Curl', sets: 3, reps: '10-12', rest: 60, rpe: 6,
        intensity: 'Medium', equipment: 'Dumbbells',
        cue: 'Full stretch at bottom for long head peak', order: 4),
  ],
);

final _broShoulders = TrainingDay(
  dayName: 'Day 3 — Shoulders',
  muscleGroup: 'shoulders',
  dayIndex: 2,
  exercises: [
    _ex('Barbell OHP', sets: 4, reps: '8-10', rest: 90, rpe: 8,
        intensity: 'High', equipment: 'Barbell',
        cue: 'Bar path straight up — avoid forward lean', order: 0),
    _ex('DB Lateral Raises', sets: 4, reps: '12-15', rest: 60, rpe: 7,
        intensity: 'Medium', equipment: 'Dumbbells',
        cue: 'Pinky slightly higher than thumb at top', order: 1),
    _ex('Rear Delt Fly', sets: 3, reps: '15-20', rest: 45, rpe: 6,
        intensity: 'Low', equipment: 'Cable machine',
        cue: 'Horizontal pull, feel rear delt contract', order: 2),
    _ex('Front Raises', sets: 3, reps: '12-15', rest: 60, rpe: 6,
        intensity: 'Medium', equipment: 'Plates',
        cue: 'Raise to shoulder height only', order: 3),
    _ex('Shrugs', sets: 3, reps: '15-20', rest: 60, rpe: 6,
        intensity: 'Medium', equipment: 'Barbell',
        cue: 'Pause and hold at top for 1 s', order: 4),
  ],
);

final _broLegs = TrainingDay(
  dayName: 'Day 4 — Legs',
  muscleGroup: 'legs',
  dayIndex: 3,
  exercises: [
    _ex('Squat', sets: 4, reps: '8-10', rest: 120, rpe: 8,
        intensity: 'High', equipment: 'Barbell',
        cue: 'Depth below parallel, brace hard', order: 0),
    _ex('Leg Press', sets: 4, reps: '12-15', rest: 75, rpe: 7,
        intensity: 'Medium', equipment: 'Leg press machine',
        cue: 'Full ROM, do not hyperextend', order: 1),
    _ex('Romanian Deadlift', sets: 3, reps: '10-12', rest: 90, rpe: 7,
        intensity: 'Medium', equipment: 'Barbell',
        cue: 'Hip hinge — feel the stretch', order: 2),
    _ex('Leg Curl', sets: 3, reps: '12-15', rest: 60, rpe: 7,
        intensity: 'Medium', equipment: 'Leg curl machine', order: 3),
    _ex('Calf Raises', sets: 4, reps: '20-25', rest: 45, rpe: 6,
        intensity: 'Low', equipment: 'Standing calf raise machine',
        cue: 'Slow eccentric — 3 s down', order: 4),
  ],
);

final _broArms = TrainingDay(
  dayName: 'Day 5 — Arms (Biceps & Triceps)',
  muscleGroup: 'biceps_triceps',
  dayIndex: 4,
  exercises: [
    _ex('Barbell Curl', sets: 4, reps: '8-10', rest: 75, rpe: 8,
        intensity: 'High', equipment: 'Barbell',
        cue: 'Wrists neutral, elbows fixed', order: 0),
    _ex('Hammer Curl', sets: 3, reps: '10-12', rest: 60, rpe: 7,
        intensity: 'Medium', equipment: 'Dumbbells', order: 1),
    _ex('Skull Crushers', sets: 4, reps: '10-12', rest: 75, rpe: 8,
        intensity: 'High', equipment: 'EZ bar',
        cue: 'Lower slowly — control the weight', order: 2),
    _ex('Tricep Pushdown', sets: 3, reps: '12-15', rest: 60, rpe: 7,
        intensity: 'Medium', equipment: 'Cable machine', order: 3),
    _ex('Concentration Curl', sets: 3, reps: '12-15', rest: 45, rpe: 6,
        intensity: 'Low', equipment: 'Dumbbell',
        cue: 'Full supination at top for bicep peak', order: 4),
  ],
);

// ===========================================================================
// 3 — 5/3/1 Powerlifting (4 days)
// ===========================================================================

final _pl531Squat = TrainingDay(
  dayName: 'Day 1 — Squat',
  muscleGroup: 'legs',
  dayIndex: 0,
  notes: 'Main lift follows 5/3/1 wave. Work sets: 65%, 75%, 85% of TM.',
  exercises: [
    _ex('Squat', sets: 3, reps: '3-5', rest: 180, rpe: 9,
        intensity: 'High', equipment: 'Barbell',
        cue: 'Create maximum tension before descent', order: 0),
    _ex('Romanian Deadlift', sets: 5, reps: '10', rest: 90, rpe: 7,
        intensity: 'Medium', equipment: 'Barbell',
        cue: 'Assistance work — stay controlled', order: 1),
    _ex('Leg Press', sets: 5, reps: '10', rest: 75, rpe: 7,
        intensity: 'Medium', equipment: 'Leg press machine', order: 2),
    _ex('Hanging Leg Raise', sets: 5, reps: '10-15', rest: 60, rpe: 6,
        intensity: 'Low', equipment: 'Pull-up bar', order: 3),
  ],
);

final _pl531Bench = TrainingDay(
  dayName: 'Day 2 — Bench Press',
  muscleGroup: 'chest_triceps',
  dayIndex: 1,
  notes: 'Main lift follows 5/3/1 wave.',
  exercises: [
    _ex('Bench Press', sets: 3, reps: '3-5', rest: 180, rpe: 9,
        intensity: 'High', equipment: 'Barbell',
        cue: 'Arch set before unrack, leg drive', order: 0),
    _ex('DB Row', sets: 5, reps: '10', rest: 75, rpe: 7,
        intensity: 'Medium', equipment: 'Dumbbells',
        cue: 'Balance push with pull', order: 1),
    _ex('Tricep Pushdown', sets: 5, reps: '10', rest: 60, rpe: 7,
        intensity: 'Medium', equipment: 'Cable machine', order: 2),
    _ex('DB Curl', sets: 5, reps: '10', rest: 60, rpe: 6,
        intensity: 'Low', equipment: 'Dumbbells', order: 3),
  ],
);

final _pl531Deadlift = TrainingDay(
  dayName: 'Day 3 — Deadlift',
  muscleGroup: 'posterior_chain',
  dayIndex: 2,
  notes: 'Main lift follows 5/3/1 wave.',
  exercises: [
    _ex('Deadlift', sets: 3, reps: '3-5', rest: 240, rpe: 9,
        intensity: 'High', equipment: 'Barbell',
        cue: 'Push the floor away, bar stays against shins', order: 0),
    _ex('Good Morning', sets: 5, reps: '10', rest: 90, rpe: 7,
        intensity: 'Medium', equipment: 'Barbell',
        cue: 'Hip hinge — lower back locked in', order: 1),
    _ex('Leg Curl', sets: 5, reps: '10', rest: 60, rpe: 7,
        intensity: 'Medium', equipment: 'Leg curl machine', order: 2),
    _ex('Ab Wheel Rollout', sets: 5, reps: '10', rest: 60, rpe: 7,
        intensity: 'Medium', equipment: 'Ab wheel', order: 3),
  ],
);

final _pl531OHP = TrainingDay(
  dayName: 'Day 4 — Overhead Press',
  muscleGroup: 'shoulders',
  dayIndex: 3,
  notes: 'Main lift follows 5/3/1 wave.',
  exercises: [
    _ex('Overhead Press', sets: 3, reps: '3-5', rest: 180, rpe: 9,
        intensity: 'High', equipment: 'Barbell',
        cue: 'Glutes and abs braced, push through the ceiling', order: 0),
    _ex('Chin-ups', sets: 5, reps: '10', rest: 75, rpe: 7,
        intensity: 'Medium', equipment: 'Pull-up bar', order: 1),
    _ex('DB Lateral Raises', sets: 5, reps: '15', rest: 45, rpe: 6,
        intensity: 'Low', equipment: 'Dumbbells', order: 2),
    _ex('Tricep Dips', sets: 5, reps: '10', rest: 60, rpe: 7,
        intensity: 'Medium', equipment: 'Parallel bars', order: 3),
  ],
);

// ===========================================================================
// 4 — Olympic Weightlifting (4 days)
// ===========================================================================

final _wlSnatch = TrainingDay(
  dayName: 'Day 1 — Snatch Technique',
  muscleGroup: 'full_body',
  dayIndex: 0,
  notes: 'Technique focus. Keep loads at 70-80% of max snatch.',
  exercises: [
    _ex('Power Snatch', sets: 5, reps: '3', rest: 180, rpe: 8,
        intensity: 'High', equipment: 'Barbell',
        cue: 'Bar close to body, violent hip extension', order: 0),
    _ex('Hang Snatch', sets: 4, reps: '3', rest: 150, rpe: 7,
        intensity: 'High', equipment: 'Barbell',
        cue: 'Start at mid-thigh, feel the pull position', order: 1),
    _ex('Snatch Pull', sets: 4, reps: '4', rest: 120, rpe: 7,
        intensity: 'Medium', equipment: 'Barbell',
        cue: 'Full extension — rise onto toes', order: 2),
    _ex('Overhead Squat', sets: 4, reps: '4', rest: 120, rpe: 7,
        intensity: 'Medium', equipment: 'Barbell',
        cue: 'Wide grip, keep bar over heels', order: 3),
  ],
);

final _wlCleanJerk = TrainingDay(
  dayName: 'Day 2 — Clean & Jerk',
  muscleGroup: 'full_body',
  dayIndex: 1,
  notes: 'Build to 85% C&J. Prioritise rack position quality.',
  exercises: [
    _ex('Clean and Jerk', sets: 5, reps: '2', rest: 240, rpe: 8,
        intensity: 'High', equipment: 'Barbell',
        cue: 'High elbow in rack, aggressive dip-drive for jerk', order: 0),
    _ex('Power Clean', sets: 4, reps: '3', rest: 180, rpe: 7,
        intensity: 'High', equipment: 'Barbell',
        cue: 'Triple extension — hips, knees, ankles', order: 1),
    _ex('Push Jerk', sets: 4, reps: '3', rest: 120, rpe: 7,
        intensity: 'Medium', equipment: 'Barbell',
        cue: 'Dip straight down, drive the bar up and under', order: 2),
    _ex('Front Squat', sets: 4, reps: '4', rest: 120, rpe: 7,
        intensity: 'Medium', equipment: 'Barbell',
        cue: 'High elbows, upright torso throughout', order: 3),
  ],
);

final _wlFrontSquat = TrainingDay(
  dayName: 'Day 3 — Front Squat & Pulls',
  muscleGroup: 'legs',
  dayIndex: 2,
  exercises: [
    _ex('Front Squat', sets: 5, reps: '3-5', rest: 180, rpe: 8,
        intensity: 'High', equipment: 'Barbell',
        cue: 'Elbows up — wrists relaxed in rack', order: 0),
    _ex('Clean Pull', sets: 5, reps: '3', rest: 120, rpe: 7,
        intensity: 'High', equipment: 'Barbell',
        cue: 'Maximal acceleration through the second pull', order: 1),
    _ex('Snatch Deadlift', sets: 4, reps: '4', rest: 120, rpe: 7,
        intensity: 'Medium', equipment: 'Barbell',
        cue: 'Wide grip, slow and controlled', order: 2),
    _ex('Back Extension', sets: 3, reps: '10', rest: 90, rpe: 6,
        intensity: 'Medium', equipment: 'GHD machine', order: 3),
  ],
);

final _wlAccessory = TrainingDay(
  dayName: 'Day 4 — Accessory',
  muscleGroup: 'full_body',
  dayIndex: 3,
  notes: 'Lighter day. Mobility, stability, and weak-point work.',
  exercises: [
    _ex('Romanian Deadlift', sets: 4, reps: '8', rest: 90, rpe: 6,
        intensity: 'Medium', equipment: 'Barbell', order: 0),
    _ex('Pull-ups', sets: 4, reps: '8-10', rest: 75, rpe: 7,
        intensity: 'Medium', equipment: 'Pull-up bar', order: 1),
    _ex('DB Lateral Raises', sets: 3, reps: '15', rest: 45, rpe: 6,
        intensity: 'Low', equipment: 'Dumbbells', order: 2),
    _ex('Barbell Hip Thrust', sets: 4, reps: '10', rest: 90, rpe: 6,
        intensity: 'Medium', equipment: 'Barbell',
        cue: 'Posteriorly tilt pelvis at top', order: 3),
    _ex('Wrist Roller', sets: 3, reps: '3 rolls', rest: 60, rpe: 5,
        intensity: 'Low', equipment: 'Wrist roller', order: 4),
  ],
);

// ===========================================================================
// 5 — Arm Wrestling Prep (3 days)
// ===========================================================================

final _awPulling = TrainingDay(
  dayName: 'Day 1 — Pulling Power',
  muscleGroup: 'back_arms',
  dayIndex: 0,
  notes: 'Develop pronation strength and elbow curl power.',
  exercises: [
    _ex('Cable Row', sets: 4, reps: '8-10', rest: 90, rpe: 8,
        intensity: 'High', equipment: 'Cable machine',
        cue: 'Drive elbow behind torso — supinate wrist at peak', order: 0),
    _ex('Hammer Curl', sets: 4, reps: '8-10', rest: 75, rpe: 8,
        intensity: 'High', equipment: 'Dumbbells',
        cue: 'Neutral grip, slow eccentric', order: 1),
    _ex('Supination Curl', sets: 4, reps: '10-12', rest: 75, rpe: 7,
        intensity: 'Medium', equipment: 'Dumbbells',
        cue: 'Pronate down, supinate up — full ROM', order: 2),
    _ex('Reverse Curl', sets: 3, reps: '12-15', rest: 60, rpe: 7,
        intensity: 'Medium', equipment: 'Barbell',
        cue: 'Overhand grip — trains brachialis and pronators', order: 3),
    _ex('Lat Pulldown', sets: 3, reps: '10-12', rest: 75, rpe: 7,
        intensity: 'Medium', equipment: 'Cable machine',
        cue: 'Full lat engagement for table pull', order: 4),
  ],
);

final _awGrip = TrainingDay(
  dayName: 'Day 2 — Wrist & Grip',
  muscleGroup: 'forearms_grip',
  dayIndex: 1,
  notes: 'High rep grip and wrist work. Avoid going to failure on isolation.',
  exercises: [
    _ex('Wrist Curls', sets: 4, reps: '15-20', rest: 45, rpe: 7,
        intensity: 'Medium', equipment: 'Barbell',
        cue: 'Full extension at bottom — squeeze at top', order: 0),
    _ex('Reverse Wrist Curls', sets: 4, reps: '15-20', rest: 45, rpe: 6,
        intensity: 'Medium', equipment: 'Barbell', order: 1),
    _ex('Pronation Work', sets: 4, reps: '15', rest: 45, rpe: 7,
        intensity: 'Medium', equipment: 'Hammer or cable',
        cue: 'Rotate palm down against resistance', order: 2),
    _ex('Plate Pinch', sets: 3, reps: '30s hold', rest: 60, rpe: 7,
        intensity: 'Medium', equipment: 'Weight plates',
        cue: 'Thumb and four fingers — squeeze entire hand', order: 3),
    _ex('Towel Pull-ups', sets: 3, reps: '5-8', rest: 90, rpe: 8,
        intensity: 'High', equipment: 'Pull-up bar + towel',
        cue: 'Builds crushing grip and pulling synergy', order: 4),
  ],
);

final _awTechnique = TrainingDay(
  dayName: 'Day 3 — Hook & Top Roll Technique',
  muscleGroup: 'forearms_back_arms',
  dayIndex: 2,
  notes: 'Simulate arm wrestling positions. Use a table or peg board.',
  exercises: [
    _ex('Table Practice', sets: 5, reps: '5 attempts', rest: 120, rpe: 8,
        intensity: 'High', equipment: 'Arm wrestling table',
        cue: 'Practice the hook — keep wrist cupped and elbow in', order: 0),
    _ex('Reverse Curl', sets: 4, reps: '10-12', rest: 60, rpe: 7,
        intensity: 'Medium', equipment: 'EZ bar', order: 1),
    _ex('Wrist Curls', sets: 3, reps: '20', rest: 45, rpe: 6,
        intensity: 'Low', equipment: 'Dumbbell', order: 2),
    _ex('Hammer Curls', sets: 4, reps: '10', rest: 60, rpe: 7,
        intensity: 'Medium', equipment: 'Dumbbells', order: 3),
    _ex('Supination Curl', sets: 3, reps: '12', rest: 60, rpe: 7,
        intensity: 'Medium', equipment: 'Dumbbells',
        cue: 'End-range supination against the pin', order: 4),
  ],
);

// ===========================================================================
// 6 — CrossFit WOD (5 days)
// ===========================================================================

final _cfStrength = TrainingDay(
  dayName: 'Day 1 — Strength Focus',
  muscleGroup: 'full_body',
  dayIndex: 0,
  notes: 'Strength + metcon. Thrusters are the primary movement.',
  exercises: [
    _ex('Thrusters', sets: 5, reps: '5', rest: 120, rpe: 8,
        intensity: 'High', equipment: 'Barbell',
        cue: 'Front squat into push press — one fluid movement', order: 0),
    _ex('Pull-ups', sets: 5, reps: '10', rest: 60, rpe: 7,
        intensity: 'High', equipment: 'Pull-up bar',
        cue: 'Kip when metabolic demand is high', order: 1),
    _ex('Box Jumps', sets: 4, reps: '10', rest: 60, rpe: 7,
        intensity: 'High', equipment: '24" box',
        cue: 'Soft landing — step down to save knees', order: 2),
    _ex('Burpees', sets: 3, reps: '15', rest: 60, rpe: 8,
        intensity: 'High', equipment: 'None',
        cue: 'Consistent pace — do not sprint then die', order: 3),
  ],
);

final _cfMetcon = TrainingDay(
  dayName: 'Day 2 — Metcon',
  muscleGroup: 'full_body',
  dayIndex: 1,
  notes: 'AMRAP or For Time format. Scale weight as needed.',
  exercises: [
    _ex('KB Swings', sets: 5, reps: '20', rest: 60, rpe: 8,
        intensity: 'High', equipment: 'Kettlebell',
        cue: 'Hip hinge, not a squat — power from glutes', order: 0),
    _ex('Double Unders', sets: 5, reps: '50', rest: 60, rpe: 7,
        intensity: 'High', equipment: 'Jump rope',
        cue: 'Relaxed wrists, tight core', order: 1),
    _ex('Wall Balls', sets: 5, reps: '20', rest: 60, rpe: 8,
        intensity: 'High', equipment: '20lb ball',
        cue: 'Full squat, catch at chest height', order: 2),
    _ex('Burpees', sets: 4, reps: '10', rest: 45, rpe: 8,
        intensity: 'High', equipment: 'None', order: 3),
  ],
);

final _cfSkills = TrainingDay(
  dayName: 'Day 3 — Gymnastics / Skills',
  muscleGroup: 'upper_body',
  dayIndex: 2,
  exercises: [
    _ex('Handstand Push-ups', sets: 4, reps: '8-10', rest: 90, rpe: 8,
        intensity: 'High', equipment: 'Wall',
        cue: 'Head to an AbMat — lock out fully at top', order: 0),
    _ex('Muscle-ups', sets: 4, reps: '3-5', rest: 120, rpe: 8,
        intensity: 'High', equipment: 'Rings or bar',
        cue: 'Late pull-through — transition fast', order: 1),
    _ex('Toes-to-Bar', sets: 4, reps: '10-15', rest: 60, rpe: 7,
        intensity: 'Medium', equipment: 'Pull-up bar', order: 2),
    _ex('KB Swings', sets: 3, reps: '20', rest: 60, rpe: 7,
        intensity: 'Medium', equipment: 'Kettlebell', order: 3),
  ],
);

final _cfEndurance = TrainingDay(
  dayName: 'Day 4 — Endurance / Rowing',
  muscleGroup: 'full_body',
  dayIndex: 3,
  exercises: [
    _ex('Row Machine', sets: 5, reps: '500m', rest: 60, rpe: 7,
        intensity: 'Medium', equipment: 'Rowing machine',
        cue: 'Drive legs first, lean back, then pull arms', order: 0),
    _ex('Double Unders', sets: 4, reps: '60', rest: 45, rpe: 7,
        intensity: 'Medium', equipment: 'Jump rope', order: 1),
    _ex('Burpees', sets: 3, reps: '20', rest: 60, rpe: 7,
        intensity: 'Medium', equipment: 'None', order: 2),
    _ex('Box Jumps', sets: 3, reps: '15', rest: 60, rpe: 7,
        intensity: 'Medium', equipment: '20" box', order: 3),
  ],
);

final _cfMaxOut = TrainingDay(
  dayName: 'Day 5 — Benchmark WOD',
  muscleGroup: 'full_body',
  dayIndex: 4,
  notes: 'Benchmark session — aim for max effort and track score.',
  exercises: [
    _ex('Thrusters', sets: 3, reps: '21-15-9', rest: 90, rpe: 9,
        intensity: 'High', equipment: 'Barbell',
        cue: 'Fran pace — sub 10 min target', order: 0),
    _ex('Pull-ups', sets: 3, reps: '21-15-9', rest: 90, rpe: 9,
        intensity: 'High', equipment: 'Pull-up bar',
        cue: 'Kipping allowed — keep moving', order: 1),
    _ex('Wall Balls', sets: 3, reps: '15', rest: 60, rpe: 8,
        intensity: 'High', equipment: '20lb ball', order: 2),
    _ex('KB Swings', sets: 3, reps: '15', rest: 60, rpe: 8,
        intensity: 'High', equipment: 'Kettlebell', order: 3),
  ],
);

// ===========================================================================
// 7 — Full Body Beginner (3 days)
// ===========================================================================

final _fbDay1 = TrainingDay(
  dayName: 'Day 1 — Full Body A',
  muscleGroup: 'full_body',
  dayIndex: 0,
  exercises: [
    _ex('Goblet Squat', sets: 3, reps: '10-12', rest: 75, rpe: 6,
        intensity: 'Low', equipment: 'Dumbbell or kettlebell',
        cue: 'Chest up, knees track toes', order: 0),
    _ex('DB Bench Press', sets: 3, reps: '10-12', rest: 75, rpe: 6,
        intensity: 'Low', equipment: 'Dumbbells',
        cue: 'Control the descent — 2 s down', order: 1),
    _ex('Seated Cable Row', sets: 3, reps: '10-12', rest: 75, rpe: 6,
        intensity: 'Low', equipment: 'Cable machine',
        cue: 'Upright torso, pull elbows past torso', order: 2),
    _ex('Romanian Deadlift', sets: 3, reps: '10-12', rest: 75, rpe: 6,
        intensity: 'Low', equipment: 'Dumbbells',
        cue: 'Slight knee bend, hip hinge until stretch', order: 3),
    _ex('Lat Pulldown', sets: 3, reps: '10-12', rest: 75, rpe: 6,
        intensity: 'Low', equipment: 'Cable machine',
        cue: 'Lean back 10°, drive elbows to ribs', order: 4),
  ],
);

final _fbDay2 = TrainingDay(
  dayName: 'Day 2 — Full Body B',
  muscleGroup: 'full_body',
  dayIndex: 1,
  exercises: [
    _ex('Goblet Squat', sets: 3, reps: '12-15', rest: 75, rpe: 6,
        intensity: 'Low', equipment: 'Kettlebell', order: 0),
    _ex('DB Shoulder Press', sets: 3, reps: '10-12', rest: 75, rpe: 6,
        intensity: 'Low', equipment: 'Dumbbells',
        cue: 'Neutral spine, do not flare ribs', order: 1),
    _ex('Lat Pulldown', sets: 3, reps: '12-15', rest: 75, rpe: 6,
        intensity: 'Low', equipment: 'Cable machine', order: 2),
    _ex('Romanian Deadlift', sets: 3, reps: '12', rest: 90, rpe: 6,
        intensity: 'Low', equipment: 'Barbell',
        cue: 'Bar stays close to the body throughout', order: 3),
    _ex('Plank', sets: 3, reps: '30-45s', rest: 45, rpe: 5,
        intensity: 'Low', equipment: 'None',
        cue: 'Neutral spine, do not let hips sag', order: 4),
  ],
);

final _fbDay3 = TrainingDay(
  dayName: 'Day 3 — Full Body C',
  muscleGroup: 'full_body',
  dayIndex: 2,
  exercises: [
    _ex('Goblet Squat', sets: 3, reps: '12', rest: 75, rpe: 6,
        intensity: 'Low', equipment: 'Dumbbell', order: 0),
    _ex('DB Bench Press', sets: 3, reps: '12', rest: 75, rpe: 6,
        intensity: 'Low', equipment: 'Dumbbells', order: 1),
    _ex('Seated Cable Row', sets: 3, reps: '12', rest: 75, rpe: 6,
        intensity: 'Low', equipment: 'Cable machine', order: 2),
    _ex('Romanian Deadlift', sets: 3, reps: '12', rest: 90, rpe: 6,
        intensity: 'Low', equipment: 'Barbell', order: 3),
    _ex('Lat Pulldown', sets: 3, reps: '12', rest: 75, rpe: 6,
        intensity: 'Low', equipment: 'Cable machine', order: 4),
  ],
);

// ===========================================================================
// 8 — Fat Loss HIIT (4 days)
// ===========================================================================

final _hiit1 = TrainingDay(
  dayName: 'Day 1 — Lower Body HIIT',
  muscleGroup: 'legs',
  dayIndex: 0,
  notes: 'Circuit: 40 s on / 20 s off per exercise. Repeat 4 rounds.',
  exercises: [
    _ex('Jump Squats', sets: 4, reps: '40s', rest: 20, rpe: 8,
        intensity: 'High', equipment: 'None',
        cue: 'Land softly — absorb through hips and knees', order: 0),
    _ex('Kettlebell Swings', sets: 4, reps: '40s', rest: 20, rpe: 8,
        intensity: 'High', equipment: 'Kettlebell',
        cue: 'Explosive hip snap every rep', order: 1),
    _ex('Mountain Climbers', sets: 4, reps: '40s', rest: 20, rpe: 8,
        intensity: 'High', equipment: 'None',
        cue: 'Drive knees to chest — keep hips level', order: 2),
    _ex('Burpees', sets: 4, reps: '40s', rest: 20, rpe: 9,
        intensity: 'High', equipment: 'None',
        cue: 'Full extension at top, chest to floor at bottom', order: 3),
  ],
);

final _hiit2 = TrainingDay(
  dayName: 'Day 2 — Upper Body HIIT',
  muscleGroup: 'upper_body',
  dayIndex: 1,
  notes: 'Circuit: 40 s on / 20 s off per exercise. Repeat 4 rounds.',
  exercises: [
    _ex('Battle Ropes', sets: 4, reps: '40s', rest: 20, rpe: 8,
        intensity: 'High', equipment: 'Battle ropes',
        cue: 'Alternating waves — anchor from the core', order: 0),
    _ex('Push-ups', sets: 4, reps: '40s', rest: 20, rpe: 7,
        intensity: 'Medium', equipment: 'None',
        cue: 'Keep body rigid — no hip sag', order: 1),
    _ex('Mountain Climbers', sets: 4, reps: '40s', rest: 20, rpe: 8,
        intensity: 'High', equipment: 'None', order: 2),
    _ex('Burpees', sets: 4, reps: '40s', rest: 20, rpe: 9,
        intensity: 'High', equipment: 'None', order: 3),
  ],
);

final _hiit3 = TrainingDay(
  dayName: 'Day 3 — Full Body Cardio',
  muscleGroup: 'full_body',
  dayIndex: 2,
  notes: 'Tabata format: 20 s on / 10 s off, 8 rounds per exercise.',
  exercises: [
    _ex('Jump Squats', sets: 8, reps: '20s', rest: 10, rpe: 8,
        intensity: 'High', equipment: 'None', order: 0),
    _ex('Burpees', sets: 8, reps: '20s', rest: 10, rpe: 9,
        intensity: 'High', equipment: 'None', order: 1),
    _ex('Kettlebell Swings', sets: 8, reps: '20s', rest: 10, rpe: 8,
        intensity: 'High', equipment: 'Kettlebell', order: 2),
    _ex('Mountain Climbers', sets: 8, reps: '20s', rest: 10, rpe: 8,
        intensity: 'High', equipment: 'None', order: 3),
  ],
);

final _hiit4 = TrainingDay(
  dayName: 'Day 4 — Metabolic Finisher',
  muscleGroup: 'full_body',
  dayIndex: 3,
  notes: 'EMOM 20 min: alternate between two movements every minute.',
  exercises: [
    _ex('Battle Ropes', sets: 10, reps: '30s', rest: 30, rpe: 8,
        intensity: 'High', equipment: 'Battle ropes',
        cue: 'Max effort each interval', order: 0),
    _ex('Jump Squats', sets: 10, reps: '10', rest: 30, rpe: 8,
        intensity: 'High', equipment: 'None', order: 1),
    _ex('Burpees', sets: 5, reps: '8', rest: 60, rpe: 9,
        intensity: 'High', equipment: 'None', order: 2),
    _ex('Kettlebell Swings', sets: 5, reps: '15', rest: 60, rpe: 8,
        intensity: 'High', equipment: 'Kettlebell', order: 3),
  ],
);

// ===========================================================================
// Master list — exported for use throughout the app
// ===========================================================================

final List<WorkoutPlan> kWorkoutTemplates = [
  // 1 — Bodybuilding PPL
  WorkoutPlan(
    id: 'template_bbs_ppl',
    gymId: 'template',
    name: 'Bodybuilding PPL',
    description:
        'Classic 6-day Push / Pull / Legs split repeated twice per week. '
        'Optimised for hypertrophy with 8-12 rep ranges and moderate RPE.',
    goal: 'muscle_gain',
    durationWeeks: 12,
    phase: 'Hypertrophy',
    athleteType: 'Bodybuilding',
    isTemplate: true,
    status: PlanStatus.active,
    days: [_pplPushA, _pplPullA, _pplLegsA, _pplPushB, _pplPullB, _pplLegsB],
    createdAt: _kTemplateDate,
    updatedAt: _kTemplateDate,
  ),

  // 2 — Bro Split
  WorkoutPlan(
    id: 'template_bbs_bro',
    gymId: 'template',
    name: 'Bro Split Bodybuilding',
    description:
        '5-day split dedicating each session to one or two muscle groups. '
        'High volume isolation work for maximum pump and mind-muscle connection.',
    goal: 'muscle_gain',
    durationWeeks: 12,
    phase: 'Volume',
    athleteType: 'Bodybuilding',
    isTemplate: true,
    status: PlanStatus.active,
    days: [_broChest, _broBack, _broShoulders, _broLegs, _broArms],
    createdAt: _kTemplateDate,
    updatedAt: _kTemplateDate,
  ),

  // 3 — 5/3/1 Powerlifting
  WorkoutPlan(
    id: 'template_pl_531',
    gymId: 'template',
    name: '5/3/1 Powerlifting',
    description:
        'Jim Wendler\'s proven four-day programme. '
        'Submaximal training on the big four lifts with progressive wave loading.',
    goal: 'strength',
    durationWeeks: 16,
    phase: 'Strength',
    athleteType: 'Powerlifting',
    isTemplate: true,
    status: PlanStatus.active,
    days: [_pl531Squat, _pl531Bench, _pl531Deadlift, _pl531OHP],
    createdAt: _kTemplateDate,
    updatedAt: _kTemplateDate,
  ),

  // 4 — Olympic Weightlifting
  WorkoutPlan(
    id: 'template_wl_olympic',
    gymId: 'template',
    name: 'Olympic Weightlifting',
    description:
        'Four-day programme centred on the snatch and clean & jerk. '
        'Emphasis on technique, bar path, and positional strength.',
    goal: 'strength',
    durationWeeks: 12,
    phase: 'Technical Development',
    athleteType: 'Weightlifting',
    isTemplate: true,
    status: PlanStatus.active,
    days: [_wlSnatch, _wlCleanJerk, _wlFrontSquat, _wlAccessory],
    createdAt: _kTemplateDate,
    updatedAt: _kTemplateDate,
  ),

  // 5 — Arm Wrestling Prep
  WorkoutPlan(
    id: 'template_aw_prep',
    gymId: 'template',
    name: 'Arm Wrestling Prep',
    description:
        'Three-day specialisation programme for competitive arm wrestlers. '
        'Develops pronation, supination, hook and top roll strength.',
    goal: 'strength',
    durationWeeks: 10,
    phase: 'Specialisation',
    athleteType: 'Arm Wrestling',
    isTemplate: true,
    status: PlanStatus.active,
    days: [_awPulling, _awGrip, _awTechnique],
    createdAt: _kTemplateDate,
    updatedAt: _kTemplateDate,
  ),

  // 6 — CrossFit WOD
  WorkoutPlan(
    id: 'template_cf_wod',
    gymId: 'template',
    name: 'CrossFit WOD',
    description:
        'Five-day functional fitness programme. '
        'Mixes barbell strength, gymnastics, and high-intensity metabolic conditioning.',
    goal: 'general_fitness',
    durationWeeks: 8,
    phase: 'General Physical Preparedness',
    athleteType: 'CrossFit',
    isTemplate: true,
    status: PlanStatus.active,
    days: [_cfStrength, _cfMetcon, _cfSkills, _cfEndurance, _cfMaxOut],
    createdAt: _kTemplateDate,
    updatedAt: _kTemplateDate,
  ),

  // 7 — Full Body Beginner
  WorkoutPlan(
    id: 'template_fb_beginner',
    gymId: 'template',
    name: 'Full Body Beginner',
    description:
        'Three-day full-body programme for new gym-goers. '
        'Foundational movement patterns with progressive overload each session.',
    goal: 'general_fitness',
    durationWeeks: 8,
    phase: 'Foundation',
    athleteType: 'General',
    isTemplate: true,
    status: PlanStatus.active,
    days: [_fbDay1, _fbDay2, _fbDay3],
    createdAt: _kTemplateDate,
    updatedAt: _kTemplateDate,
  ),

  // 8 — Fat Loss HIIT
  WorkoutPlan(
    id: 'template_fl_hiit',
    gymId: 'template',
    name: 'Fat Loss HIIT',
    description:
        'Four-day high-intensity interval programme designed to maximise '
        'caloric expenditure and metabolic rate through circuit and Tabata formats.',
    goal: 'fat_loss',
    durationWeeks: 8,
    phase: 'Fat Loss',
    athleteType: 'Fat Loss',
    isTemplate: true,
    status: PlanStatus.active,
    days: [_hiit1, _hiit2, _hiit3, _hiit4],
    createdAt: _kTemplateDate,
    updatedAt: _kTemplateDate,
  ),
];
