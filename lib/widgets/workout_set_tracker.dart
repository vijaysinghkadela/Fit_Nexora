import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/extensions.dart';

/// A row of dot indicators representing workout sets.
/// Completed sets show filled brand color, current set pulses with accent color,
/// and remaining sets are muted.
class WorkoutSetTracker extends StatelessWidget {
  final int totalSets;
  final int completedSets;
  final int currentSet; // 1-based index of current active set
  final double dotSize;
  final double spacing;

  const WorkoutSetTracker({
    super.key,
    required this.totalSets,
    required this.completedSets,
    this.currentSet = 0,
    this.dotSize = 12,
    this.spacing = 8,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(totalSets, (index) {
        final setNumber = index + 1; // 1-based
        final isCompleted = setNumber <= completedSets;
        final isCurrent = setNumber == currentSet;

        if (isCompleted) {
          return _CompletedDot(
            size: dotSize,
            color: t.brand,
            margin: EdgeInsets.only(right: index < totalSets - 1 ? spacing : 0),
          );
        } else if (isCurrent) {
          return _PulsingDot(
            size: dotSize,
            color: t.accent,
            margin: EdgeInsets.only(right: index < totalSets - 1 ? spacing : 0),
          );
        } else {
          return _MutedDot(
            size: dotSize,
            color: t.ringTrack,
            margin: EdgeInsets.only(right: index < totalSets - 1 ? spacing : 0),
          );
        }
      }),
    );
  }
}

class _CompletedDot extends StatelessWidget {
  final double size;
  final Color color;
  final EdgeInsets margin;

  const _CompletedDot({
    required this.size,
    required this.color,
    required this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      margin: margin,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.5),
            blurRadius: 6,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Icon(
        Icons.check,
        size: size * 0.65,
        color: Colors.white,
      ),
    ).animate().scale(duration: 200.ms, curve: Curves.elasticOut);
  }
}

class _PulsingDot extends StatefulWidget {
  final double size;
  final Color color;
  final EdgeInsets margin;

  const _PulsingDot({
    required this.size,
    required this.color,
    required this.margin,
  });

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _scale = Tween<double>(begin: 0.9, end: 1.3).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _opacity = Tween<double>(begin: 0.4, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: widget.margin,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Pulsing ring
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return Transform.scale(
                scale: _scale.value,
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.color
                        .withOpacity(_opacity.value),
                  ),
                ),
              );
            },
          ),
          // Core dot
          Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.color,
              boxShadow: [
                BoxShadow(
                  color: widget.color.withOpacity(0.6),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MutedDot extends StatelessWidget {
  final double size;
  final Color color;
  final EdgeInsets margin;

  const _MutedDot({
    required this.size,
    required this.color,
    required this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;
    return Container(
      width: size,
      height: size,
      margin: margin,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: Border.all(
          color: t.border,
          width: 1.5,
        ),
      ),
    );
  }
}
