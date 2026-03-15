import 'package:flutter_test/flutter_test.dart';
import 'package:gymos_ai/core/chart_buckets.dart';

void main() {
  group('bucketHourlyValues', () {
    test('groups hourly values into fixed-width buckets', () {
      final values = List<double>.generate(24, (index) => index.toDouble());

      final buckets = bucketHourlyValues(
        values: values,
        startHour: 5,
        endHour: 10,
        groupSize: 2,
        currentHour: 6,
      );

      expect(buckets.length, 3);
      expect(buckets[0].startHour, 5);
      expect(buckets[0].endHour, 6);
      expect(buckets[0].value, 5.5);
      expect(buckets[0].containsCurrentHour, isTrue);
      expect(buckets[1].containsCurrentHour, isFalse);
    });
  });

  group('bucketLabeledValues', () {
    test('returns values unchanged when already within the max bucket count', () {
      const values = [
        LabeledChartBucket(label: '01', value: 100),
        LabeledChartBucket(label: '02', value: 200),
      ];

      final buckets = bucketLabeledValues(values: values, maxBuckets: 4);

      expect(buckets.length, 2);
      expect(buckets.first.label, '01');
      expect(buckets.last.value, 200);
    });

    test('averages dense labeled values into compact buckets', () {
      const values = [
        LabeledChartBucket(label: '01', value: 100),
        LabeledChartBucket(label: '02', value: 200),
        LabeledChartBucket(label: '03', value: 300),
        LabeledChartBucket(label: '04', value: 500),
      ];

      final buckets = bucketLabeledValues(values: values, maxBuckets: 2);

      expect(buckets.length, 2);
      expect(buckets[0].label, '01-02');
      expect(buckets[0].value, 150);
      expect(buckets[1].label, '03-04');
      expect(buckets[1].value, 400);
    });
  });
}
