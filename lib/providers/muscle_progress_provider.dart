// lib/providers/muscle_progress_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/muscle_group_model.dart';
import '../models/body_measurement_model.dart';
import '../models/personal_record_model.dart';
import 'body_measurement_provider.dart';
import 'personal_records_provider.dart';
import 'member_provider.dart';

// ─── Exercise → muscle group lookup ─────────────────────────────────────────

/// Maps exercise name substrings (lower-case) to a muscle group id.
const _exerciseToMuscle = <String, String>{
  'bench press': 'chest',
  'incline': 'chest',
  'decline': 'chest',
  'chest fly': 'chest',
  'cable fly': 'chest',
  'pec deck': 'chest',
  'dip': 'chest',
  'push up': 'chest',
  'pushup': 'chest',
  'squat': 'quads',
  'leg press': 'quads',
  'hack squat': 'quads',
  'leg extension': 'quads',
  'lunge': 'quads',
  'leg curl': 'hamstrings',
  'romanian': 'hamstrings',
  'rdl': 'hamstrings',
  'nordic': 'hamstrings',
  'sumo': 'hamstrings',
  'good morning': 'lower_back',
  'deadlift': 'lower_back',
  'hyperextension': 'lower_back',
  'back extension': 'lower_back',
  'pull-up': 'lats',
  'pullup': 'lats',
  'pull up': 'lats',
  'lat pulldown': 'lats',
  'barbell row': 'lats',
  'cable row': 'lats',
  'seated row': 'lats',
  'chest-supported row': 'lats',
  'ohp': 'shoulders_front',
  'overhead press': 'shoulders_front',
  'arnold press': 'shoulders_front',
  'lateral raise': 'shoulders_front',
  'front raise': 'shoulders_front',
  'face pull': 'traps',
  'shrug': 'traps',
  'upright row': 'traps',
  'y-raise': 'traps',
  'bicep curl': 'biceps',
  'barbell curl': 'biceps',
  'hammer curl': 'biceps',
  'preacher curl': 'biceps',
  'cable curl': 'biceps',
  'incline curl': 'biceps',
  'tricep pushdown': 'triceps',
  'skullcrusher': 'triceps',
  'skull crusher': 'triceps',
  'overhead extension': 'triceps',
  'close-grip bench': 'triceps',
  'close grip bench': 'triceps',
  'calf raise': 'calves',
  'donkey calf': 'calves',
  'jump rope': 'calves',
  'hip thrust': 'glutes',
  'glute bridge': 'glutes',
  'bulgarian': 'glutes',
  'plank': 'abs',
  'cable crunch': 'abs',
  'sit-up': 'abs',
  'situp': 'abs',
  'hanging leg raise': 'abs',
  'ab wheel': 'abs',
  'wrist curl': 'forearms',
  'reverse curl': 'forearms',
  'farmer carry': 'forearms',
  'farmer walk': 'forearms',
  'neck harness': 'neck',
};

String? _muscleForExercise(String exerciseName) {
  final lower = exerciseName.toLowerCase();
  for (final entry in _exerciseToMuscle.entries) {
    if (lower.contains(entry.key)) return entry.value;
  }
  return null;
}

// ─── Measurement score helpers ──────────────────────────────────────────────

/// Normalizes a raw measurement against population norms (0.0–1.0).
/// Returns null if measurement is null.
double? _measurementScore({
  required double? valueCm,
  required double normMinCm,
  required double normMaxCm,
}) {
  if (valueCm == null) return null;
  return ((valueCm - normMinCm) / (normMaxCm - normMinCm)).clamp(0.0, 1.0);
}

// ─── Scoring ─────────────────────────────────────────────────────────────────

const double _defaultScore = 0.35;
const double _prWeight = 0.50;
const double _measurementWeight = 0.30;
const double _frequencyWeight = 0.20;

/// Computes normalized strength score (0.0–1.0) for a given PR using
/// the Epley 1RM against a reasonable benchmark (1× bodyweight = 0.5 score).
double _prScore(PersonalRecord pr, double bodyweightKg) {
  final orm = pr.estimatedOneRepMax;
  if (bodyweightKg <= 0) return _defaultScore;
  // 0.5× BW → 0.25, 1× BW → 0.50, 2× BW → 0.80, 3× BW → 1.0
  final ratio = orm / bodyweightKg;
  return (ratio / 3.0).clamp(0.0, 1.0);
}

