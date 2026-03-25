// lib/data/muscle_paths.dart
//
// Anatomically accurate muscle path definitions for the body diagram.
// All coordinates are in the logical 200×480 canvas space.
// Bilateral muscles are authored for the LEFT side and mirrored for the RIGHT.

import 'dart:ui';

import '../models/muscle_group_model.dart';

// ─── Path command types ─────────────────────────────────────────────────────

sealed class PathCommand {
  const PathCommand();
}

class MoveToCmd extends PathCommand {
  final double x, y;
  const MoveToCmd(this.x, this.y);
}

class LineToCmd extends PathCommand {
  final double x, y;
  const LineToCmd(this.x, this.y);
}

class CubicToCmd extends PathCommand {
  final double x1, y1, x2, y2, x3, y3;
  const CubicToCmd(this.x1, this.y1, this.x2, this.y2, this.x3, this.y3);
}

class CloseCmd extends PathCommand {
  const CloseCmd();
}

// ─── Sub-muscle path definition ─────────────────────────────────────────────

class SubMusclePath {
  final String subId;
  final String label;
  final String parentGroupId;
  final MuscleSide side;
  final List<PathCommand> commands;
  final double shadeOffset; // -0.15 to +0.15
  final Offset labelAnchor; // in 200×480 space
  final Offset labelPosition; // in 200×480 space

  const SubMusclePath({
    required this.subId,
    required this.label,
    required this.parentGroupId,
    required this.side,
    required this.commands,
    this.shadeOffset = 0.0,
    required this.labelAnchor,
    required this.labelPosition,
  });

  Path buildPath() {
    final p = Path();
    for (final cmd in commands) {
      switch (cmd) {
        case MoveToCmd(:final x, :final y):
          p.moveTo(x, y);
        case LineToCmd(:final x, :final y):
          p.lineTo(x, y);
        case CubicToCmd(:final x1, :final y1, :final x2, :final y2, :final x3, :final y3):
          p.cubicTo(x1, y1, x2, y2, x3, y3);
        case CloseCmd():
          p.close();
      }
    }
    return p;
  }
}

// ─── Mirror helper ──────────────────────────────────────────────────────────

/// Mirror path commands around x = 100 (center of 200-wide canvas)
List<PathCommand> _mirrorX(List<PathCommand> cmds) {
  return cmds.map((cmd) {
    return switch (cmd) {
      MoveToCmd(:final x, :final y) => MoveToCmd(200.0 - x, y),
      LineToCmd(:final x, :final y) => LineToCmd(200.0 - x, y),
      CubicToCmd(:final x1, :final y1, :final x2, :final y2, :final x3, :final y3) =>
        CubicToCmd(200.0 - x1, y1, 200.0 - x2, y2, 200.0 - x3, y3),
      CloseCmd() => const CloseCmd(),
    };
  }).toList();
}

SubMusclePath _mirror(SubMusclePath src, String newSubId) {
  return SubMusclePath(
    subId: newSubId,
    label: src.label,
    parentGroupId: src.parentGroupId,
    side: src.side,
    commands: _mirrorX(src.commands),
    shadeOffset: src.shadeOffset,
    labelAnchor: Offset(200.0 - src.labelAnchor.dx, src.labelAnchor.dy),
    labelPosition: Offset(200.0 - src.labelPosition.dx, src.labelPosition.dy),
  );
}

// ═════════════════════════════════════════════════════════════════════════════
// SILHOUETTE PATHS
// ═════════════════════════════════════════════════════════════════════════════

