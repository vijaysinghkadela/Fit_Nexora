import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/constants.dart';

/// Reusable glassmorphic card with frosted-glass effect and subtle animated transitions.
class GlassmorphicCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsets? margin;
  final bool isAnimated;
  final VoidCallback? onTap;

  const GlassmorphicCard({
    super.key,
    required this.child,
    this.borderRadius = 20,
    this.margin,
    this.isAnimated = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = AnimatedContainer(
      duration: AppConstants.normalAnimation,
      curve: AppConstants.smoothCurve,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: AppColors.glassBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.bgCard
                  .withValues(alpha: 0.65), // Let more blur through
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            child: child,
          ),
        ),
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          highlightColor: AppColors.glassBg,
          splashColor: AppColors.glassBg.withValues(alpha: 0.1),
          child: content,
        ),
      );
    }
    return content;
  }
}