/// Builds the full scored list from upstream data.
List<MuscleGroupProgress> _computeMuscles({
  required List<PersonalRecord> records,
  required List<BodyMeasurement> measurements,
  required List<Map<String, dynamic>> workoutHistory,
}) {
  final defaults = buildDefaultMuscles();

  // Latest measurement for circumference scoring
  final latest = measurements.isNotEmpty ? measurements.first : null;
  final bwKg = latest?.weightKg ?? 75.0;

  // PR map: muscleId → best PersonalRecord
  final prMap = <String, PersonalRecord>{};
  for (final r in records) {
    final muscleId = _muscleForExercise(r.exerciseName);
    if (muscleId == null) continue;
    final existing = prMap[muscleId];
    if (existing == null ||
        r.estimatedOneRepMax > existing.estimatedOneRepMax) {
      prMap[muscleId] = r;
    }
  }

  // Frequency map: muscleId → session count in last 30 days
  final freqMap = <String, int>{};
  for (final session in workoutHistory) {
    final exercises = session['exercises'] as List? ?? [];
    for (final ex in exercises) {
      final name = (ex['exercise_name'] ?? ex['name'] ?? '').toString();
      final muscleId = _muscleForExercise(name);
      if (muscleId != null) {
        freqMap[muscleId] = (freqMap[muscleId] ?? 0) + 1;
      }
    }
    // Also check top-level muscle_group field on session
    final topGroup = session['muscle_group']?.toString();
    if (topGroup != null) {
      final muscleId = _muscleForExercise(topGroup);
      if (muscleId != null) {
        freqMap[muscleId] = (freqMap[muscleId] ?? 0) + 1;
      }
    }
  }

  // Max frequency for normalization (cap at 12 sessions/30 days = 3×/week)
  const maxFreqSessions = 12;

  return defaults.map((muscle) {
    double score = 0.0;
    double totalWeight = 0.0;

    // Strength score from PR
    final pr = prMap[muscle.id];
    if (pr != null) {
      score += _prScore(pr, bwKg) * _prWeight;
      totalWeight += _prWeight;
    }

    // Measurement score
    double? measScore;
    switch (muscle.id) {
      case 'chest':
        measScore = _measurementScore(
            valueCm: latest?.chestCm,
            normMinCm: 85,
            normMaxCm: 120);
        break;
      case 'biceps':
      case 'triceps':
      case 'forearms':
        measScore = _measurementScore(
            valueCm: latest?.armCm, normMinCm: 28, normMaxCm: 48);
        break;
      case 'quads':
      case 'hamstrings':
        measScore = _measurementScore(
            valueCm: latest?.thighCm, normMinCm: 48, normMaxCm: 70);
        break;
      case 'abs':
        // Waist inversely correlates with abs definition
        if (latest?.waistCm != null) {
          measScore = 1.0 -
              _measurementScore(
                  valueCm: latest?.waistCm,
                  normMinCm: 65,
                  normMaxCm: 100)!;
        }
        break;
      default:
        break;
    }
    if (measScore != null) {
      score += measScore * _measurementWeight;
      totalWeight += _measurementWeight;
    }

    // Frequency score
    final freq = freqMap[muscle.id] ?? 0;
    final freqScore = (freq / maxFreqSessions).clamp(0.0, 1.0);
    if (freq > 0) {
      score += freqScore * _frequencyWeight;
      totalWeight += _frequencyWeight;
    }

    // If we have no data at all, use default score; otherwise normalise by used weights
    final finalScore = totalWeight > 0
        ? (score / totalWeight).clamp(0.0, 1.0)
        : _defaultScore;

    return muscle.copyWithScore(finalScore);
  }).toList();
}

// ─── Providers ───────────────────────────────────────────────────────────────

/// Full list of 14 muscle groups with computed gain percentages.
final muscleProgressProvider =
    Provider.autoDispose<AsyncValue<List<MuscleGroupProgress>>>((ref) {
  final recordsAsync = ref.watch(personalRecordsProvider);
  final measurementsAsync = ref.watch(bodyMeasurementProvider);
  final historyAsync = ref.watch(workoutHistoryProvider);

  if (recordsAsync.isLoading ||
      measurementsAsync.isLoading ||
      historyAsync.isLoading) {
    return const AsyncValue.loading();
  }

  final err =
      recordsAsync.error ?? measurementsAsync.error ?? historyAsync.error;
  if (err != null) {
    return AsyncValue.error(
        err,
        recordsAsync.stackTrace ??
            measurementsAsync.stackTrace ??
            historyAsync.stackTrace ??
            StackTrace.empty);
  }

  final muscles = _computeMuscles(
    records: recordsAsync.value ?? [],
    measurements: measurementsAsync.value ?? [],
    workoutHistory: historyAsync.value ?? [],
  );

  return AsyncValue.data(muscles);
});

/// The 3 lowest-scoring muscles (priority areas).
final weakMusclesProvider =
    Provider.autoDispose<List<MuscleGroupProgress>>((ref) {
  final muscles = ref.watch(muscleProgressProvider).value ?? [];
  final sorted = List.of(muscles)
    ..sort((a, b) => a.gainPercent.compareTo(b.gainPercent));
  return sorted.take(3).toList();
});

/// Composite overall development score 0–100.
final overallMuscleScoreProvider = Provider.autoDispose<double>((ref) {
  final muscles = ref.watch(muscleProgressProvider).value ?? [];
  if (muscles.isEmpty) return 0.0;
  final avg =
      muscles.map((m) => m.gainPercent).reduce((a, b) => a + b) /
          muscles.length;
  return avg * 100;
});
