import 'package:flutter/material.dart';
import '../core/extensions.dart';

/// Displays three macro-nutrient progress bars: protein, carbs, fat.
class MacroProgressBar extends StatelessWidget {
  final double proteinG;
  final double carbsG;
  final double fatG;
  final double proteinGoalG;
  final double carbsGoalG;
  final double fatGoalG;
  final bool showLabels;
  final bool showValues;

  const MacroProgressBar({
    super.key,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    this.proteinGoalG = 150,
    this.carbsGoalG = 250,
    this.fatGoalG = 65,
    this.showLabels = true,
    this.showValues = true,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MacroBar(
          label: 'Protein',
          current: proteinG,
          goal: proteinGoalG,
          unit: 'g',
          color: t.info,
          showLabel: showLabels,
          showValue: showValues,
        ),
        const SizedBox(height: 10),
        _MacroBar(
          label: 'Carbs',
          current: carbsG,
          goal: carbsGoalG,
          unit: 'g',
          color: t.warning,
          showLabel: showLabels,
          showValue: showValues,
        ),
        const SizedBox(height: 10),
        _MacroBar(
          label: 'Fat',
          current: fatG,
          goal: fatGoalG,
          unit: 'g',
          color: t.danger,
          showLabel: showLabels,
          showValue: showValues,
        ),
      ],
    );
  }
}

class _MacroBar extends StatelessWidget {
  final String label;
  final double current;
  final double goal;
  final String unit;
  final Color color;
  final bool showLabel;
  final bool showValue;

  const _MacroBar({
    required this.label,
    required this.current,
    required this.goal,
    required this.unit,
    required this.color,
    required this.showLabel,
    required this.showValue,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;
    final progress = goal > 0 ? (current / goal).clamp(0.0, 1.0) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showLabel || showValue)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (showLabel)
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: t.textSecondary,
                  ),
                ),
              if (showValue)
                Text(
                  '${current.toStringAsFixed(0)}$unit / ${goal.toStringAsFixed(0)}$unit',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: t.textMuted,
                  ),
                ),
            ],
          ),
        if (showLabel || showValue) const SizedBox(height: 4),
        LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: [
                // Track
                Container(
                  height: 6,
                  width: constraints.maxWidth,
                  decoration: BoxDecoration(
                    color: t.ringTrack,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                // Fill
                AnimatedContainer(
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOutCubic,
                  height: 6,
                  width: constraints.maxWidth * progress,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(3),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.4),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
