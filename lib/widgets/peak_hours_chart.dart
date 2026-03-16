import 'package:flutter/material.dart';
import '../core/extensions.dart';

/// Data model for a single hour's gym traffic data.
class PeakHourData {
  final int hour; // 0–23
  final double occupancy; // 0.0–1.0

  const PeakHourData({required this.hour, required this.occupancy});

  String get label {
    if (hour == 0) return '12a';
    if (hour < 12) return '${hour}a';
    if (hour == 12) return '12p';
    return '${hour - 12}p';
  }
}

/// Bar chart heatmap displaying gym traffic per hour.
class PeakHoursChart extends StatelessWidget {
  final List<PeakHourData> data;
  final double height;
  final double barWidth;

  const PeakHoursChart({
    super.key,
    required this.data,
    this.height = 80,
    this.barWidth = 28,
  });

  Color _barColor(double occupancy, BuildContext context) {
    final t = context.fitTheme;
    if (occupancy >= 0.75) return t.danger;
    if (occupancy >= 0.5) return t.warning;
    if (occupancy >= 0.25) return t.accent;
    return t.info;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;

    return SizedBox(
      height: height + 36,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: data.map((d) {
            final barH = (height * d.occupancy).clamp(4.0, height);
            final color = _barColor(d.occupancy, context);

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Occupancy % label on hover — shown only for peaks
                  if (d.occupancy >= 0.75)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text(
                        '${(d.occupancy * 100).round()}%',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          color: t.danger,
                        ),
                      ),
                    )
                  else
                    const SizedBox(height: 14),
                  // Bar
                  AnimatedContainer(
                    duration: Duration(milliseconds: 400 + data.indexOf(d) * 20),
                    curve: Curves.easeOutCubic,
                    width: barWidth,
                    height: barH,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(6),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          color,
                          color.withValues(alpha: 0.7),
                        ],
                      ),
                    ),
                  ),
                  // Hour label
                  const SizedBox(height: 6),
                  SizedBox(
                    width: barWidth,
                    child: Text(
                      d.label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                        color: t.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

/// Convenience factory for sample data (6 AM – 10 PM).
List<PeakHourData> samplePeakHours() => [
      const PeakHourData(hour: 6, occupancy: 0.45),
      const PeakHourData(hour: 7, occupancy: 0.72),
      const PeakHourData(hour: 8, occupancy: 0.91),
      const PeakHourData(hour: 9, occupancy: 0.68),
      const PeakHourData(hour: 10, occupancy: 0.42),
      const PeakHourData(hour: 11, occupancy: 0.35),
      const PeakHourData(hour: 12, occupancy: 0.55),
      const PeakHourData(hour: 13, occupancy: 0.48),
      const PeakHourData(hour: 14, occupancy: 0.30),
      const PeakHourData(hour: 15, occupancy: 0.28),
      const PeakHourData(hour: 16, occupancy: 0.50),
      const PeakHourData(hour: 17, occupancy: 0.82),
      const PeakHourData(hour: 18, occupancy: 0.95),
      const PeakHourData(hour: 19, occupancy: 0.88),
      const PeakHourData(hour: 20, occupancy: 0.60),
      const PeakHourData(hour: 21, occupancy: 0.38),
      const PeakHourData(hour: 22, occupancy: 0.20),
    ];
