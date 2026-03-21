import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_provider.dart';

// ─── Real-time stream of all check-in rows for a gym ────────────────────────

final gymCheckInsStreamProvider = StreamProvider.autoDispose.family<
    List<Map<String, dynamic>>, String>((ref, gymId) {
  final db = ref.watch(databaseServiceProvider);
  return db.streamGymCheckIns(gymId);
});

// ─── Current live traffic count (active check-ins in last 12 h) ─────────────

final currentTrafficCountProvider =
    Provider.autoDispose.family<AsyncValue<int>, String>((ref, gymId) {
  return ref.watch(gymCheckInsStreamProvider(gymId)).whenData((rows) {
    final cutoff = DateTime.now().subtract(const Duration(hours: 12));
    return rows.where((r) {
      if (r['checked_out_at'] != null) return false;
      final rawIn = r['checked_in_at'] as String?;
      if (rawIn == null) return false;
      final checkedIn = DateTime.tryParse(rawIn);
      return checkedIn != null && checkedIn.isAfter(cutoff);
    }).length;
  });
});

// ─── User's active check-in record ──────────────────────────────────────────

final activeCheckInProvider = FutureProvider.autoDispose.family<Map<String, dynamic>?,
    (String gymId, String userId)>((ref, args) async {
  final db = ref.watch(databaseServiceProvider);
  return db.getActiveCheckIn(gymId: args.$1, userId: args.$2);
});

// ─── Hourly traffic averages (List<double> with 24 entries, index = hour) ───

final hourlyTrafficProvider =
    FutureProvider.autoDispose.family<List<double>, String>((ref, gymId) async {
  final db = ref.watch(databaseServiceProvider);
  final checkins = await db.getRecentCheckIns(gymId: gymId);
  return _computeHourlyAverages(checkins);
});

// ─── Best 3 hours to visit (sorted by lowest average, gym hours only) ────────

final bestVisitTimesProvider =
    FutureProvider.autoDispose.family<List<int>, String>((ref, gymId) async {
  final averages = await ref.watch(hourlyTrafficProvider(gymId).future);

  // Only consider reasonable gym hours: 5 AM – 10 PM
  const gymStart = 5;
  const gymEnd = 22;

  final hoursWithAvg = [
    for (int h = gymStart; h <= gymEnd; h++) (hour: h, avg: averages[h]),
  ];

  // No historical data yet — return empty so UI shows built-in defaults
  if (hoursWithAvg.every((e) => e.avg == 0)) return [];

  hoursWithAvg.sort((a, b) => a.avg.compareTo(b.avg));
  return hoursWithAvg.take(3).map((e) => e.hour).toList()..sort();
});

// ─── Computation helper ──────────────────────────────────────────────────────

/// For every check-in, expand across the hours it spans.
/// Returns a 24-element list where [h] = average number of
/// people present during hour h, averaged across all days that had data.
List<double> _computeHourlyAverages(List<Map<String, dynamic>> checkins) {
  // hour → { dayKey → count }
  final Map<int, Map<String, int>> hourDayCounts = {};

  for (final row in checkins) {
    final raw = row['checked_in_at'];
    if (raw == null) continue;
    final checkIn = DateTime.tryParse(raw as String)?.toLocal();
    if (checkIn == null) continue;

    final rawOut = row['checked_out_at'];
    final checkOut = rawOut != null
        ? (DateTime.tryParse(rawOut as String)?.toLocal() ??
            checkIn.add(const Duration(hours: 1)))
        : checkIn.add(const Duration(hours: 1)); // assume 1 h if no checkout

    // Walk hour-by-hour from check-in to check-out
    var cursor = DateTime(checkIn.year, checkIn.month, checkIn.day, checkIn.hour);
    while (cursor.isBefore(checkOut)) {
      final h = cursor.hour;
      final dayKey = '${cursor.year}-${cursor.month}-${cursor.day}';
      hourDayCounts.putIfAbsent(h, () => {});
      hourDayCounts[h]![dayKey] = (hourDayCounts[h]![dayKey] ?? 0) + 1;
      cursor = cursor.add(const Duration(hours: 1));
    }
  }

  final List<double> averages = List.filled(24, 0.0);
  for (int h = 0; h < 24; h++) {
    final days = hourDayCounts[h];
    if (days != null && days.isNotEmpty) {
      final total = days.values.fold(0, (a, b) => a + b);
      averages[h] = total / days.length;
    }
  }
  return averages;
}