Path buildFrontSilhouette() {
  final p = Path();

  // ── Head ──
  p.moveTo(88, 8);
  p.cubicTo(78, 8, 72, 16, 72, 26);
  p.cubicTo(72, 36, 78, 44, 88, 46);
  p.lineTo(92, 46);
  p.cubicTo(94, 46, 96, 46, 98, 46);
  p.lineTo(112, 46);
  p.cubicTo(122, 44, 128, 36, 128, 26);
  p.cubicTo(128, 16, 122, 8, 112, 8);
  p.close();

  // ── Neck ──
  p.moveTo(90, 46);
  p.lineTo(90, 56);
  p.cubicTo(90, 58, 92, 60, 95, 60);
  p.lineTo(105, 60);
  p.cubicTo(108, 60, 110, 58, 110, 56);
  p.lineTo(110, 46);
  p.close();

  // ── Torso (shoulders to hips) ──
  p.moveTo(48, 62);
  p.cubicTo(34, 64, 28, 74, 26, 86);
  p.lineTo(26, 100);
  p.lineTo(26, 210);
  p.cubicTo(26, 220, 32, 230, 50, 234);
  p.lineTo(80, 236);
  p.lineTo(80, 248);
  p.lineTo(120, 248);
  p.lineTo(120, 236);
  p.lineTo(150, 234);
  p.cubicTo(168, 230, 174, 220, 174, 210);
  p.lineTo(174, 100);
  p.lineTo(174, 86);
  p.cubicTo(172, 74, 166, 64, 152, 62);
  p.cubicTo(138, 58, 118, 56, 110, 56);
  p.lineTo(90, 56);
  p.cubicTo(82, 56, 62, 58, 48, 62);
  p.close();

  // ── Left upper arm ──
  p.moveTo(26, 72);
  p.cubicTo(18, 74, 14, 82, 14, 92);
  p.lineTo(14, 156);
  p.cubicTo(14, 162, 18, 166, 24, 166);
  p.lineTo(42, 166);
  p.cubicTo(46, 166, 48, 162, 48, 156);
  p.lineTo(48, 92);
  p.cubicTo(48, 82, 44, 74, 38, 72);
  p.close();

  // ── Left forearm ──
  p.moveTo(16, 168);
  p.cubicTo(12, 170, 8, 178, 8, 188);
  p.lineTo(6, 228);
  p.cubicTo(6, 234, 10, 238, 16, 238);
  p.lineTo(36, 238);
  p.cubicTo(40, 238, 44, 234, 44, 228);
  p.lineTo(42, 188);
  p.cubicTo(42, 178, 40, 170, 36, 168);
  p.close();

  // ── Left hand ──
  p.addOval(const Rect.fromLTWH(4, 238, 34, 18));

  // ── Right upper arm ──
  p.moveTo(162, 72);
  p.cubicTo(156, 74, 152, 82, 152, 92);
  p.lineTo(152, 156);
  p.cubicTo(152, 162, 154, 166, 158, 166);
  p.lineTo(176, 166);
  p.cubicTo(182, 166, 186, 162, 186, 156);
  p.lineTo(186, 92);
  p.cubicTo(186, 82, 182, 74, 174, 72);
  p.close();

  // ── Right forearm ──
  p.moveTo(156, 168);
  p.cubicTo(152, 170, 150, 178, 150, 188);
  p.lineTo(148, 228);
  p.cubicTo(148, 234, 152, 238, 158, 238);
  p.lineTo(178, 238);
  p.cubicTo(184, 238, 188, 234, 188, 228);
  p.lineTo(186, 188);
  p.cubicTo(186, 178, 182, 170, 178, 168);
  p.close();

  // ── Right hand ──
  p.addOval(const Rect.fromLTWH(152, 238, 34, 18));

  // ── Left thigh ──
  p.moveTo(58, 248);
  p.cubicTo(52, 250, 48, 260, 48, 270);
  p.lineTo(48, 345);
  p.cubicTo(48, 352, 52, 356, 58, 356);
  p.lineTo(88, 356);
  p.cubicTo(92, 356, 96, 352, 96, 345);
  p.lineTo(96, 270);
  p.cubicTo(96, 260, 94, 250, 88, 248);
  p.close();

  // ── Left lower leg ──
  p.moveTo(52, 360);
  p.cubicTo(48, 362, 46, 370, 46, 380);
  p.lineTo(46, 432);
  p.cubicTo(46, 438, 50, 442, 56, 442);
  p.lineTo(84, 442);
  p.cubicTo(88, 442, 92, 438, 92, 432);
  p.lineTo(92, 380);
  p.cubicTo(92, 370, 88, 362, 84, 360);
  p.close();

  // ── Left foot ──
  p.moveTo(42, 444);
  p.cubicTo(38, 444, 36, 448, 36, 452);
  p.lineTo(36, 460);
  p.cubicTo(36, 464, 40, 468, 46, 468);
  p.lineTo(92, 468);
  p.cubicTo(96, 468, 98, 464, 98, 460);
  p.lineTo(98, 456);
  p.cubicTo(98, 450, 94, 444, 88, 444);
  p.close();

  // ── Right thigh ──
  p.moveTo(104, 248);
  p.cubicTo(100, 250, 96, 260, 96, 270);
  p.lineTo(96, 345);
  p.cubicTo(96, 352, 100, 356, 106, 356);
  p.lineTo(136, 356);
  p.cubicTo(142, 356, 146, 352, 146, 345);
  p.lineTo(146, 270);
  p.cubicTo(146, 260, 142, 250, 136, 248);
  p.close();

  // ── Right lower leg ──
  p.moveTo(108, 360);
  p.cubicTo(104, 362, 102, 370, 102, 380);
  p.lineTo(102, 432);
  p.cubicTo(102, 438, 106, 442, 112, 442);
  p.lineTo(140, 442);
  p.cubicTo(146, 442, 150, 438, 150, 432);
  p.lineTo(150, 380);
  p.cubicTo(150, 370, 146, 362, 142, 360);
  p.close();

  // ── Right foot ──
  p.moveTo(100, 444);
  p.cubicTo(96, 444, 94, 448, 94, 452);
  p.lineTo(94, 460);
  p.cubicTo(94, 464, 98, 468, 104, 468);
  p.lineTo(150, 468);
  p.cubicTo(156, 468, 160, 464, 160, 460);
  p.lineTo(160, 456);
  p.cubicTo(160, 450, 156, 444, 150, 444);
  p.close();

  return p;
}

Path buildBackSilhouette() {
  // Back silhouette is nearly identical to front with minor contour differences
  // (scapulae ridges, slightly different hip shape). We reuse the front shape
  // for now and add scapulae detail.
  final p = buildFrontSilhouette();

  // Add scapulae ridges (back-specific detail)
  final scapula = Path();
  // Left scapula
  scapula.moveTo(52, 82);
  scapula.cubicTo(48, 90, 48, 105, 52, 115);
  scapula.cubicTo(58, 120, 72, 118, 78, 110);
  scapula.cubicTo(82, 102, 78, 88, 72, 82);
  scapula.cubicTo(66, 78, 56, 78, 52, 82);
  scapula.close();
  // Right scapula
  scapula.moveTo(148, 82);
  scapula.cubicTo(152, 90, 152, 105, 148, 115);
  scapula.cubicTo(142, 120, 128, 118, 122, 110);
  scapula.cubicTo(118, 102, 122, 88, 128, 82);
  scapula.cubicTo(134, 78, 144, 78, 148, 82);
  scapula.close();

  p.addPath(scapula, Offset.zero);
  return p;
}

// ═════════════════════════════════════════════════════════════════════════════
// FRONT VIEW — SUB-MUSCLE PATHS
// ═════════════════════════════════════════════════════════════════════════════

// ── Neck — Sternocleidomastoid ──────────────────────────────────────────────

const _neckSCMLeft = SubMusclePath(
  subId: 'scm_left',
  label: 'Sternocleidomastoid',
  parentGroupId: 'neck',
  side: MuscleSide.front,
  shadeOffset: -0.05,
  labelAnchor: Offset(90, 52),
  labelPosition: Offset(12, 48),
  commands: [
    MoveToCmd(92, 46),
    CubicToCmd(90, 48, 88, 52, 88, 56),
    LineToCmd(90, 60),
    CubicToCmd(92, 60, 94, 58, 96, 56),
    LineToCmd(98, 50),
    CubicToCmd(96, 48, 94, 46, 92, 46),
    CloseCmd(),
  ],
);

final _neckSCMRight = _mirror(_neckSCMLeft, 'scm_right');

