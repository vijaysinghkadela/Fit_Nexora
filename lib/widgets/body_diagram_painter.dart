// lib/widgets/body_diagram_painter.dart
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../config/theme.dart';
import '../data/muscle_paths.dart';
import '../models/muscle_group_model.dart';

/// Draws a detailed anatomical body diagram (front or back) with color-coded
/// muscle sub-groups, leader lines, margin labels, and gain% badges.
///
/// Coordinate system: logical 200 × 480 canvas scaled to any device size.
class BodyDiagramPainter extends CustomPainter {
  final List<MuscleGroupProgress> muscles;
  final MuscleSide viewSide;
  final String? selectedMuscleId;
  final FitNexoraThemeTokens theme;
  final bool showLabels;
  final bool lowPerformance;

  const BodyDiagramPainter({
    required this.muscles,
    required this.viewSide,
    this.selectedMuscleId,
    required this.theme,
    this.showLabels = true,
    this.lowPerformance = false,
  });

  static const double _lw = 200;
  static const double _lh = 480;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / _lw, size.height / _lh);

    // 1. Draw silhouette background
    _drawSilhouette(canvas);

    // 2. Draw all sub-muscle paths with color coding
    _drawSubMuscles(canvas);

    // 3. Draw view header ("FRONT VIEW" / "BACK VIEW")
    _drawViewHeader(canvas);

    // 4. Draw leader lines + margin labels
    if (showLabels && !lowPerformance) {
      _drawLeaderLinesAndLabels(canvas);
    }

    // 5. Draw gain% badges on each major group
    _drawGainBadges(canvas);

    canvas.restore();
  }

  // ── 1. Silhouette ─────────────────────────────────────────────────────────

  void _drawSilhouette(Canvas canvas) {
    final path = viewSide == MuscleSide.front
        ? buildFrontSilhouette()
        : buildBackSilhouette();

    // Subtle fill
    final fillPaint = Paint()
      ..color = theme.surfaceMuted.withOpacity(0.18)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    // Outline
    final strokePaint = Paint()
      ..color = theme.border.withOpacity(0.30)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    canvas.drawPath(path, strokePaint);
  }

  // ── 2. Sub-muscle rendering ───────────────────────────────────────────────

  void _drawSubMuscles(Canvas canvas) {
    final subPaths = viewSide == MuscleSide.front
        ? AnatomyPathSet.frontPaths
        : AnatomyPathSet.backPaths;

    // Build a lookup for muscle data by group id
    final muscleMap = <String, MuscleGroupProgress>{};
    for (final m in muscles) {
      if (m.side == viewSide) muscleMap[m.id] = m;
    }

    // Collect selected group sub-paths for glow effect
    final selectedSubPaths = <Path>[];

    for (final sub in subPaths) {
      final parent = muscleMap[sub.parentGroupId];
      if (parent == null) continue;

      final isSelected = parent.id == selectedMuscleId;
      final baseColor = parent.statusColor(theme);
      final adjustedColor = _adjustShade(baseColor, sub.shadeOffset);
      final path = sub.buildPath();

      // Fill
      final fillPaint = Paint()
        ..color = adjustedColor.withOpacity(isSelected ? 0.78 : 0.52)
        ..style = PaintingStyle.fill;
      canvas.drawPath(path, fillPaint);

      // Stroke (muscle boundary)
      final strokePaint = Paint()
        ..color = _adjustShade(adjustedColor, -0.15).withOpacity(0.70)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.7;
      canvas.drawPath(path, strokePaint);

      // Inter-muscle separation line (thin dark)
      if (!lowPerformance) {
        final sepPaint = Paint()
          ..color = theme.background.withOpacity(0.45)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.3;
        canvas.drawPath(path, sepPaint);
      }

      if (isSelected) {
        selectedSubPaths.add(path);
      }
    }

    // Draw glow for selected group
    if (selectedSubPaths.isNotEmpty && !lowPerformance) {
      final parent = muscleMap[selectedMuscleId];
      if (parent != null) {
        final glowColor = parent.statusColor(theme);
        final glowPaint = Paint()
          ..color = glowColor.withOpacity(0.28)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4.0
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

        for (final p in selectedSubPaths) {
          canvas.drawPath(p, glowPaint);
        }
      }
    }
  }

  // ── 3. View header ────────────────────────────────────────────────────────

  void _drawViewHeader(Canvas canvas) {
    final text = viewSide == MuscleSide.front ? 'FRONT VIEW' : 'BACK VIEW';
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: 7.0,
          fontWeight: FontWeight.w800,
          color: theme.textMuted.withOpacity(0.7),
          letterSpacing: 1.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    tp.paint(canvas, Offset((_lw - tp.width) / 2, 2));
  }

  // ── 4. Leader lines + margin labels ───────────────────────────────────────

  void _drawLeaderLinesAndLabels(Canvas canvas) {
    final labels = AnatomyPathSet.getGroupLabels(viewSide);

    for (final lbl in labels) {
      final anchor = lbl.anchor;
      final labelPos = lbl.labelPos;

      // Leader line
      final linePaint = Paint()
        ..color = theme.textMuted.withOpacity(0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.4;

      canvas.drawLine(anchor, labelPos, linePaint);

      // Small dot at anchor
      final dotPaint = Paint()
        ..color = theme.textMuted.withOpacity(0.6)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(anchor, 1.2, dotPaint);

      // Label text
      final tp = TextPainter(
        text: TextSpan(
          text: lbl.label,
          style: TextStyle(
            fontSize: 5.5,
            fontWeight: FontWeight.w700,
            color: theme.textSecondary.withOpacity(0.85),
            letterSpacing: 0.3,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      // Position: if label is on the left margin, align left; if right, align right
      final isLeftMargin = labelPos.dx < _lw / 2;
      final textX = isLeftMargin ? labelPos.dx : labelPos.dx - tp.width;
      tp.paint(canvas, Offset(textX, labelPos.dy - tp.height / 2));
    }
  }

  // ── 5. Gain% badges ──────────────────────────────────────────────────────

  void _drawGainBadges(Canvas canvas) {
    final visibleMuscles = muscles.where((m) => m.side == viewSide).toList();

    for (final muscle in visibleMuscles) {
      final center = Offset(
        muscle.normalizedCenter.dx * _lw,
        muscle.normalizedCenter.dy * _lh,
      );
      final color = muscle.statusColor(theme);
      final label = muscle.gainPercentLabel;

      // Pill background
      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            fontSize: 6.5,
            fontWeight: FontWeight.w900,
            color: theme.textPrimary,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      const hPad = 4.0;
      const vPad = 2.0;
      final pillRect = Rect.fromCenter(
        center: center,
        width: tp.width + hPad * 2,
        height: tp.height + vPad * 2,
      );

      // Background pill
      final bgPaint = Paint()
        ..color = theme.surface.withOpacity(0.88);
      canvas.drawRRect(
        RRect.fromRectAndRadius(pillRect, const Radius.circular(6)),
        bgPaint,
      );

      // Border pill
      final borderPaint = Paint()
        ..color = color.withOpacity(0.60)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.6;
      canvas.drawRRect(
        RRect.fromRectAndRadius(pillRect, const Radius.circular(6)),
        borderPaint,
      );

      // Text
      tp.paint(
        canvas,
        Offset(pillRect.left + hPad, pillRect.top + vPad),
      );
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Color _adjustShade(Color base, double offset) {
    if (offset == 0.0) return base;
    final hsl = HSLColor.fromColor(base);
    return hsl
        .withLightness((hsl.lightness + offset).clamp(0.0, 1.0))
        .toColor();
  }

  @override
  bool shouldRepaint(BodyDiagramPainter old) =>
      old.selectedMuscleId != selectedMuscleId ||
      old.viewSide != viewSide ||
      old.muscles != muscles ||
      old.lowPerformance != lowPerformance;
}

// ═════════════════════════════════════════════════════════════════════════════
// Interactive wrapper widget
// ═════════════════════════════════════════════════════════════════════════════

/// Wraps [BodyDiagramPainter] with gesture detection, front/back toggle,
/// and legend. Tap any muscle group to select it.
class BodyDiagramWidget extends StatefulWidget {
  final List<MuscleGroupProgress> muscles;
  final FitNexoraThemeTokens theme;
  final void Function(MuscleGroupProgress muscle)? onMuscleTap;
  final bool showLabels;
  final bool lowPerformance;

  const BodyDiagramWidget({
    super.key,
    required this.muscles,
    required this.theme,
    this.onMuscleTap,
    this.showLabels = true,
    this.lowPerformance = false,
  });

  @override
  State<BodyDiagramWidget> createState() => _BodyDiagramWidgetState();
}

class _BodyDiagramWidgetState extends State<BodyDiagramWidget>
    with SingleTickerProviderStateMixin {
  MuscleSide _side = MuscleSide.front;
  String? _selectedId;
  late final AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  // Path cache for hit-testing
  final Map<String, Path> _groupPathCache = {};
  MuscleSide? _cachedSide;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeInOut),
    );
    _fadeCtrl.forward();
    _rebuildPathCache();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _rebuildPathCache() {
    _groupPathCache.clear();
    final visibleMuscles =
        widget.muscles.where((m) => m.side == _side).toList();
    for (final m in visibleMuscles) {
      _groupPathCache[m.id] =
          AnatomyPathSet.buildGroupPath(m.id, _side);
    }
    _cachedSide = _side;
  }

  void _switchSide(MuscleSide side) {
    if (_side == side) return;
    _fadeCtrl.reverse().then((_) {
      setState(() {
        _side = side;
        _selectedId = null;
      });
      _rebuildPathCache();
      _fadeCtrl.forward();
    });
  }

  void _onTap(TapUpDetails details, BoxConstraints constraints) {
    // Convert tap to logical canvas coordinates (200 × 480)
    final canvasX = details.localPosition.dx / constraints.maxWidth * 200;
    final canvasY = details.localPosition.dy / constraints.maxHeight * 480;
    final canvasPt = Offset(canvasX, canvasY);

    // Also compute normalized for bounding-box pre-filter
    final normX = details.localPosition.dx / constraints.maxWidth;
    final normY = details.localPosition.dy / constraints.maxHeight;
    final normPt = Offset(normX, normY);

    // Ensure cache is current
    if (_cachedSide != _side) _rebuildPathCache();

    MuscleGroupProgress? hit;
    double hitArea = double.infinity;

    for (final muscle
        in widget.muscles.where((m) => m.side == _side)) {
      // Quick bounding-box pre-check
      if (!muscle.normalizedBounds.inflate(0.02).contains(normPt)) continue;

      // Accurate path hit-test
      final path = _groupPathCache[muscle.id];
      if (path != null && path.contains(canvasPt)) {
        final bounds = path.getBounds();
        final area = bounds.width * bounds.height;
        if (area < hitArea) {
          hit = muscle;
          hitArea = area;
        }
      }
    }

    if (hit != null) {
      setState(() => _selectedId = hit!.id);
      widget.onMuscleTap?.call(hit);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.theme;

    return Column(
      children: [
        // Front / Back toggle
        _SideToggle(
          current: _side,
          onChanged: _switchSide,
          theme: t,
        ),
        const SizedBox(height: 12),

        // Diagram
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return GestureDetector(
                onTapUp: (d) => _onTap(d, constraints),
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: RepaintBoundary(
                    child: CustomPaint(
                      size: Size(constraints.maxWidth, constraints.maxHeight),
                      painter: BodyDiagramPainter(
                        muscles: widget.muscles,
                        viewSide: _side,
                        selectedMuscleId: _selectedId,
                        theme: t,
                        showLabels: widget.showLabels,
                        lowPerformance: widget.lowPerformance,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 8),

        // Legend
        _DiagramLegend(theme: t),
      ],
    );
  }
}

// ─── Side toggle ─────────────────────────────────────────────────────────────

class _SideToggle extends StatelessWidget {
  final MuscleSide current;
  final ValueChanged<MuscleSide> onChanged;
  final FitNexoraThemeTokens theme;

  const _SideToggle({
    required this.current,
    required this.onChanged,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: theme.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToggleBtn(
            label: 'FRONT',
            icon: Icons.face_rounded,
            active: current == MuscleSide.front,
            theme: theme,
            onTap: () => onChanged(MuscleSide.front),
          ),
          _ToggleBtn(
            label: 'BACK',
            icon: Icons.accessibility_new_rounded,
            active: current == MuscleSide.back,
            theme: theme,
            onTap: () => onChanged(MuscleSide.back),
          ),
        ],
      ),
    );
  }
}

class _ToggleBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final FitNexoraThemeTokens theme;
  final VoidCallback onTap;

  const _ToggleBtn({
    required this.label,
    required this.icon,
    required this.active,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: active ? theme.brand : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: theme.brand.withOpacity(0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 14,
                color: active ? Colors.white : theme.textSecondary),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: active ? Colors.white : theme.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Legend ───────────────────────────────────────────────────────────────────

class _DiagramLegend extends StatelessWidget {
  final FitNexoraThemeTokens theme;

  const _DiagramLegend({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _LegendDot(color: theme.success, label: 'Strong (70%+)'),
        const SizedBox(width: 16),
        _LegendDot(color: theme.warning, label: 'Developing (40–70%)'),
        const SizedBox(width: 16),
        _LegendDot(color: theme.danger, label: 'Needs Work (<40%)'),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
              fontSize: 9,
              color: color.withOpacity(0.85),
              fontWeight: FontWeight.w600,
            )),
      ],
    );
  }
}

// ─── Muscle score chip row ──────────────────────────────────────────────────

/// Horizontal scrollable row of muscle score chips.
class MuscleScoreChipRow extends StatelessWidget {
  final List<MuscleGroupProgress> muscles;
  final FitNexoraThemeTokens theme;
  final String? selectedId;
  final ValueChanged<MuscleGroupProgress>? onTap;

  const MuscleScoreChipRow({
    super.key,
    required this.muscles,
    required this.theme,
    this.selectedId,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: muscles.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final m = muscles[i];
          final isSelected = m.id == selectedId;
          final color = m.statusColor(theme);
          return GestureDetector(
            onTap: () => onTap?.call(m),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? color.withOpacity(0.2)
                    : theme.surfaceAlt,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? color : theme.border,
                  width: isSelected ? 1.5 : 1.0,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '${m.name} ${m.gainPercentLabel}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? color : theme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Muscle detail bottom-sheet content ──────────────────────────────────────

/// Builds the content for the muscle detail bottom sheet.
Widget buildMuscleDetailSheet({
  required BuildContext context,
  required MuscleGroupProgress muscle,
  required FitNexoraThemeTokens theme,
}) {
  final color = muscle.statusColor(theme);
  final desc = kMuscleDescriptions[muscle.id] ??
      'Keep training this muscle group consistently.';

  return DraggableScrollableSheet(
    initialChildSize: 0.55,
    minChildSize: 0.35,
    maxChildSize: 0.90,
    expand: false,
    builder: (context, scrollCtrl) {
      return Container(
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: theme.border, width: 1)),
        ),
        child: ListView(
          controller: scrollCtrl,
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.textMuted,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Header row
            Row(
              children: [
                Expanded(
                  child: Text(
                    muscle.name,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: theme.textPrimary,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: color.withOpacity(0.5), width: 1),
                  ),
                  child: Text(
                    muscle.statusLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Gain % arc
            Center(
              child: _MuscleArcIndicator(
                  percent: muscle.gainPercent, color: color, theme: theme),
            ),
            const SizedBox(height: 20),

            // Description
            Text(
              desc,
              style: TextStyle(
                fontSize: 13,
                color: theme.textSecondary,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 20),

            // Tip card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border:
                    Border(left: BorderSide(color: color, width: 3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(Icons.lightbulb_rounded,
                        size: 15, color: color),
                    const SizedBox(width: 6),
                    Text('Training Tip',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: color,
                        )),
                  ]),
                  const SizedBox(height: 8),
                  Text(
                    muscle.improvementTip,
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.textPrimary,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Suggested exercises
            Text(
              'SUGGESTED EXERCISES',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: theme.textMuted,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: muscle.suggestedExercises
                  .map((ex) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: theme.surfaceAlt,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: theme.border, width: 1),
                        ),
                        child: Text(
                          ex,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: theme.textSecondary,
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ],
        ),
      );
    },
  );
}

// ── Muscle arc indicator ────────────────────────────────────────────────────

class _MuscleArcIndicator extends StatelessWidget {
  final double percent;
  final Color color;
  final FitNexoraThemeTokens theme;

  const _MuscleArcIndicator({
    required this.percent,
    required this.color,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      height: 100,
      child: Stack(
        alignment: Alignment.center,
        children: [
          RepaintBoundary(
            child: CustomPaint(
              size: const Size(100, 100),
              painter: _ArcPainter(
                  percent: percent,
                  color: color,
                  track: theme.ringTrack),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${(percent * 100).round()}%',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
              Text(
                'gain',
                style: TextStyle(
                  fontSize: 10,
                  color: theme.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  final double percent;
  final Color color;
  final Color track;

  const _ArcPainter({
    required this.percent,
    required this.color,
    required this.track,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const strokeWidth = 10.0;
    final radius = (size.width / 2) - strokeWidth / 2;
    const startAngle = -math.pi / 2;

    final trackPaint = Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final arcPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      2 * math.pi * percent.clamp(0.0, 1.0),
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(_ArcPainter old) => old.percent != percent;
}
