import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/performance_provider.dart';
import '../config/theme.dart';
import '../core/constants.dart';
import '../core/extensions.dart';

/// Reusable glassmorphic card with frosted-glass effect and subtle animated transitions.
class GlassmorphicCard extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.fitTheme;
    final isLowPerformance = ref.watch(performanceProvider);

    Widget content = AnimatedContainer(
      duration: AppConstants.normalAnimation,
      curve: AppConstants.smoothCurve,
      margin: margin,
      decoration: BoxDecoration(
        color: isLowPerformance ? colors.surface : Colors.transparent,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: colors.glassBorder, width: 1),
        boxShadow: isLowPerformance
            ? null
            : [
                BoxShadow(
                  color: colors.glow.withValues(alpha: 0.2),
                  blurRadius: 32,
                  offset: const Offset(0, 12),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: RepaintBoundary(
          child: _buildBackground(context, isLowPerformance, colors),
        ),
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          highlightColor: colors.glassFill,
          splashColor: colors.glassFill.withValues(alpha: 0.5),
          child: content,
        ),
      );
    }
    return content;
  }

  Widget _buildBackground(
      BuildContext context, bool isLowPerformance, FitNexoraThemeTokens colors) {
    if (isLowPerformance) {
      return Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: child,
      );
    }

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
      child: Container(
        decoration: BoxDecoration(
          color: colors.glassFill,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: child,
      ),
    );
  }
}