const _neckOmohyoid = SubMusclePath(
  subId: 'omohyoid',
  label: 'Omohyoid',
  parentGroupId: 'neck',
  side: MuscleSide.front,
  shadeOffset: 0.08,
  labelAnchor: Offset(100, 50),
  labelPosition: Offset(12, 40),
  commands: [
    MoveToCmd(95, 44),
    CubicToCmd(93, 46, 92, 48, 92, 50),
    LineToCmd(108, 50),
    CubicToCmd(108, 48, 107, 46, 105, 44),
    CloseCmd(),
  ],
);

// ── Shoulders — Deltoids ────────────────────────────────────────────────────

const _anteriorDeltLeft = SubMusclePath(
  subId: 'anterior_delt_left',
  label: 'Anterior Deltoid',
  parentGroupId: 'shoulders_front',
  side: MuscleSide.front,
  shadeOffset: 0.0,
  labelAnchor: Offset(38, 72),
  labelPosition: Offset(4, 70),
  commands: [
    MoveToCmd(48, 62),
    CubicToCmd(40, 64, 34, 68, 30, 74),
    CubicToCmd(28, 80, 26, 86, 26, 92),
    LineToCmd(36, 92),
    CubicToCmd(36, 86, 38, 78, 42, 72),
    CubicToCmd(46, 66, 50, 64, 56, 62),
    CloseCmd(),
  ],
);

final _anteriorDeltRight = _mirror(_anteriorDeltLeft, 'anterior_delt_right');

const _middleDeltLeft = SubMusclePath(
  subId: 'middle_delt_left',
  label: 'Middle Deltoid',
  parentGroupId: 'shoulders_front',
  side: MuscleSide.front,
  shadeOffset: 0.10,
  labelAnchor: Offset(30, 82),
  labelPosition: Offset(4, 82),
  commands: [
    MoveToCmd(26, 92),
    CubicToCmd(24, 86, 22, 78, 24, 72),
    CubicToCmd(26, 66, 30, 62, 36, 60),
    LineToCmd(48, 62),
    CubicToCmd(42, 64, 38, 68, 34, 74),
    CubicToCmd(30, 82, 28, 88, 26, 92),
    CloseCmd(),
  ],
);

final _middleDeltRight = _mirror(_middleDeltLeft, 'middle_delt_right');

// ── Chest — Pectoralis ──────────────────────────────────────────────────────

const _pecMajorLeft = SubMusclePath(
  subId: 'pec_major_left',
  label: 'Pectoralis Major',
  parentGroupId: 'chest',
  side: MuscleSide.front,
  shadeOffset: 0.0,
  labelAnchor: Offset(72, 92),
  labelPosition: Offset(186, 78),
  commands: [
    MoveToCmd(56, 68),
    CubicToCmd(52, 72, 48, 80, 48, 90),
    CubicToCmd(48, 100, 52, 108, 60, 114),
    CubicToCmd(68, 120, 82, 118, 92, 114),
    CubicToCmd(96, 112, 98, 106, 98, 98),
    LineToCmd(98, 78),
    CubicToCmd(94, 72, 86, 68, 76, 66),
    CubicToCmd(68, 64, 60, 66, 56, 68),
    CloseCmd(),
  ],
);

final _pecMajorRight = _mirror(_pecMajorLeft, 'pec_major_right');

const _pecMinorLeft = SubMusclePath(
  subId: 'pec_minor_left',
  label: 'Pectoralis Minor',
  parentGroupId: 'chest',
  side: MuscleSide.front,
  shadeOffset: -0.10,
  labelAnchor: Offset(66, 104),
  labelPosition: Offset(186, 92),
  commands: [
    MoveToCmd(58, 96),
    CubicToCmd(54, 100, 54, 108, 60, 114),
    CubicToCmd(66, 118, 78, 118, 88, 116),
    CubicToCmd(92, 114, 94, 110, 94, 104),
    CubicToCmd(94, 100, 90, 96, 84, 94),
    CubicToCmd(76, 92, 66, 92, 58, 96),
    CloseCmd(),
  ],
);

final _pecMinorRight = _mirror(_pecMinorLeft, 'pec_minor_right');

// ── Biceps ──────────────────────────────────────────────────────────────────

const _bicepLongLeft = SubMusclePath(
  subId: 'bicep_long_left',
  label: 'Biceps Long Head',
  parentGroupId: 'biceps',
  side: MuscleSide.front,
  shadeOffset: 0.0,
  labelAnchor: Offset(28, 110),
  labelPosition: Offset(4, 108),
  commands: [
    MoveToCmd(22, 94),
    CubicToCmd(18, 98, 16, 106, 16, 118),
    CubicToCmd(16, 132, 18, 146, 20, 156),
    LineToCmd(30, 156),
    CubicToCmd(30, 146, 30, 132, 32, 118),
    CubicToCmd(34, 106, 32, 98, 28, 94),
    CloseCmd(),
  ],
);

final _bicepLongRight = _mirror(_bicepLongLeft, 'bicep_long_right');

const _bicepShortLeft = SubMusclePath(
  subId: 'bicep_short_left',
  label: 'Biceps Short Head',
  parentGroupId: 'biceps',
  side: MuscleSide.front,
  shadeOffset: 0.08,
  labelAnchor: Offset(36, 118),
  labelPosition: Offset(4, 120),
  commands: [
    MoveToCmd(30, 94),
    CubicToCmd(34, 98, 38, 106, 40, 118),
    CubicToCmd(42, 132, 42, 146, 40, 156),
    LineToCmd(30, 156),
    CubicToCmd(30, 146, 30, 132, 32, 118),
    CubicToCmd(34, 106, 34, 98, 30, 94),
    CloseCmd(),
  ],
);

final _bicepShortRight = _mirror(_bicepShortLeft, 'bicep_short_right');

const _brachialisLeft = SubMusclePath(
  subId: 'brachialis_left',
  label: 'Brachialis',
  parentGroupId: 'biceps',
  side: MuscleSide.front,
  shadeOffset: -0.08,
  labelAnchor: Offset(40, 145),
  labelPosition: Offset(4, 144),
  commands: [
    MoveToCmd(16, 148),
    CubicToCmd(16, 154, 18, 160, 22, 164),
    LineToCmd(40, 164),
    CubicToCmd(44, 160, 46, 154, 46, 148),
    CubicToCmd(46, 142, 42, 140, 36, 140),
    CubicToCmd(28, 140, 18, 142, 16, 148),
    CloseCmd(),
  ],
);

