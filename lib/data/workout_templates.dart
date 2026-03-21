import '../models/workout_plan_model.dart';

class WorkoutTemplates {
  static const Map<String, List<TrainingDay>> _templates = {
    'Powerlifting': [
      TrainingDay(
        dayIndex: 0,
        dayName: 'Day 1: Heavy Squat & Leg Acc',
        muscleGroup: 'Legs',
        exercises: [
          Exercise(name: 'Barbell Back Squat', sets: 5, reps: '3-5', rpe: 8, restSeconds: 180, tempo: '2110', intensity: 'High', orderIndex: 0),
          Exercise(name: 'Leg Press', sets: 3, reps: '8-10', rpe: 7, restSeconds: 90, intensity: 'Medium', orderIndex: 1),
          Exercise(name: 'Leg Curls', sets: 3, reps: '12', rpe: 7, restSeconds: 60, intensity: 'Medium', orderIndex: 2),
        ],
      ),
      TrainingDay(
        dayIndex: 1,
        dayName: 'Day 2: Heavy Bench & Push Acc',
        muscleGroup: 'Chest, Shoulders, Triceps',
        exercises: [
          Exercise(name: 'Barbell Bench Press', sets: 5, reps: '3-5', rpe: 8, restSeconds: 180, tempo: '2110', intensity: 'High', orderIndex: 0),
          Exercise(name: 'Incline Dumbbell Press', sets: 3, reps: '8', rpe: 7, restSeconds: 90, intensity: 'Medium', orderIndex: 1),
          Exercise(name: 'Overhead Tricep Extension', sets: 3, reps: '10-12', rpe: 7, restSeconds: 60, intensity: 'Low', orderIndex: 2),
        ],
      ),
      TrainingDay(
        dayIndex: 2,
        dayName: 'Day 3: Heavy Deadlift & Pull Acc',
        muscleGroup: 'Back, Hamstrings',
        exercises: [
          Exercise(name: 'Deadlift', sets: 5, reps: '2-4', rpe: 8, restSeconds: 240, tempo: '1110', intensity: 'High', orderIndex: 0),
          Exercise(name: 'Barbell Row', sets: 3, reps: '8', rpe: 7, restSeconds: 90, intensity: 'Medium', orderIndex: 1),
          Exercise(name: 'Lat Pulldowns', sets: 3, reps: '12', rpe: 7, restSeconds: 60, intensity: 'Low', orderIndex: 2),
        ],
      ),
    ],
    'Bodybuilding': [
      TrainingDay(
        dayIndex: 0,
        dayName: 'Push Day (Chest, Shoulders, Triceps)',
        muscleGroup: 'Chest, Shoulders, Triceps',
        exercises: [
          Exercise(name: 'Incline Dumbbell Press', sets: 4, reps: '8-10', rpe: 8, restSeconds: 90, tempo: '3110', intensity: 'High', orderIndex: 0),
          Exercise(name: 'Pec Deck Fly', sets: 3, reps: '12-15', rpe: 8, restSeconds: 60, tempo: '2111', intensity: 'Medium', orderIndex: 1),
          Exercise(name: 'Lateral Raises', sets: 4, reps: '15-20', rpe: 9, restSeconds: 60, tempo: '2011', intensity: 'Medium', orderIndex: 2),
          Exercise(name: 'Tricep Rope Pushdowns', sets: 4, reps: '12-15', rpe: 8, restSeconds: 60, tempo: '2110', intensity: 'Medium', supersetGroupId: 'A', orderIndex: 3),
          Exercise(name: 'Overhead Extension', sets: 4, reps: '12-15', rpe: 8, restSeconds: 60, tempo: '2110', intensity: 'Medium', supersetGroupId: 'A', orderIndex: 4),
        ],
      ),
      TrainingDay(
        dayIndex: 1,
        dayName: 'Pull Day (Back, Biceps, Rear Delts)',
        muscleGroup: 'Back, Biceps',
        exercises: [
          Exercise(name: 'Pull-ups', sets: 4, reps: '8-10', rpe: 8, restSeconds: 90, tempo: '2110', intensity: 'High', orderIndex: 0),
          Exercise(name: 'Seated Cable Row', sets: 4, reps: '10-12', rpe: 8, restSeconds: 90, tempo: '3110', intensity: 'Medium', orderIndex: 1),
          Exercise(name: 'Reverse Pec Deck', sets: 3, reps: '15', rpe: 9, restSeconds: 60, tempo: '2011', intensity: 'Medium', orderIndex: 2),
          Exercise(name: 'Preacher Curls', sets: 3, reps: '10-12', rpe: 8, restSeconds: 60, tempo: '3110', intensity: 'Medium', supersetGroupId: 'B', orderIndex: 3),
          Exercise(name: 'Hammer Curls', sets: 3, reps: '12-15', rpe: 8, restSeconds: 60, tempo: '2110', intensity: 'Medium', supersetGroupId: 'B', orderIndex: 4),
        ],
      ),
      TrainingDay(
        dayIndex: 2,
        dayName: 'Leg Day',
        muscleGroup: 'Legs',
        exercises: [
          Exercise(name: 'Hack Squat', sets: 4, reps: '8-10', rpe: 8, restSeconds: 120, tempo: '3110', intensity: 'High', orderIndex: 0),
          Exercise(name: 'Leg Press', sets: 3, reps: '12-15', rpe: 8, restSeconds: 90, tempo: '2110', intensity: 'Medium', orderIndex: 1),
          Exercise(name: 'Romanian Deadlift', sets: 4, reps: '10-12', rpe: 8, restSeconds: 90, tempo: '3110', intensity: 'Medium', orderIndex: 2),
          Exercise(name: 'Calf Raises', sets: 5, reps: '15-20', rpe: 9, restSeconds: 60, tempo: '2210', intensity: 'Low', orderIndex: 3),
        ],
      ),
    ],
    'Arm Wrestling': [
      TrainingDay(
        dayIndex: 0,
        dayName: 'Table Time & Fundamentals',
        muscleGroup: 'Arms, Grip, Forearms',
        exercises: [
          Exercise(name: 'Pronation Extensions (Cable)', sets: 4, reps: '12-15', rpe: 8, restSeconds: 90, tempo: '1010', intensity: 'High', orderIndex: 0),
          Exercise(name: 'Cupping / Wrist Curls', sets: 5, reps: '15-20', rpe: 9, restSeconds: 60, tempo: '1111', intensity: 'High', orderIndex: 1),
          Exercise(name: 'Static Holds (Thick Bar)', sets: 3, reps: 'Hold', setTime: '30s', rpe: 8, restSeconds: 90, intensity: 'Medium', orderIndex: 2),
          Exercise(name: 'Fat Grip Hammer Curls', sets: 3, reps: '10-12', rpe: 7, restSeconds: 60, tempo: '2110', intensity: 'Medium', orderIndex: 3),
        ],
      ),
      TrainingDay(
        dayIndex: 1,
        dayName: 'Back Pressure & Hook Training',
        muscleGroup: 'Back, Biceps',
        exercises: [
          Exercise(name: 'Half ROM Pull-ups (Top)', sets: 4, reps: '8-10', rpe: 8, restSeconds: 90, tempo: '1210', intensity: 'High', orderIndex: 0),
          Exercise(name: 'Rising (Thumb Loop Cable)', sets: 4, reps: '12-15', rpe: 8, restSeconds: 60, tempo: '1011', intensity: 'High', orderIndex: 1),
          Exercise(name: 'Defensive Hook Holds', sets: 3, reps: 'Hold', setTime: '20s', rpe: 9, restSeconds: 90, intensity: 'High', orderIndex: 2),
          Exercise(name: 'Heavy Preacher Curls', sets: 3, reps: '5-8', rpe: 8, restSeconds: 120, tempo: '2110', intensity: 'High', orderIndex: 3),
        ],
      ),
    ],
    'Olympic Weightlifting': [
      TrainingDay(
        dayIndex: 0,
        dayName: 'Snatch Focus',
        muscleGroup: 'Full Body',
        exercises: [
          Exercise(name: 'Snatch', sets: 5, reps: '2-3', rpe: 8, restSeconds: 180, tempo: '10X0', intensity: 'High', orderIndex: 0),
          Exercise(name: 'Snatch Pulls', sets: 4, reps: '3-5', rpe: 8, restSeconds: 120, tempo: '2110', intensity: 'Medium', orderIndex: 1),
          Exercise(name: 'Overhead Squat', sets: 3, reps: '5', rpe: 7, restSeconds: 120, tempo: '3110', intensity: 'Medium', orderIndex: 2),
        ],
      ),
      TrainingDay(
        dayIndex: 1,
        dayName: 'Clean & Jerk Focus',
        muscleGroup: 'Full Body',
        exercises: [
          Exercise(name: 'Clean & Jerk', sets: 5, reps: '2-3', rpe: 8, restSeconds: 180, tempo: '10X0', intensity: 'High', orderIndex: 0),
          Exercise(name: 'Clean Pulls', sets: 4, reps: '3-5', rpe: 8, restSeconds: 120, tempo: '2110', intensity: 'Medium', orderIndex: 1),
          Exercise(name: 'Front Squat', sets: 4, reps: '4-6', rpe: 8, restSeconds: 180, tempo: '3110', intensity: 'High', orderIndex: 2),
        ],
      ),
    ],
    'General': [
      TrainingDay(
        dayIndex: 0,
        dayName: 'Full Body A',
        muscleGroup: 'Full Body',
        exercises: [
          Exercise(name: 'Goblet Squat', sets: 3, reps: '10', rpe: 7, restSeconds: 60, tempo: '2110', intensity: 'Medium', orderIndex: 0),
          Exercise(name: 'Dumbbell Bench Press', sets: 3, reps: '10', rpe: 7, restSeconds: 60, tempo: '2110', intensity: 'Medium', orderIndex: 1),
          Exercise(name: 'Dumbbell Row', sets: 3, reps: '10', rpe: 7, restSeconds: 60, tempo: '2110', intensity: 'Medium', orderIndex: 2),
        ],
      ),
      TrainingDay(
        dayIndex: 1,
        dayName: 'Full Body B',
        muscleGroup: 'Full Body',
        exercises: [
          Exercise(name: 'Romanian Deadlift', sets: 3, reps: '10', rpe: 7, restSeconds: 60, tempo: '2110', intensity: 'Medium', orderIndex: 0),
          Exercise(name: 'Overhead Press', sets: 3, reps: '10', rpe: 7, restSeconds: 60, tempo: '2110', intensity: 'Medium', orderIndex: 1),
          Exercise(name: 'Lat Pulldowns', sets: 3, reps: '12', rpe: 7, restSeconds: 60, tempo: '2110', intensity: 'Medium', orderIndex: 2),
        ],
      ),
    ],
  };

  static List<TrainingDay> getTemplate(String athleteType) {
    if (_templates.containsKey(athleteType)) {
      return _templates[athleteType]!.map((d) => _cloneDay(d)).toList();
    }
    return _templates['General']!.map((d) => _cloneDay(d)).toList();
  }

  static TrainingDay _cloneDay(TrainingDay d) {
    return TrainingDay(
      dayIndex: d.dayIndex,
      dayName: d.dayName,
      muscleGroup: d.muscleGroup,
      notes: d.notes,
      exercises: d.exercises.map((e) => Exercise(
        name: e.name,
        sets: e.sets,
        reps: e.reps,
        restSeconds: e.restSeconds,
        setTime: e.setTime,
        rpe: e.rpe,
        supersetGroupId: e.supersetGroupId,
        intensity: e.intensity,
        tempo: e.tempo,
        equipment: e.equipment,
        cue: e.cue,
        substitute: e.substitute,
        orderIndex: e.orderIndex,
      )).toList(),
    );
  }
}
