import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../core/extensions.dart';

class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    required this.height,
    this.width = double.infinity,
    this.radius = 12,
    this.margin,
  });

  final double height;
  final double width;
  final double radius;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(radius),
      ),
    ).animate(onPlay: (controller) => controller.repeat()).shimmer(
          duration: 1200.ms,
          color: t.surfaceAlt.withOpacity(0.5),
        );
  }
}

class CardSkeleton extends StatelessWidget {
  const CardSkeleton({
    super.key,
    this.height = 120,
    this.padding = const EdgeInsets.all(16),
  });

  final double height;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: t.border),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SkeletonBox(height: 16, width: 140),
          SkeletonBox(height: 12, width: 220, radius: 8),
          SkeletonBox(height: 12, width: 180, radius: 8),
        ],
      ),
    );
  }
}

class ListTileSkeleton extends StatelessWidget {
  const ListTileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: t.border),
      ),
      child: Row(
        children: const [
          SkeletonBox(height: 52, width: 52, radius: 26),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(height: 16, width: 120),
                SizedBox(height: 10),
                SkeletonBox(height: 12, width: 200, radius: 8),
                SizedBox(height: 12),
                SkeletonBox(height: 28, width: double.infinity),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ChartSkeleton extends StatelessWidget {
  const ChartSkeleton({
    super.key,
    this.height = 120,
  });

  final double height;

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: t.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonBox(height: 16, width: 140),
          const SizedBox(height: 16),
          SkeletonBox(height: height, radius: 12),
        ],
      ),
    );
  }
}

class LoadingFooter extends StatelessWidget {
  const LoadingFooter({
    super.key,
    required this.isLoading,
    required this.hasMore,
    required this.onPressed,
    this.error,
  });

  final bool isLoading;
  final bool hasMore;
  final VoidCallback onPressed;
  final Object? error;

  @override
  Widget build(BuildContext context) {
    if (!hasMore && error == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: error != null
            ? TextButton.icon(
                onPressed: onPressed,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              )
            : isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: context.fitTheme.brand,
                    ),
                  )
                : TextButton(
                    onPressed: hasMore ? onPressed : null,
                    child: const Text('Load more'),
                  ),
      ),
    );
  }
}

class DashboardSkeletonScaffold extends StatelessWidget {
  const DashboardSkeletonScaffold({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;
    return Scaffold(
      backgroundColor: t.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: const [
            SkeletonBox(height: 28, width: 180),
            SizedBox(height: 16),
            CardSkeleton(height: 140),
            SizedBox(height: 16),
            CardSkeleton(height: 92),
            SizedBox(height: 16),
            CardSkeleton(height: 92),
            SizedBox(height: 16),
            ChartSkeleton(height: 110),
          ],
        ),
      ),
    );
  }
}