final _brachialisRight = _mirror(_brachialisLeft, 'brachialis_right');

// ── Forearms ────────────────────────────────────────────────────────────────

const _brachioradialisLeft = SubMusclePath(
  subId: 'brachioradialis_left',
  label: 'Brachioradialis',
  parentGroupId: 'forearms',
  side: MuscleSide.front,
  shadeOffset: 0.0,
  labelAnchor: Offset(22, 190),
  labelPosition: Offset(186, 178),
  commands: [
    MoveToCmd(18, 168),
    CubicToCmd(14, 172, 12, 182, 10, 196),
    CubicToCmd(8, 210, 8, 222, 10, 232),
    LineToCmd(24, 232),
    CubicToCmd(24, 222, 26, 210, 28, 196),
    CubicToCmd(30, 182, 28, 172, 24, 168),
    CloseCmd(),
  ],
);

final _brachioradialisRight = _mirror(_brachioradialisLeft, 'brachioradialis_right');

const _flexorGroupLeft = SubMusclePath(
  subId: 'flexor_group_left',
  label: 'Flexor Carpi',
  parentGroupId: 'forearms',
  side: MuscleSide.front,
  shadeOffset: -0.08,
  labelAnchor: Offset(34, 196),
  labelPosition: Offset(186, 194),
  commands: [
    MoveToCmd(26, 168),
    CubicToCmd(30, 172, 34, 182, 36, 196),
    CubicToCmd(38, 210, 38, 222, 36, 232),
    LineToCmd(24, 232),
    CubicToCmd(24, 222, 26, 210, 28, 196),
    CubicToCmd(30, 182, 28, 172, 26, 168),
    CloseCmd(),
  ],
);

final _flexorGroupRight = _mirror(_flexorGroupLeft, 'flexor_group_right');

// ── Abs ─────────────────────────────────────────────────────────────────────

const _rectusAbdominis = SubMusclePath(
  subId: 'rectus_abdominis',
  label: 'Rectus Abdominis',
  parentGroupId: 'abs',
  side: MuscleSide.front,
  shadeOffset: 0.0,
  labelAnchor: Offset(100, 168),
  labelPosition: Offset(186, 148),
  commands: [
    MoveToCmd(86, 118),
    CubicToCmd(84, 122, 82, 132, 82, 148),
    CubicToCmd(82, 168, 82, 192, 82, 210),
    CubicToCmd(82, 218, 86, 224, 92, 228),
    LineToCmd(108, 228),
    CubicToCmd(114, 224, 118, 218, 118, 210),
    CubicToCmd(118, 192, 118, 168, 118, 148),
    CubicToCmd(118, 132, 116, 122, 114, 118),
    CloseCmd(),
  ],
);

const _externalObliqueLeft = SubMusclePath(
  subId: 'external_oblique_left',
  label: 'External Oblique',
  parentGroupId: 'abs',
  side: MuscleSide.front,
  shadeOffset: -0.10,
  labelAnchor: Offset(62, 170),
  labelPosition: Offset(4, 168),
  commands: [
    MoveToCmd(50, 120),
    CubicToCmd(48, 130, 46, 150, 46, 170),
    CubicToCmd(46, 190, 48, 210, 52, 222),
    CubicToCmd(56, 228, 64, 232, 76, 234),
    LineToCmd(82, 228),
    CubicToCmd(82, 218, 82, 200, 82, 180),
    CubicToCmd(82, 160, 82, 140, 82, 120),
    CubicToCmd(76, 118, 66, 118, 56, 118),
    CubicToCmd(52, 118, 50, 118, 50, 120),
    CloseCmd(),
  ],
);

final _externalObliqueRight = _mirror(_externalObliqueLeft, 'external_oblique_right');

const _serratusAnteriorLeft = SubMusclePath(
  subId: 'serratus_anterior_left',
  label: 'Serratus Anterior',
  parentGroupId: 'abs',
  side: MuscleSide.front,
  shadeOffset: 0.10,
  labelAnchor: Offset(54, 130),
  labelPosition: Offset(4, 130),
  commands: [
    MoveToCmd(48, 110),
    CubicToCmd(46, 114, 44, 122, 44, 132),
    CubicToCmd(44, 140, 46, 146, 50, 148),
    LineToCmd(56, 148),
    CubicToCmd(60, 146, 62, 140, 62, 132),
    CubicToCmd(62, 122, 58, 114, 54, 110),
    CloseCmd(),
  ],
);

final _serratusAnteriorRight = _mirror(_serratusAnteriorLeft, 'serratus_anterior_right');

// ── Quads ───────────────────────────────────────────────────────────────────

const _rectusFemorisLeft = SubMusclePath(
  subId: 'rectus_femoris_left',
  label: 'Rectus Femoris',
  parentGroupId: 'quads',
  side: MuscleSide.front,
  shadeOffset: 0.0,
  labelAnchor: Offset(72, 290),
  labelPosition: Offset(4, 286),
  commands: [
    MoveToCmd(64, 252),
    CubicToCmd(60, 260, 58, 276, 58, 296),
    CubicToCmd(58, 316, 60, 332, 64, 342),
    CubicToCmd(66, 348, 70, 350, 76, 350),
    CubicToCmd(82, 350, 86, 348, 88, 342),
    CubicToCmd(92, 332, 94, 316, 94, 296),
    CubicToCmd(94, 276, 92, 260, 88, 252),
    CubicToCmd(84, 248, 76, 248, 68, 248),
    CubicToCmd(64, 248, 62, 250, 64, 252),
    CloseCmd(),
  ],
);

final _rectusFemorisRight = _mirror(_rectusFemorisLeft, 'rectus_femoris_right');

