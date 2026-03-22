import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/extensions.dart';
import '../../providers/auth_provider.dart';

class PasswordUpdatedScreen extends ConsumerStatefulWidget {
  const PasswordUpdatedScreen({super.key});

  @override
  ConsumerState<PasswordUpdatedScreen> createState() =>
      _PasswordUpdatedScreenState();
}

class _PasswordUpdatedScreenState extends ConsumerState<PasswordUpdatedScreen> {
  Timer? _timer;
  int _secondsRemaining = 5;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_secondsRemaining == 1) {
        timer.cancel();
        _goNext();
        return;
      }
      setState(() => _secondsRemaining -= 1);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _goNext() {
    final hasUser = ref.read(currentUserProvider).value != null;
    context.go(hasUser ? '/settings' : '/login');
  }

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;
    final background = t.background;
    final panel = t.surface;
    final primary = t.brand;
    final muted = t.textMuted;

    return Scaffold(
      backgroundColor: background,
      body: Stack(
        children: [
          Positioned(
            top: 80,
            left: -80,
            child: _SuccessGlow(color: primary.withOpacity(0.16), size: 220),
          ),
          Positioned(
            bottom: -100,
            right: -90,
            child: _SuccessGlow(color: primary.withOpacity(0.1), size: 240),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 18, 28, 24),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          onPressed: () => Navigator.of(context).maybePop(),
                          icon: const Icon(Icons.arrow_back_rounded),
                          color: Colors.white,
                        ),
                      ),
                      const Expanded(
                        child: SizedBox(),
                      ),
                      Text(
                        'Security',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const Expanded(
                        child: SizedBox(),
                      ),
                      const SizedBox(width: 44),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    width: 132,
                    height: 132,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: primary.withOpacity(0.1),
                      border: Border.all(color: primary.withOpacity(0.16)),
                    ),
                    child: Center(
                      child: Container(
                        width: 92,
                        height: 92,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: primary,
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          size: 52,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 34),
                  Text(
                    'Success!',
                    style: GoogleFonts.inter(
                      fontSize: 42,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Your password has been updated successfully. Use your new credentials to log in.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      height: 1.55,
                      color: muted,
                    ),
                  ),
                  const SizedBox(height: 34),
                  Container(
                    width: double.infinity,
                    height: 118,
                    decoration: BoxDecoration(
                      color: panel,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: primary.withOpacity(0.08)),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _DashBar(color: primary.withOpacity(0.55)),
                          const SizedBox(width: 14),
                          _DashBar(color: primary.withOpacity(0.25)),
                          const SizedBox(width: 14),
                          _DashBar(color: primary.withOpacity(0.14)),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(56),
                        backgroundColor: primary,
                        foregroundColor: Colors.white,
                        textStyle: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      onPressed: _goNext,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Continue'),
                          SizedBox(width: 8),
                          Icon(Icons.settings_rounded),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Auto-redirecting in $_secondsRemaining seconds...',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: muted,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.fitness_center_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'FITNEXORA',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashBar extends StatelessWidget {
  const _DashBar({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 4,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

class _SuccessGlow extends StatelessWidget {
  const _SuccessGlow({
    required this.color,
    required this.size,
  });

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, Colors.transparent],
          ),
        ),
      ),
    );
  }
}
