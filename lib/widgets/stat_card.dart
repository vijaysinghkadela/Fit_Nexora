import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants.dart';

/// Animated stat card for dashboard metrics.
class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final int delay;
  final String? subtitle;
  final String? trend;
  final bool? isTrendPositive;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.delay = 0,
    this.subtitle,
    this.trend,
    this.isTrendPositive,
  });

  @override
  Widget build(BuildContext context) {
    // Generate a soft glow color based on the icon's color
    final glowColor = color.withValues(alpha: 0.15);

    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Stack(
            children: [
              // ─── AMBIENT GLOW ──────────────────────────────────────────
              Positioned(
                top: -20,
                left: -20,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [glowColor, Colors.transparent],
                      stops: const [0.1, 1.0],
                    ),
                  ),
                ),
              ),
              // ─── CONTENT ─────────────────────────────────────────────
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.bgInput,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: color.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Icon(icon, color: color, size: 22),
                      ),
                      if (trend != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.bgInput,
                            border: Border.all(
                              color: isTrendPositive == true
                                  ? AppColors.success.withValues(alpha: 0.3)
                                  : AppColors.error.withValues(alpha: 0.3),
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isTrendPositive == true
                                    ? Icons.trending_up_rounded
                                    : Icons.trending_down_rounded,
                                size: 14,
                                color: isTrendPositive == true
                                    ? AppColors.success
                                    : AppColors.error,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                trend!,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: isTrendPositive == true
                                      ? AppColors.success
                                      : AppColors.error,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    value,
                    style: GoogleFonts.inter(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        // Colored left border accent
        Positioned(
          left: 0,
          top: 14,
          bottom: 14,
          child: Container(
            width: 4,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.5),
                  blurRadius: 8,
                  offset: const Offset(2, 0),
                ),
              ],
            ),
          ),
        ),
      ],
    )
        .animate(delay: Duration(milliseconds: delay))
        .fadeIn(duration: AppConstants.normalAnimation)
        .slideY(begin: 0.08, end: 0, curve: AppConstants.smoothCurve);
  }
}