const _vastusLateralisLeft = SubMusclePath(
  subId: 'vastus_lateralis_left',
  label: 'Vastus Lateralis',
  parentGroupId: 'quads',
  side: MuscleSide.front,
  shadeOffset: 0.10,
  labelAnchor: Offset(52, 296),
  labelPosition: Offset(4, 298),
  commands: [
    MoveToCmd(48, 256),
    CubicToCmd(46, 266, 44, 282, 44, 300),
    CubicToCmd(44, 318, 46, 334, 50, 344),
    CubicToCmd(52, 348, 56, 350, 60, 350),
    LineToCmd(64, 342),
    CubicToCmd(60, 332, 58, 316, 58, 296),
    CubicToCmd(58, 276, 60, 260, 64, 252),
    CubicToCmd(58, 250, 52, 252, 48, 256),
    CloseCmd(),
  ],
);

final _vastusLateralisRight = _mirror(_vastusLateralisLeft, 'vastus_lateralis_right');

const _vastusMedialisLeft = SubMusclePath(
  subId: 'vastus_medialis_left',
  label: 'Vastus Medialis',
  parentGroupId: 'quads',
  side: MuscleSide.front,
  shadeOffset: -0.06,
  labelAnchor: Offset(88, 320),
  labelPosition: Offset(4, 324),
  commands: [
    MoveToCmd(88, 252),
    CubicToCmd(92, 260, 94, 276, 96, 296),
    CubicToCmd(96, 316, 96, 332, 94, 342),
    CubicToCmd(92, 348, 88, 350, 84, 350),
    LineToCmd(76, 350),
    CubicToCmd(80, 348, 86, 342, 88, 332),
    CubicToCmd(92, 316, 94, 296, 94, 276),
    CubicToCmd(94, 260, 92, 252, 88, 252),
    CloseCmd(),
  ],
);

final _vastusMedialisRight = _mirror(_vastusMedialisLeft, 'vastus_medialis_right');

const _sartoriusLeft = SubMusclePath(
  subId: 'sartorius_left',
  label: 'Sartorius',
  parentGroupId: 'quads',
  side: MuscleSide.front,
  shadeOffset: -0.12,
  labelAnchor: Offset(80, 270),
  labelPosition: Offset(4, 266),
  commands: [
    MoveToCmd(62, 248),
    CubicToCmd(58, 252, 56, 258, 56, 266),
    LineToCmd(60, 266),
    CubicToCmd(62, 258, 66, 252, 72, 248),
    CloseCmd(),
  ],
);

final _sartoriusRight = _mirror(_sartoriusLeft, 'sartorius_right');

// ── Calves (Front) ──────────────────────────────────────────────────────────

const _tibialisAnteriorLeft = SubMusclePath(
  subId: 'tibialis_anterior_left',
  label: 'Tibialis Anterior',
  parentGroupId: 'calves',
  side: MuscleSide.front,
  shadeOffset: 0.0,
  labelAnchor: Offset(62, 390),
  labelPosition: Offset(4, 388),
  commands: [
    MoveToCmd(56, 362),
    CubicToCmd(52, 368, 50, 380, 50, 396),
    CubicToCmd(50, 412, 52, 426, 56, 436),
    LineToCmd(68, 436),
    CubicToCmd(68, 426, 66, 412, 66, 396),
    CubicToCmd(66, 380, 64, 368, 62, 362),
    CloseCmd(),
  ],
);

final _tibialisAnteriorRight = _mirror(_tibialisAnteriorLeft, 'tibialis_anterior_right');

const _gastrocFrontLeft = SubMusclePath(
  subId: 'gastroc_front_left',
  label: 'Gastrocnemius',
  parentGroupId: 'calves',
  side: MuscleSide.front,
  shadeOffset: -0.08,
  labelAnchor: Offset(78, 386),
  labelPosition: Offset(4, 402),
  commands: [
    MoveToCmd(68, 362),
    CubicToCmd(72, 368, 78, 376, 82, 388),
    CubicToCmd(86, 400, 88, 412, 88, 424),
    CubicToCmd(88, 432, 86, 436, 82, 438),
    LineToCmd(68, 436),
    CubicToCmd(68, 426, 66, 412, 66, 396),
    CubicToCmd(66, 380, 64, 368, 62, 362),
    CubicToCmd(64, 362, 66, 362, 68, 362),
    CloseCmd(),
  ],
);

final _gastrocFrontRight = _mirror(_gastrocFrontLeft, 'gastroc_front_right');

// ═════════════════════════════════════════════════════════════════════════════
// BACK VIEW — SUB-MUSCLE PATHS
// ═════════════════════════════════════════════════════════════════════════════

// ── Trapezius ───────────────────────────────────────────────────────────────

const _upperTrap = SubMusclePath(
  subId: 'upper_trap',
  label: 'Upper Trapezius',
  parentGroupId: 'traps',
  side: MuscleSide.back,
  shadeOffset: 0.0,
  labelAnchor: Offset(100, 64),
  labelPosition: Offset(186, 56),
  commands: [
    MoveToCmd(72, 56),
    CubicToCmd(66, 58, 58, 62, 52, 68),
    CubicToCmd(48, 72, 46, 76, 48, 80),
    LineToCmd(92, 66),
    LineToCmd(108, 66),
    LineToCmd(152, 80),
    CubicToCmd(154, 76, 152, 72, 148, 68),
    CubicToCmd(142, 62, 134, 58, 128, 56),
    CloseCmd(),
  ],
);

const _midTrapLeft = SubMusclePath(
  subId: 'mid_trap_left',
  label: 'Mid Trapezius',
  parentGroupId: 'traps',
  side: MuscleSide.back,
  shadeOffset: -0.08,
  labelAnchor: Offset(74, 86),
  labelPosition: Offset(4, 86),
  commands: [
    MoveToCmd(48, 80),
    CubicToCmd(46, 86, 46, 94, 50, 102),
    CubicToCmd(54, 108, 64, 110, 78, 108),
    LineToCmd(92, 104),
    LineToCmd(92, 66),
    CloseCmd(),
  ],
);

final _midTrapRight = _mirror(_midTrapLeft, 'mid_trap_right');

