import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/performance_provider.dart';
import '../config/theme.dart';
import '../core/constants.dart';
import '../core/extensions.dart';

/// Reusable glassmorphic card with frosted-glass effect, press-scale animation,
/// and haptic feedback on tap.
class GlassmorphicCard extends ConsumerStatefulWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsets? margin;
  final bool isAnimated;
  final bool applyBlur;
  final VoidCallback? onTap;

  const GlassmorphicCard({
    super.key,
    required this.child,
    this.borderRadius = 20,
    this.margin,
    this.isAnimated = true,
    this.applyBlur = true,
    this.onTap,
  });

  @override
  ConsumerState<GlassmorphicCard> createState() => _GlassmorphicCardState();
}

class _GlassmorphicCardState extends ConsumerState<GlassmorphicCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.fitTheme;
    final isLowPerformance = ref.watch(performanceProvider) || !widget.applyBlur;

    Widget content = AnimatedContainer(
      duration: AppConstants.normalAnimation,
      curve: AppConstants.smoothCurve,
      margin: widget.margin,
      decoration: BoxDecoration(
        color: isLowPerformance ? colors.surface : Colors.transparent,
        borderRadius: BorderRadius.circular(widget.borderRadius),
        border: Border.all(color: colors.glassBorder, width: 1),
        boxShadow: isLowPerformance
            ? null
            : [
                BoxShadow(
                  color: colors.glow.withOpacity(0.2),
                  blurRadius: 32,
                  offset: const Offset(0, 12),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: RepaintBoundary(
          child: _buildBackground(context, isLowPerformance, colors),
        ),
      ),
    );

    if (widget.onTap != null) {
      return AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeInOut,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              widget.onTap!();
            },
            onHighlightChanged: (highlighted) {
              if (mounted) setState(() => _pressed = highlighted);
            },
            borderRadius: BorderRadius.circular(widget.borderRadius),
            highlightColor: colors.glassFill,
            splashColor: colors.glassFill.withOpacity(0.5),
            child: content,
          ),
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
          borderRadius: BorderRadius.circular(widget.borderRadius),
        ),
        child: widget.child,
      );
    }

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
      child: Container(
        decoration: BoxDecoration(
          color: colors.glassFill,
          borderRadius: BorderRadius.circular(widget.borderRadius),
        ),
        child: widget.child,
      ),
    );
  }
}
