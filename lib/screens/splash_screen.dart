import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants.dart';
import '../core/responsive.dart';


/// Animated splash/loading screen shown during auth initialization.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final rs = ResponsiveSize.of(context);

    // After the animation, let GoRouter's redirect decide the destination:
    //   • Authenticated  → /dashboard
    //   • Unauthenticated → /login
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
              width: rs.sp(100),
              height: rs.sp(100),
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
              child: Icon(
                Icons.fitness_center_rounded,
                size: rs.sp(48),
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

            SizedBox(height: rs.sp(32)),

            // App Name
            Text(
              'GymOS',
              style: GoogleFonts.inter(
                fontSize: rs.sp(40),
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -1,
              ),
            )
                .animate(delay: 300.ms)
                .fadeIn(duration: 500.ms)
                .slideY(begin: 0.3, end: 0),

            SizedBox(height: rs.sp(8)),

            // Tagline
            Text(
              'AI-Powered Gym Management',
              style: GoogleFonts.inter(
                fontSize: rs.sp(16),
                fontWeight: FontWeight.w400,
                color: AppColors.textSecondary,
              ),
            ).animate(delay: 500.ms).fadeIn(duration: 500.ms),

            SizedBox(height: rs.sp(48)),

            // Loading indicator
            SizedBox(
              width: rs.sp(32),
              height: rs.sp(32),
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