const _lowerTrap = SubMusclePath(
  subId: 'lower_trap',
  label: 'Lower Trapezius',
  parentGroupId: 'traps',
  side: MuscleSide.back,
  shadeOffset: 0.08,
  labelAnchor: Offset(100, 118),
  labelPosition: Offset(186, 110),
  commands: [
    MoveToCmd(78, 108),
    CubicToCmd(84, 112, 90, 118, 96, 128),
    LineToCmd(100, 128),
    CubicToCmd(106, 118, 112, 112, 118, 108),
    LineToCmd(108, 104),
    LineToCmd(92, 104),
    CloseCmd(),
  ],
);

// ── Lats ────────────────────────────────────────────────────────────────────

const _latLeft = SubMusclePath(
  subId: 'lat_left',
  label: 'Latissimus Dorsi',
  parentGroupId: 'lats',
  side: MuscleSide.back,
  shadeOffset: 0.0,
  labelAnchor: Offset(60, 148),
  labelPosition: Offset(4, 146),
  commands: [
    MoveToCmd(50, 102),
    CubicToCmd(48, 112, 44, 128, 42, 148),
    CubicToCmd(40, 168, 42, 188, 48, 200),
    CubicToCmd(52, 208, 60, 212, 72, 210),
    CubicToCmd(80, 208, 86, 200, 88, 188),
    CubicToCmd(90, 176, 90, 158, 90, 140),
    CubicToCmd(90, 128, 88, 116, 84, 108),
    CubicToCmd(78, 104, 66, 102, 50, 102),
    CloseCmd(),
  ],
);

final _latRight = _mirror(_latLeft, 'lat_right');

const _teresMajorLeft = SubMusclePath(
  subId: 'teres_major_left',
  label: 'Teres Major',
  parentGroupId: 'lats',
  side: MuscleSide.back,
  shadeOffset: -0.10,
  labelAnchor: Offset(46, 102),
  labelPosition: Offset(4, 98),
  commands: [
    MoveToCmd(42, 88),
    CubicToCmd(38, 92, 36, 98, 36, 106),
    CubicToCmd(36, 112, 38, 116, 44, 118),
    LineToCmd(56, 118),
    CubicToCmd(58, 114, 56, 106, 52, 98),
    CubicToCmd(50, 92, 46, 88, 42, 88),
    CloseCmd(),
  ],
);

final _teresMajorRight = _mirror(_teresMajorLeft, 'teres_major_right');

const _infraspinatusLeft = SubMusclePath(
  subId: 'infraspinatus_left',
  label: 'Infraspinatus',
  parentGroupId: 'lats',
  side: MuscleSide.back,
  shadeOffset: 0.10,
  labelAnchor: Offset(60, 92),
  labelPosition: Offset(4, 72),
  commands: [
    MoveToCmd(52, 78),
    CubicToCmd(48, 82, 44, 88, 42, 94),
    CubicToCmd(40, 100, 42, 104, 50, 102),
    LineToCmd(78, 102),
    CubicToCmd(82, 100, 80, 94, 76, 88),
    CubicToCmd(72, 82, 66, 78, 58, 76),
    CubicToCmd(56, 76, 54, 76, 52, 78),
    CloseCmd(),
  ],
);

final _infraspinatusRight = _mirror(_infraspinatusLeft, 'infraspinatus_right');

// ── Triceps ─────────────────────────────────────────────────────────────────

const _tricepLongLeft = SubMusclePath(
  subId: 'tricep_long_left',
  label: 'Triceps Long Head',
  parentGroupId: 'triceps',
  side: MuscleSide.back,
  shadeOffset: 0.0,
  labelAnchor: Offset(26, 120),
  labelPosition: Offset(4, 118),
  commands: [
    MoveToCmd(20, 92),
    CubicToCmd(16, 98, 14, 110, 14, 126),
    CubicToCmd(14, 142, 16, 154, 20, 162),
    LineToCmd(32, 162),
    CubicToCmd(32, 154, 34, 142, 36, 126),
    CubicToCmd(38, 110, 36, 98, 32, 92),
    CloseCmd(),
  ],
);

final _tricepLongRight = _mirror(_tricepLongLeft, 'tricep_long_right');

const _tricepLatLeft = SubMusclePath(
  subId: 'tricep_lateral_left',
  label: 'Triceps Lateral Head',
  parentGroupId: 'triceps',
  side: MuscleSide.back,
  shadeOffset: 0.10,
  labelAnchor: Offset(40, 128),
  labelPosition: Offset(4, 134),
  commands: [
    MoveToCmd(34, 92),
    CubicToCmd(38, 98, 42, 110, 44, 126),
    CubicToCmd(46, 142, 44, 154, 42, 162),
    LineToCmd(32, 162),
    CubicToCmd(32, 154, 34, 142, 36, 126),
    CubicToCmd(38, 110, 36, 98, 34, 92),
    CloseCmd(),
  ],
);

final _tricepLatRight = _mirror(_tricepLatLeft, 'tricep_lateral_right');

// ── Lower Back ──────────────────────────────────────────────────────────────

const _erectorSpinaeLeft = SubMusclePath(
  subId: 'erector_spinae_left',
  label: 'Erector Spinae',
  parentGroupId: 'lower_back',
  side: MuscleSide.back,
  shadeOffset: 0.0,
  labelAnchor: Offset(84, 188),
  labelPosition: Offset(186, 178),
  commands: [
    MoveToCmd(86, 150),
    CubicToCmd(84, 160, 82, 174, 80, 190),
    CubicToCmd(78, 206, 78, 218, 82, 226),
    LineToCmd(98, 226),
    CubicToCmd(98, 218, 98, 206, 98, 190),
    CubicToCmd(98, 174, 96, 160, 94, 150),
    CloseCmd(),
  ],
);

final _erectorSpinaeRight = _mirror(_erectorSpinaeLeft, 'erector_spinae_right');

const _thoracolumbarFascia = SubMusclePath(
  subId: 'thoracolumbar_fascia',
  label: 'Thoracolumbar Fascia',
  parentGroupId: 'lower_back',
  side: MuscleSide.back,
  shadeOffset: -0.10,
  labelAnchor: Offset(100, 216),
  labelPosition: Offset(186, 210),
  commands: [
    MoveToCmd(72, 210),
    CubicToCmd(68, 218, 66, 226, 68, 232),
    CubicToCmd(72, 238, 82, 240, 92, 240),
    LineToCmd(108, 240),
    CubicToCmd(118, 240, 128, 238, 132, 232),
    CubicToCmd(134, 226, 132, 218, 128, 210),
    CubicToCmd(120, 208, 108, 210, 100, 210),
    CubicToCmd(92, 210, 80, 208, 72, 210),
    CloseCmd(),
  ],
);

