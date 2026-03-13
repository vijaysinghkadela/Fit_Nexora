import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants.dart';

/// Animated splash/loading screen shown during auth initialization.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Auto-navigate after delay (router will handle redirect)
    Future.delayed(const Duration(seconds: 2), () {
      if (context.mounted) {
        context.go('/login');
      }
    });

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo Icon
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.accent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.4),
                    blurRadius: 40,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: const Icon(
                Icons.fitness_center_rounded,
                size: 48,
                color: Colors.white,
              ),
            )
                .animate()
                .scale(
                  begin: const Offset(0.5, 0.5),
                  end: const Offset(1, 1),
                  duration: 600.ms,
                  curve: Curves.elasticOut,
                )
                .fadeIn(duration: 400.ms),

            const SizedBox(height: 32),

            // App Name
            Text(
              'GymOS',
              style: GoogleFonts.inter(
                fontSize: 40,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -1,
              ),
            )
                .animate(delay: 300.ms)
                .fadeIn(duration: 500.ms)
                .slideY(begin: 0.3, end: 0),

            const SizedBox(height: 8),

            // Tagline
            Text(
              'AI-Powered Gym Management',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: AppColors.textSecondary,
              ),
            ).animate(delay: 500.ms).fadeIn(duration: 500.ms),

            const SizedBox(height: 48),

            // Loading indicator
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: AppColors.primary,
                backgroundColor: AppColors.primary.withValues(alpha: 0.15),
              ),
            ).animate(delay: 700.ms).fadeIn(duration: 400.ms),
          ],
        ),
      ),
    );
  }
}
