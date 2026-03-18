import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/extensions.dart';

/// A circular arc gauge rendered via CustomPainter.
/// Draws a gradient arc from 0.0 to [value] (0.0–1.0) with a center text overlay.
class CircularGauge extends StatelessWidget {
  final double value; // 0.0 to 1.0
  final String label;
  final String centerText;
  final double size;
  final double strokeWidth;
  final List<Color>? gradientColors;

  const CircularGauge({
    super.key,
    required this.value,
    this.label = '',
    this.centerText = '',
    this.size = 200,
    this.strokeWidth = 14,
    this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;
    final colors = gradientColors ?? [t.brand, t.accent];

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _GaugePainter(
              value: value.clamp(0.0, 1.0),
              strokeWidth: strokeWidth,
              trackColor: t.ringTrack,
              gradientColors: colors,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (centerText.isNotEmpty)
                Text(
                  centerText,
                  style: TextStyle(
                    fontSize: size * 0.18,
                    fontWeight: FontWeight.w800,
                    color: t.textPrimary,
                    letterSpacing: -1,
                  ),
                ),
              if (label.isNotEmpty)
                Text(
                  label,
                  style: TextStyle(
                    fontSize: size * 0.08,
                    fontWeight: FontWeight.w500,
                    color: t.textSecondary,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double value;
  final double strokeWidth;
  final Color trackColor;
  final List<Color> gradientColors;

  _GaugePainter({
    required this.value,
    required this.strokeWidth,
    required this.trackColor,
    required this.gradientColors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - strokeWidth / 2;

    // Track arc (full circle background)
    final trackPaint = Paint()
      ..color = trackColor
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, radius, trackPaint);

    if (value <= 0) return;

    // Gradient arc
    final rect = Rect.fromCircle(center: center, radius: radius);
    final gradient = SweepGradient(
      startAngle: -math.pi / 2,
      endAngle: -math.pi / 2 + 2 * math.pi,
      colors: gradientColors,
      stops: const [0.0, 1.0],
    );

    final arcPaint = Paint()
      ..shader = gradient.createShader(rect)
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final sweepAngle = 2 * math.pi * value;
    canvas.drawArc(
      rect,
      -math.pi / 2,
      sweepAngle,
      false,
      arcPaint,
    );

    // Glow dot at the tip of the arc
    final tipAngle = -math.pi / 2 + sweepAngle;
    final tipX = center.dx + radius * math.cos(tipAngle);
    final tipY = center.dy + radius * math.sin(tipAngle);

    final glowPaint = Paint()
      ..color = gradientColors.last.withOpacity(0.6)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    canvas.drawCircle(Offset(tipX, tipY), strokeWidth / 2, glowPaint);

    final dotPaint = Paint()..color = gradientColors.last;
    canvas.drawCircle(Offset(tipX, tipY), strokeWidth / 2 - 1, dotPaint);
  }

  @override
  bool shouldRepaint(_GaugePainter oldDelegate) =>
      oldDelegate.value != value ||
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.trackColor != trackColor;
}