// ── Glutes ──────────────────────────────────────────────────────────────────

const _gluteMaxLeft = SubMusclePath(
  subId: 'glute_max_left',
  label: 'Gluteus Maximus',
  parentGroupId: 'glutes',
  side: MuscleSide.back,
  shadeOffset: 0.0,
  labelAnchor: Offset(70, 258),
  labelPosition: Offset(186, 250),
  commands: [
    MoveToCmd(52, 234),
    CubicToCmd(46, 242, 44, 254, 46, 268),
    CubicToCmd(48, 280, 54, 286, 64, 288),
    CubicToCmd(74, 290, 84, 286, 90, 278),
    CubicToCmd(94, 270, 96, 258, 96, 246),
    CubicToCmd(96, 238, 92, 234, 86, 234),
    CubicToCmd(76, 234, 64, 234, 52, 234),
    CloseCmd(),
  ],
);

final _gluteMaxRight = _mirror(_gluteMaxLeft, 'glute_max_right');

const _gluteMedLeft = SubMusclePath(
  subId: 'glute_med_left',
  label: 'Gluteus Medius',
  parentGroupId: 'glutes',
  side: MuscleSide.back,
  shadeOffset: -0.10,
  labelAnchor: Offset(58, 238),
  labelPosition: Offset(4, 238),
  commands: [
    MoveToCmd(48, 218),
    CubicToCmd(42, 224, 40, 232, 42, 240),
    CubicToCmd(44, 246, 50, 248, 58, 246),
    CubicToCmd(66, 244, 76, 240, 82, 234),
    CubicToCmd(86, 230, 86, 224, 82, 218),
    CubicToCmd(76, 216, 66, 216, 56, 216),
    CubicToCmd(52, 216, 50, 216, 48, 218),
    CloseCmd(),
  ],
);

final _gluteMedRight = _mirror(_gluteMedLeft, 'glute_med_right');

// ── Hamstrings ──────────────────────────────────────────────────────────────

const _bicepFemorisLeft = SubMusclePath(
  subId: 'bicep_femoris_left',
  label: 'Biceps Femoris',
  parentGroupId: 'hamstrings',
  side: MuscleSide.back,
  shadeOffset: 0.0,
  labelAnchor: Offset(56, 320),
  labelPosition: Offset(186, 300),
  commands: [
    MoveToCmd(48, 290),
    CubicToCmd(46, 300, 44, 316, 44, 334),
    CubicToCmd(44, 348, 48, 356, 54, 358),
    LineToCmd(68, 358),
    CubicToCmd(68, 348, 66, 334, 66, 316),
    CubicToCmd(66, 300, 64, 290, 60, 286),
    CubicToCmd(56, 286, 50, 288, 48, 290),
    CloseCmd(),
  ],
);

final _bicepFemorisRight = _mirror(_bicepFemorisLeft, 'bicep_femoris_right');

const _semitendinosusLeft = SubMusclePath(
  subId: 'semitendinosus_left',
  label: 'Semitendinosus',
  parentGroupId: 'hamstrings',
  side: MuscleSide.back,
  shadeOffset: -0.08,
  labelAnchor: Offset(78, 326),
  labelPosition: Offset(186, 320),
  commands: [
    MoveToCmd(68, 290),
    CubicToCmd(72, 298, 76, 312, 80, 328),
    CubicToCmd(84, 342, 86, 352, 86, 358),
    LineToCmd(68, 358),
    CubicToCmd(68, 348, 66, 334, 66, 316),
    CubicToCmd(66, 300, 66, 292, 68, 290),
    CloseCmd(),
  ],
);

final _semitendinosusRight = _mirror(_semitendinosusLeft, 'semitendinosus_right');

const _semimembranosusLeft = SubMusclePath(
  subId: 'semimembranosus_left',
  label: 'Semimembranosus',
  parentGroupId: 'hamstrings',
  side: MuscleSide.back,
  shadeOffset: 0.08,
  labelAnchor: Offset(86, 340),
  labelPosition: Offset(186, 340),
  commands: [
    MoveToCmd(80, 328),
    CubicToCmd(82, 336, 86, 344, 90, 350),
    CubicToCmd(92, 354, 94, 356, 94, 358),
    LineToCmd(86, 358),
    CubicToCmd(86, 354, 84, 346, 80, 336),
    CubicToCmd(78, 332, 78, 330, 80, 328),
    CloseCmd(),
  ],
);

final _semimembranosusRight = _mirror(_semimembranosusLeft, 'semimembranosus_right');

// ── Calves (Back) ───────────────────────────────────────────────────────────

const _gastrocBackLeft = SubMusclePath(
  subId: 'gastroc_back_left',
  label: 'Gastrocnemius',
  parentGroupId: 'calves',
  side: MuscleSide.back,
  shadeOffset: 0.0,
  labelAnchor: Offset(64, 386),
  labelPosition: Offset(4, 388),
  commands: [
    MoveToCmd(52, 362),
    CubicToCmd(48, 368, 46, 380, 46, 396),
    CubicToCmd(46, 410, 48, 422, 54, 430),
    CubicToCmd(58, 436, 64, 438, 72, 436),
    CubicToCmd(78, 434, 82, 428, 84, 420),
    CubicToCmd(86, 410, 88, 396, 88, 382),
    CubicToCmd(88, 372, 84, 364, 80, 362),
    CubicToCmd(72, 358, 60, 358, 52, 362),
    CloseCmd(),
  ],
);

final _gastrocBackRight = _mirror(_gastrocBackLeft, 'gastroc_back_right');

