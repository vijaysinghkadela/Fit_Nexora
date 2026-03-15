import 'package:flutter/foundation.dart';

@immutable
class HourlyChartBucket {
  const HourlyChartBucket({
    required this.startHour,
    required this.endHour,
    required this.value,
    required this.containsCurrentHour,
  });

  final int startHour;
  final int endHour;
  final double value;
  final bool containsCurrentHour;
}

@immutable
class LabeledChartBucket {
  const LabeledChartBucket({
    required this.label,
    required this.value,
  });

  final String label;
  final double value;
}

List<HourlyChartBucket> bucketHourlyValues({
  required List<double> values,
  required int startHour,
  required int endHour,
  required int groupSize,
  required int currentHour,
}) {
  assert(groupSize > 0, 'groupSize must be greater than zero.');

  if (values.isEmpty || startHour > endHour) {
    return const [];
  }

  final safeEndHour = endHour.clamp(0, values.length - 1);
  final safeStartHour = startHour.clamp(0, safeEndHour);
  final buckets = <HourlyChartBucket>[];

  for (var hour = safeStartHour; hour <= safeEndHour; hour += groupSize) {
    final bucketEnd = (hour + groupSize - 1).clamp(hour, safeEndHour);
    final slice = values.sublist(hour, bucketEnd + 1);
    final total = slice.fold<double>(0, (sum, value) => sum + value);
    buckets.add(
      HourlyChartBucket(
        startHour: hour,
        endHour: bucketEnd,
        value: slice.isEmpty ? 0 : total / slice.length,
        containsCurrentHour:
            currentHour >= hour && currentHour <= bucketEnd,
      ),
    );
  }

  return buckets;
}

List<LabeledChartBucket> bucketLabeledValues({
  required List<LabeledChartBucket> values,
  required int maxBuckets,
}) {
  assert(maxBuckets > 0, 'maxBuckets must be greater than zero.');

  if (values.length <= maxBuckets) {
    return values;
  }

  final bucketSize = (values.length / maxBuckets).ceil();
  final buckets = <LabeledChartBucket>[];

  for (var index = 0; index < values.length; index += bucketSize) {
    final chunk = values.skip(index).take(bucketSize).toList();
    final average = chunk.fold<double>(0, (sum, item) => sum + item.value) /
        chunk.length;
    final startLabel = chunk.first.label;
    final endLabel = chunk.last.label;

    buckets.add(
      LabeledChartBucket(
        label: startLabel == endLabel ? startLabel : '$startLabel-$endLabel',
        value: average,
      ),
    );
  }

  return buckets;
}
