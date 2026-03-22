import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';
import '../core/extensions.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const _targetProgress = 0.74;

  @override
  void initState() {
    super.initState();
    _navigateAfterSplash();
  }

  Future<void> _navigateAfterSplash() async {
    // If already authenticated, skip the full splash animation
    if (AppConfig.hasSupabase) {
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        // Already logged in — short delay so splash is still briefly visible
        await Future<void>.delayed(const Duration(milliseconds: 400));
        if (mounted) context.go('/login'); // router redirect handles role-based routing
        return;
      }
    }
    // Not authenticated — show a reduced 1-second splash
    await Future<void>.delayed(const Duration(seconds: 1));
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.fitTheme;

    return Scaffold(
      backgroundColor: colors.background,
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 0.88,
                  colors: [
                    colors.brand.withOpacity(0.14),
                    colors.background,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 120,
            left: -120,
            child: _SplashGlow(
              color: colors.brand.withOpacity(0.24),
              size: 260,
            ),
          ),
          Positioned(
            bottom: 90,
            right: -110,
            child: _SplashGlow(
              color: colors.brandSecondary.withOpacity(0.18),
              size: 240,
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 40, 28, 42),
              child: Column(
                children: [
                  const Spacer(),
                  Container(
                    width: 210,
                    height: 210,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colors.brand.withOpacity(0.16),
                      border: Border.all(
                        color: colors.textPrimary.withOpacity(0.08),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: colors.brand.withOpacity(0.26),
                          blurRadius: 46,
                          spreadRadius: 6,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        'F',
                        style: GoogleFonts.inter(
                          fontSize: 88,
                          fontWeight: FontWeight.w900,
                          color: colors.textPrimary,
                          letterSpacing: -2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 34),
                  RichText(
                    text: TextSpan(
                      style: GoogleFonts.inter(
                        fontSize: 44,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1.2,
                      ),
                      children: [
                        const TextSpan(text: 'Fit', style: TextStyle(color: Colors.white)),
                        TextSpan(
                          text: 'Nexora',
                          style: TextStyle(color: colors.brand),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'PREMIUM FITNESS INTELLIGENCE',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: colors.textMuted,
                      letterSpacing: 3,
                    ),
                  ),
                  const Spacer(),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 290),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: _targetProgress),
                      duration: const Duration(milliseconds: 1400),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, _) {
                        final percentage = (value * 100).round();
                        return Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Syncing performance data...',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: colors.textMuted,
                                    ),
                                  ),
                                ),
                                Text(
                                  '$percentage%',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: colors.brand,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: LinearProgressIndicator(
                                minHeight: 6,
                                value: value,
                                backgroundColor: colors.ringTrack,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  colors.brand,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (index) {
                      final activeOpacity = index == 2 ? 1.0 : 0.35 + (index * 0.18);
                      return Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: colors.brand.withOpacity(activeOpacity),
                          shape: BoxShape.circle,
                        ),
                      );
                    }),
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

class _SplashGlow extends StatelessWidget {
  const _SplashGlow({
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