const _soleusLeft = SubMusclePath(
  subId: 'soleus_left',
  label: 'Soleus',
  parentGroupId: 'calves',
  side: MuscleSide.back,
  shadeOffset: -0.10,
  labelAnchor: Offset(68, 418),
  labelPosition: Offset(4, 420),
  commands: [
    MoveToCmd(56, 414),
    CubicToCmd(52, 420, 50, 428, 52, 436),
    CubicToCmd(54, 440, 58, 442, 66, 442),
    LineToCmd(82, 442),
    CubicToCmd(86, 442, 90, 440, 90, 436),
    CubicToCmd(92, 428, 90, 420, 86, 414),
    CubicToCmd(80, 410, 68, 410, 56, 414),
    CloseCmd(),
  ],
);

final _soleusRight = _mirror(_soleusLeft, 'soleus_right');

// ═════════════════════════════════════════════════════════════════════════════
// AGGREGATED PATH LISTS
// ═════════════════════════════════════════════════════════════════════════════

class AnatomyPathSet {
  AnatomyPathSet._();

  static List<SubMusclePath> get frontPaths => [
        // Neck
        _neckSCMLeft, _neckSCMRight, _neckOmohyoid,
        // Shoulders
        _anteriorDeltLeft, _anteriorDeltRight,
        _middleDeltLeft, _middleDeltRight,
        // Chest
        _pecMajorLeft, _pecMajorRight,
        _pecMinorLeft, _pecMinorRight,
        // Biceps
        _bicepLongLeft, _bicepLongRight,
        _bicepShortLeft, _bicepShortRight,
        _brachialisLeft, _brachialisRight,
        // Forearms
        _brachioradialisLeft, _brachioradialisRight,
        _flexorGroupLeft, _flexorGroupRight,
        // Abs
        _rectusAbdominis,
        _externalObliqueLeft, _externalObliqueRight,
        _serratusAnteriorLeft, _serratusAnteriorRight,
        // Quads
        _rectusFemorisLeft, _rectusFemorisRight,
        _vastusLateralisLeft, _vastusLateralisRight,
        _vastusMedialisLeft, _vastusMedialisRight,
        _sartoriusLeft, _sartoriusRight,
        // Calves
        _tibialisAnteriorLeft, _tibialisAnteriorRight,
        _gastrocFrontLeft, _gastrocFrontRight,
      ];

  static List<SubMusclePath> get backPaths => [
        // Traps
        _upperTrap, _midTrapLeft, _midTrapRight, _lowerTrap,
        // Lats
        _latLeft, _latRight,
        _teresMajorLeft, _teresMajorRight,
        _infraspinatusLeft, _infraspinatusRight,
        // Triceps
        _tricepLongLeft, _tricepLongRight,
        _tricepLatLeft, _tricepLatRight,
        // Lower Back
        _erectorSpinaeLeft, _erectorSpinaeRight,
        _thoracolumbarFascia,
        // Glutes
        _gluteMaxLeft, _gluteMaxRight,
        _gluteMedLeft, _gluteMedRight,
        // Hamstrings
        _bicepFemorisLeft, _bicepFemorisRight,
        _semitendinosusLeft, _semitendinosusRight,
        _semimembranosusLeft, _semimembranosusRight,
        // Calves (back)
        _gastrocBackLeft, _gastrocBackRight,
        _soleusLeft, _soleusRight,
      ];

  /// Get all sub-muscle paths for a given parent group on a given side.
  static List<SubMusclePath> getPathsForGroup(
      String parentGroupId, MuscleSide side) {
    final source = side == MuscleSide.front ? frontPaths : backPaths;
    return source
        .where((p) => p.parentGroupId == parentGroupId)
        .toList();
  }

  /// Build a combined hit-test Path for a parent group on a given side.
  static Path buildGroupPath(String parentGroupId, MuscleSide side) {
    final combined = Path();
    for (final sub in getPathsForGroup(parentGroupId, side)) {
      combined.addPath(sub.buildPath(), Offset.zero);
    }
    return combined;
  }

  // ─── Label layout data ────────────────────────────────────────────────────

  /// Unique labels for each parent group (for leader lines).
  /// Returns (label text, anchor on muscle, label position in margin).
  static List<({String groupId, String label, Offset anchor, Offset labelPos})>
      getGroupLabels(MuscleSide side) {
    if (side == MuscleSide.front) {
      return [
        (groupId: 'neck', label: 'Neck', anchor: const Offset(90, 52), labelPos: const Offset(14, 48)),
        (groupId: 'shoulders_front', label: 'Shoulders', anchor: const Offset(34, 76), labelPos: const Offset(4, 76)),
        (groupId: 'chest', label: 'Chest', anchor: const Offset(130, 90), labelPos: const Offset(186, 82)),
        (groupId: 'biceps', label: 'Biceps', anchor: const Offset(28, 118), labelPos: const Offset(4, 114)),
        (groupId: 'forearms', label: 'Forearms', anchor: const Offset(170, 196), labelPos: const Offset(186, 190)),
        (groupId: 'abs', label: 'Abs', anchor: const Offset(62, 168), labelPos: const Offset(4, 164)),
        (groupId: 'quads', label: 'Thighs', anchor: const Offset(72, 296), labelPos: const Offset(4, 292)),
        (groupId: 'calves', label: 'Calves', anchor: const Offset(142, 396), labelPos: const Offset(186, 392)),
      ];
    } else {
      return [
        (groupId: 'traps', label: 'Trapezius', anchor: const Offset(100, 68), labelPos: const Offset(186, 62)),
        (groupId: 'lats', label: 'Back', anchor: const Offset(58, 148), labelPos: const Offset(4, 144)),
        (groupId: 'triceps', label: 'Triceps', anchor: const Offset(172, 128), labelPos: const Offset(186, 124)),
        (groupId: 'lower_back', label: 'Lower Back', anchor: const Offset(100, 190), labelPos: const Offset(186, 186)),
        (groupId: 'glutes', label: 'Glutes', anchor: const Offset(60, 258), labelPos: const Offset(4, 254)),
        (groupId: 'hamstrings', label: 'Hamstrings', anchor: const Offset(142, 320), labelPos: const Offset(186, 316)),
        (groupId: 'calves', label: 'Calves', anchor: const Offset(64, 396), labelPos: const Offset(4, 392)),
      ];
    }
  }
}
