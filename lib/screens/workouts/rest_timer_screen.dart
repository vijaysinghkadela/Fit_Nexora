import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/extensions.dart';
import '../../widgets/glassmorphic_card.dart';
import '../../widgets/circular_gauge.dart';

/// Rest timer screen with large circular progress ring and next exercise preview.
/// Route: `/workout/timer`
class RestTimerScreen extends ConsumerStatefulWidget {
  const RestTimerScreen({super.key});

  @override
  ConsumerState<RestTimerScreen> createState() => _RestTimerScreenState();
}

class _RestTimerScreenState extends ConsumerState<RestTimerScreen> {
  static const int _defaultRestSeconds = 90;
  int _remaining = 88; // pre-seeded to 01:28 as in spec
  late int _total;
  Timer? _timer;
  bool _isPaused = false;

  @override
  void initState() {
    super.initState();
    _total = _defaultRestSeconds;
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _isPaused) return;
      if (_remaining <= 0) {
        _timer?.cancel();
        _onExpired();
        return;
      }
      setState(() => _remaining--);
    });
  }

  void _onExpired() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rest complete! Start your next set.')),
      );
    }
  }

  void _addTime(int seconds) {
    setState(() {
      _remaining += seconds;
      _total += seconds;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _formattedTime {
    final m = (_remaining ~/ 60).toString().padLeft(2, '0');
    final s = (_remaining % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  double get _progress => _total > 0 ? (1 - _remaining / _total).clamp(0.0, 1.0) : 1.0;

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;

    return Scaffold(
      backgroundColor: t.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: t.textSecondary),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(
          'Rest Timer',
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: t.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 16),

              // ── Circular Gauge + Timer ────────────────────────────────
              Expanded(
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer glow ring
                      Container(
                        width: 260,
                        height: 260,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: t.accent.withValues(alpha: 0.15),
                              blurRadius: 48,
                              spreadRadius: 16,
                            ),
                          ],
                        ),
                      ),
                      CircularGauge(
                        value: _progress,
                        size: 240,
                        strokeWidth: 16,
                        gradientColors: [t.accent, t.brand],
                      ),
                      // Center content
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _formattedTime,
                            style: GoogleFonts.inter(
                              fontSize: 56,
                              fontWeight: FontWeight.w800,
                              color: t.textPrimary,
                              letterSpacing: -3,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                          Text(
                            'REST',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: t.accent,
                              letterSpacing: 3,
                            ),
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () => setState(() => _isPaused = !_isPaused),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: t.surfaceMuted,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: t.border),
                              ),
                              child: Text(
                                _isPaused ? 'PAUSED' : 'TAP TO PAUSE',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: t.textMuted,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(duration: 500.ms).scale(begin: const Offset(0.9, 0.9)),

              // ── Next Exercise Card ────────────────────────────────────
              _NextExerciseCard().animate(delay: 200.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1),

              const SizedBox(height: 20),

              // ── Action Buttons ────────────────────────────────────────
              Row(
                children: [
                  OutlinedButton(
                    onPressed: () => _addTime(30),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: t.border),
                      foregroundColor: t.textPrimary,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      '+30s',
                      style: GoogleFonts.inter(
                          fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () {
                      _timer?.cancel();
                      setState(() => _remaining = 0);
                      _onExpired();
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: t.textSecondary,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                    child: Text(
                      'Skip Rest',
                      style: GoogleFonts.inter(
                          fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const Spacer(),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: () {
                        _timer?.cancel();
                        Navigator.maybePop(context);
                      },
                      icon: const Icon(Icons.play_arrow_rounded, size: 18),
                      label: Text(
                        'Start Next Set',
                        style: GoogleFonts.inter(
                            fontSize: 13, fontWeight: FontWeight.w700),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: t.accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ).animate(delay: 300.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _NextExerciseCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;

    return GlassmorphicCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: t.brandGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.sports_gymnastics_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'NEXT EXERCISE',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: t.textMuted,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Incline Dumbbell Press',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: t.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '3 sets × 10 reps  •  70 kg',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: t.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: t.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}
