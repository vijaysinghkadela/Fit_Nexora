import 'dart:async';
import 'package:flutter/material.dart';
import '../core/extensions.dart';

/// Animated countdown timer that counts from [initialSeconds] to zero.
/// Displays in MM:SS format and calls [onExpired] when finished.
class CountdownTimerWidget extends StatefulWidget {
  final int initialSeconds;
  final VoidCallback? onExpired;
  final TextStyle? textStyle;
  final bool autoStart;

  const CountdownTimerWidget({
    super.key,
    required this.initialSeconds,
    this.onExpired,
    this.textStyle,
    this.autoStart = true,
  });

  @override
  State<CountdownTimerWidget> createState() => _CountdownTimerWidgetState();
}

class _CountdownTimerWidgetState extends State<CountdownTimerWidget>
    with SingleTickerProviderStateMixin {
  late int _remaining;
  Timer? _timer;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _remaining = widget.initialSeconds;

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (widget.autoStart) _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_remaining <= 0) {
        _timer?.cancel();
        widget.onExpired?.call();
        return;
      }
      setState(() => _remaining--);

      // Pulse on last 10 seconds
      if (_remaining <= 10) {
        _pulseController
          ..reset()
          ..forward();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  String get _formatted {
    final m = (_remaining ~/ 60).toString().padLeft(2, '0');
    final s = (_remaining % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;
    final isUrgent = _remaining <= 10;

    final defaultStyle = TextStyle(
      fontSize: 48,
      fontWeight: FontWeight.w800,
      color: isUrgent ? t.danger : t.textPrimary,
      letterSpacing: -2,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    return RepaintBoundary(
      child: ScaleTransition(
      scale: _pulseAnimation,
      child: Text(
        _formatted,
        style: widget.textStyle ?? defaultStyle,
      ),
    ),
    );
  }
}
