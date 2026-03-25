// lib/widgets/body_anatomy_painter.dart
//
// Full anatomical human body painter — gender-specific.
// Draws a detailed front or back view silhouette with every major muscle group
// individually filled (colour based on MuscleState), fiber-texture lines, and labels.
//
// All coordinates are NORMALISED (0.0 – 1.0) against the canvas size so the
// diagram scales to any container width/height.

import 'dart:math' as math;
import 'package:flutter/material.dart';

// ─── Muscle state ─────────────────────────────────────────────────────────────

enum MuscleState { untrained, recovery, moderate, active, intense }

Color muscleStateColor(MuscleState s, Color brand) {
  switch (s) {
    case MuscleState.untrained:
      return const Color(0xFF4A4A5A).withOpacity(0.30);
    case MuscleState.recovery:
      return const Color(0xFF4FC3F7).withOpacity(0.50);
    case MuscleState.moderate:
      return brand.withOpacity(0.40);
    case MuscleState.active:
      return brand.withOpacity(0.75);
    case MuscleState.intense:
      return brand;
  }
}

// ─── Muscle zone definition ───────────────────────────────────────────────────

class MuscleZone {
  final String id;
  final String label;
  final Path Function(Size) pathBuilder;
  final Offset Function(Size) labelAnchor;
  final double fiberAngleDeg; // fiber direction for texture (0 = horizontal)

  const MuscleZone({
    required this.id,
    required this.label,
    required this.pathBuilder,
    required this.labelAnchor,
    this.fiberAngleDeg = 80.0,
  });

  bool contains(Offset local, Size size) => pathBuilder(size).contains(local);
}

// ─── Path helpers ─────────────────────────────────────────────────────────────

Offset _s(double nx, double ny, Size sz) =>
    Offset(nx * sz.width, ny * sz.height);

/// Ellipse from normalised centre + half-radii.
Path _ellipse(double cx, double cy, double rx, double ry, Size s) {
  return Path()
    ..addOval(Rect.fromCenter(
      center: _s(cx, cy, s),
      width: rx * 2 * s.width,
      height: ry * 2 * s.height,
    ));
}

/// Straight-line polygon from normalised points.
Path _poly(List<List<double>> pts, Size s) {
  final path = Path();
  for (var i = 0; i < pts.length; i++) {
    final p = _s(pts[i][0], pts[i][1], s);
    if (i == 0) {
      path.moveTo(p.dx, p.dy);
    } else {
      path.lineTo(p.dx, p.dy);
    }
  }
  path.close();
  return path;
}

/// Smooth cubic-bezier path.
/// segs[0] = [startX, startY]
/// segs[1..n] = [cp1x, cp1y, cp2x, cp2y, endX, endY]  (cubicTo)
Path _bezier(List<List<double>> segs, Size s) {
  final p = Path();
  p.moveTo(segs[0][0] * s.width, segs[0][1] * s.height);
  for (var i = 1; i < segs.length; i++) {
    final seg = segs[i];
    p.cubicTo(
      seg[0] * s.width, seg[1] * s.height,
      seg[2] * s.width, seg[3] * s.height,
      seg[4] * s.width, seg[5] * s.height,
    );
  }
  p.close();
  return p;
}

// ─── FRONT VIEW muscle zones ─────────────────────────────────────────────────

List<MuscleZone> buildFrontZones(String gender) {
  final isFemale = gender == 'female';
  return [
    // ── Neck / Sternocleidomastoid ─────────────────────────────────────────
    MuscleZone(
      id: 'neck_left',
      label: 'SCM',
      pathBuilder: (s) => _ellipse(0.448, 0.172, 0.022, 0.028, s),
      labelAnchor: (s) => _s(0.390, 0.165, s),
      fiberAngleDeg: 70,
    ),
    MuscleZone(
      id: 'neck_right',
      label: 'SCM',
      pathBuilder: (s) => _ellipse(0.552, 0.172, 0.022, 0.028, s),
      labelAnchor: (s) => _s(0.600, 0.165, s),
      fiberAngleDeg: 110,
    ),

    // ── Shoulders (deltoids) ───────────────────────────────────────────────
    MuscleZone(
      id: 'delt_left',
      label: 'Deltoid',
      pathBuilder: (s) => _bezier([
        [0.292, 0.215],
        [0.262, 0.208, 0.228, 0.225, 0.228, 0.255],
        [0.228, 0.282, 0.260, 0.295, 0.300, 0.295],
        [0.340, 0.295, 0.352, 0.270, 0.352, 0.250],
        [0.352, 0.228, 0.325, 0.210, 0.292, 0.215],
      ], s),
      labelAnchor: (s) => _s(0.198, 0.242, s),
      fiberAngleDeg: 75,
    ),
    MuscleZone(
      id: 'delt_right',
      label: 'Deltoid',
      pathBuilder: (s) => _bezier([
        [0.708, 0.215],
        [0.738, 0.208, 0.772, 0.225, 0.772, 0.255],
        [0.772, 0.282, 0.740, 0.295, 0.700, 0.295],
        [0.660, 0.295, 0.648, 0.270, 0.648, 0.250],
        [0.648, 0.228, 0.675, 0.210, 0.708, 0.215],
      ], s),
      labelAnchor: (s) => _s(0.763, 0.242, s),
      fiberAngleDeg: 105,
    ),

    // ── Upper Chest ────────────────────────────────────────────────────────
    MuscleZone(
      id: 'pec_upper',
      label: 'Upper\nChest',
      pathBuilder: (s) => isFemale
          ? _bezier([
              [0.365, 0.252],
              [0.380, 0.240, 0.440, 0.235, 0.500, 0.238],
              [0.560, 0.235, 0.622, 0.240, 0.635, 0.252],
              [0.628, 0.292, 0.570, 0.305, 0.500, 0.308],
              [0.430, 0.305, 0.372, 0.292, 0.365, 0.252],
            ], s)
          : _bezier([
              [0.368, 0.250],
              [0.382, 0.238, 0.440, 0.233, 0.500, 0.236],
              [0.560, 0.233, 0.618, 0.238, 0.632, 0.250],
              [0.625, 0.293, 0.565, 0.307, 0.500, 0.310],
              [0.435, 0.307, 0.375, 0.293, 0.368, 0.250],
            ], s),
      labelAnchor: (s) => _s(0.500, 0.264, s),
      fiberAngleDeg: 5,
    ),

    // ── Lower Chest ────────────────────────────────────────────────────────
    MuscleZone(
      id: 'pec_lower',
      label: 'Lower\nChest',
      pathBuilder: (s) => isFemale
          ? _bezier([
              [0.372, 0.308],
              [0.435, 0.305, 0.500, 0.308, 0.500, 0.308],
              [0.500, 0.308, 0.565, 0.305, 0.628, 0.308],
              [0.620, 0.350, 0.568, 0.368, 0.500, 0.372],
              [0.432, 0.368, 0.380, 0.350, 0.372, 0.308],
            ], s)
          : _bezier([
              [0.375, 0.310],
              [0.435, 0.307, 0.500, 0.310, 0.500, 0.310],
              [0.500, 0.310, 0.565, 0.307, 0.625, 0.310],
              [0.618, 0.352, 0.565, 0.368, 0.500, 0.372],
              [0.435, 0.368, 0.382, 0.352, 0.375, 0.310],
            ], s),
      labelAnchor: (s) => _s(0.500, 0.335, s),
      fiberAngleDeg: 15,
    ),

    // ── Serratus Anterior ──────────────────────────────────────────────────
    MuscleZone(
      id: 'serratus_left',
      label: 'Serratus',
      pathBuilder: (s) => _bezier([
        [0.352, 0.328],
        [0.342, 0.330, 0.330, 0.338, 0.332, 0.352],
        [0.334, 0.366, 0.345, 0.372, 0.355, 0.368],
        [0.348, 0.382, 0.342, 0.390, 0.345, 0.402],
        [0.348, 0.412, 0.358, 0.418, 0.368, 0.410],
        [0.375, 0.400, 0.420, 0.392, 0.428, 0.372],
        [0.435, 0.352, 0.430, 0.330, 0.415, 0.324],
        [0.398, 0.318, 0.368, 0.320, 0.352, 0.328],
      ], s),
      labelAnchor: (s) => _s(0.298, 0.372, s),
      fiberAngleDeg: 30,
    ),
    MuscleZone(
      id: 'serratus_right',
      label: 'Serratus',
      pathBuilder: (s) => _bezier([
        [0.648, 0.328],
        [0.658, 0.320, 0.685, 0.318, 0.670, 0.324],
        [0.570, 0.330, 0.565, 0.352, 0.572, 0.372],
        [0.580, 0.392, 0.625, 0.400, 0.632, 0.410],
        [0.642, 0.418, 0.652, 0.412, 0.655, 0.402],
        [0.658, 0.390, 0.652, 0.382, 0.645, 0.368],
        [0.655, 0.372, 0.666, 0.366, 0.668, 0.352],
        [0.670, 0.338, 0.658, 0.330, 0.648, 0.328],
      ], s),
      labelAnchor: (s) => _s(0.668, 0.372, s),
      fiberAngleDeg: 150,
    ),

    // ── Biceps ────────────────────────────────────────────────────────────
    MuscleZone(
      id: 'bicep_left',
      label: 'Biceps',
      pathBuilder: (s) => _bezier([
        [0.255, 0.270],
        [0.240, 0.272, 0.212, 0.285, 0.210, 0.315],
        [0.208, 0.345, 0.215, 0.375, 0.225, 0.388],
        [0.235, 0.400, 0.258, 0.405, 0.272, 0.398],
        [0.288, 0.390, 0.298, 0.368, 0.296, 0.342],
        [0.294, 0.312, 0.282, 0.278, 0.265, 0.270],
        [0.258, 0.267, 0.255, 0.268, 0.255, 0.270],
      ], s),
      labelAnchor: (s) => _s(0.163, 0.330, s),
      fiberAngleDeg: 88,
    ),
    MuscleZone(
      id: 'bicep_right',
      label: 'Biceps',
      pathBuilder: (s) => _bezier([
        [0.745, 0.270],
        [0.718, 0.268, 0.704, 0.278, 0.702, 0.312],
        [0.700, 0.342, 0.706, 0.368, 0.722, 0.378],
        [0.730, 0.390, 0.745, 0.398, 0.762, 0.400],
        [0.778, 0.402, 0.796, 0.395, 0.800, 0.380],
        [0.804, 0.362, 0.800, 0.330, 0.792, 0.310],
        [0.786, 0.280, 0.762, 0.268, 0.745, 0.270],
      ], s),
      labelAnchor: (s) => _s(0.800, 0.330, s),
      fiberAngleDeg: 92,
    ),

    // ── Forearms ──────────────────────────────────────────────────────────
    MuscleZone(
      id: 'forearm_left',
      label: 'Forearm',
      pathBuilder: (s) => _bezier([
        [0.222, 0.400],
        [0.208, 0.402, 0.192, 0.415, 0.190, 0.438],
        [0.188, 0.462, 0.195, 0.490, 0.205, 0.500],
        [0.215, 0.510, 0.232, 0.512, 0.245, 0.504],
        [0.260, 0.495, 0.268, 0.472, 0.265, 0.448],
        [0.262, 0.422, 0.248, 0.402, 0.232, 0.398],
        [0.226, 0.397, 0.222, 0.399, 0.222, 0.400],
      ], s),
      labelAnchor: (s) => _s(0.142, 0.448, s),
      fiberAngleDeg: 85,
    ),
    MuscleZone(
      id: 'forearm_right',
      label: 'Forearm',
      pathBuilder: (s) => _bezier([
        [0.778, 0.400],
        [0.768, 0.397, 0.752, 0.402, 0.740, 0.420],
        [0.728, 0.440, 0.728, 0.468, 0.735, 0.490],
        [0.742, 0.508, 0.758, 0.516, 0.772, 0.508],
        [0.788, 0.498, 0.800, 0.476, 0.800, 0.450],
        [0.800, 0.425, 0.788, 0.405, 0.778, 0.400],
      ], s),
      labelAnchor: (s) => _s(0.820, 0.448, s),
      fiberAngleDeg: 95,
    ),

    // ── Abs (rectus abdominis) ─────────────────────────────────────────────
    MuscleZone(
      id: 'abs',
      label: 'Abs',
      pathBuilder: (s) => _bezier([
        [0.435, 0.350],
        [0.460, 0.345, 0.540, 0.345, 0.565, 0.350],
        [0.575, 0.358, 0.578, 0.380, 0.575, 0.420],
        [0.572, 0.460, 0.565, 0.490, 0.555, 0.498],
        [0.542, 0.505, 0.520, 0.508, 0.500, 0.508],
        [0.480, 0.508, 0.458, 0.505, 0.445, 0.498],
        [0.432, 0.490, 0.425, 0.462, 0.422, 0.422],
        [0.419, 0.382, 0.422, 0.358, 0.435, 0.350],
      ], s),
      labelAnchor: (s) => _s(0.500, 0.425, s),
      fiberAngleDeg: 90,
    ),

    // ── Obliques ──────────────────────────────────────────────────────────
    MuscleZone(
      id: 'oblique_left',
      label: 'Oblique',
      pathBuilder: (s) => _bezier([
        [0.370, 0.348],
        [0.380, 0.340, 0.418, 0.335, 0.435, 0.350],
        [0.422, 0.358, 0.419, 0.382, 0.420, 0.422],
        [0.421, 0.460, 0.428, 0.490, 0.435, 0.500],
        [0.425, 0.510, 0.402, 0.520, 0.375, 0.515],
        [0.350, 0.508, 0.338, 0.490, 0.340, 0.462],
        [0.342, 0.432, 0.352, 0.398, 0.365, 0.368],
        [0.370, 0.355, 0.370, 0.350, 0.370, 0.348],
      ], s),
      labelAnchor: (s) => _s(0.305, 0.425, s),
      fiberAngleDeg: 50,
    ),
    MuscleZone(
      id: 'oblique_right',
      label: 'Oblique',
      pathBuilder: (s) => _bezier([
        [0.630, 0.348],
        [0.630, 0.348, 0.630, 0.352, 0.635, 0.368],
        [0.648, 0.398, 0.658, 0.432, 0.660, 0.462],
        [0.662, 0.490, 0.650, 0.508, 0.625, 0.515],
        [0.598, 0.520, 0.575, 0.510, 0.565, 0.500],
        [0.572, 0.490, 0.579, 0.460, 0.580, 0.422],
        [0.581, 0.382, 0.578, 0.358, 0.565, 0.350],
        [0.582, 0.335, 0.618, 0.340, 0.630, 0.348],
      ], s),
      labelAnchor: (s) => _s(0.664, 0.425, s),
      fiberAngleDeg: 130,
    ),

    // ── Sartorius (diagonal strap) ─────────────────────────────────────────
    MuscleZone(
      id: 'sartorius_left',
      label: 'Sartorius',
      pathBuilder: (s) => _bezier([
        [0.420, 0.530],
        [0.428, 0.525, 0.440, 0.522, 0.448, 0.528],
        [0.456, 0.535, 0.455, 0.552, 0.450, 0.575],
        [0.442, 0.610, 0.428, 0.650, 0.412, 0.688],
        [0.400, 0.715, 0.388, 0.728, 0.378, 0.725],
        [0.368, 0.720, 0.362, 0.710, 0.365, 0.698],
        [0.370, 0.682, 0.382, 0.660, 0.392, 0.628],
        [0.404, 0.592, 0.414, 0.558, 0.416, 0.536],
        [0.417, 0.532, 0.418, 0.529, 0.420, 0.530],
      ], s),
      labelAnchor: (s) => _s(0.340, 0.625, s),
      fiberAngleDeg: 65,
    ),
    MuscleZone(
      id: 'sartorius_right',
      label: 'Sartorius',
      pathBuilder: (s) => _bezier([
        [0.580, 0.530],
        [0.582, 0.529, 0.583, 0.532, 0.584, 0.536],
        [0.586, 0.558, 0.596, 0.592, 0.608, 0.628],
        [0.618, 0.660, 0.630, 0.682, 0.635, 0.698],
        [0.638, 0.710, 0.632, 0.720, 0.622, 0.725],
        [0.612, 0.728, 0.600, 0.715, 0.588, 0.688],
        [0.572, 0.650, 0.558, 0.610, 0.550, 0.575],
        [0.545, 0.552, 0.544, 0.535, 0.552, 0.528],
        [0.560, 0.522, 0.572, 0.525, 0.580, 0.530],
      ], s),
      labelAnchor: (s) => _s(0.628, 0.625, s),
      fiberAngleDeg: 115,
    ),

    // ── Adductors (inner thigh) ────────────────────────────────────────────
    MuscleZone(
      id: 'adductor_left',
      label: 'Adductor',
      pathBuilder: (s) => _poly([
        [0.460, 0.548], [0.490, 0.544],
        [0.494, 0.620], [0.488, 0.700],
        [0.476, 0.715], [0.460, 0.708],
        [0.452, 0.640], [0.456, 0.580],
      ], s),
      labelAnchor: (s) => _s(0.420, 0.628, s),
      fiberAngleDeg: 88,
    ),
    MuscleZone(
      id: 'adductor_right',
      label: 'Adductor',
      pathBuilder: (s) => _poly([
        [0.510, 0.544], [0.540, 0.548],
        [0.544, 0.580], [0.548, 0.640],
        [0.540, 0.708], [0.524, 0.715],
        [0.512, 0.700], [0.506, 0.620],
      ], s),
      labelAnchor: (s) => _s(0.552, 0.628, s),
      fiberAngleDeg: 92,
    ),

    // ── Quads ─────────────────────────────────────────────────────────────
    MuscleZone(
      id: 'quad_left',
      label: 'Quads',
      pathBuilder: (s) => _bezier([
        [0.405, 0.532],
        [0.418, 0.524, 0.445, 0.520, 0.460, 0.528],
        [0.480, 0.538, 0.490, 0.555, 0.492, 0.585],
        [0.494, 0.625, 0.492, 0.670, 0.486, 0.700],
        [0.480, 0.720, 0.465, 0.728, 0.448, 0.722],
        [0.428, 0.715, 0.412, 0.698, 0.400, 0.672],
        [0.388, 0.642, 0.388, 0.602, 0.392, 0.568],
        [0.396, 0.548, 0.402, 0.535, 0.405, 0.532],
      ], s),
      labelAnchor: (s) => _s(0.360, 0.618, s),
      fiberAngleDeg: 88,
    ),
    MuscleZone(
      id: 'quad_right',
      label: 'Quads',
      pathBuilder: (s) => _bezier([
        [0.595, 0.532],
        [0.598, 0.535, 0.602, 0.548, 0.608, 0.568],
        [0.612, 0.602, 0.612, 0.642, 0.600, 0.672],
        [0.588, 0.698, 0.572, 0.715, 0.552, 0.722],
        [0.535, 0.728, 0.520, 0.720, 0.514, 0.700],
        [0.508, 0.670, 0.506, 0.625, 0.508, 0.585],
        [0.510, 0.555, 0.520, 0.538, 0.540, 0.528],
        [0.555, 0.520, 0.582, 0.524, 0.595, 0.532],
      ], s),
      labelAnchor: (s) => _s(0.612, 0.618, s),
      fiberAngleDeg: 92,
    ),

    // ── Tibialis Anterior / Front Calves ──────────────────────────────────
    MuscleZone(
      id: 'tibialis_left',
      label: 'Tibialis',
      pathBuilder: (s) => _bezier([
        [0.418, 0.745],
        [0.408, 0.748, 0.395, 0.760, 0.394, 0.778],
        [0.393, 0.800, 0.400, 0.820, 0.412, 0.830],
        [0.422, 0.840, 0.440, 0.842, 0.452, 0.835],
        [0.462, 0.825, 0.468, 0.805, 0.466, 0.782],
        [0.464, 0.760, 0.452, 0.744, 0.438, 0.742],
        [0.428, 0.740, 0.420, 0.742, 0.418, 0.745],
      ], s),
      labelAnchor: (s) => _s(0.352, 0.790, s),
      fiberAngleDeg: 88,
    ),
    MuscleZone(
      id: 'tibialis_right',
      label: 'Tibialis',
      pathBuilder: (s) => _bezier([
        [0.562, 0.742],
        [0.548, 0.740, 0.536, 0.744, 0.534, 0.760],
        [0.532, 0.782, 0.538, 0.805, 0.548, 0.825],
        [0.558, 0.842, 0.578, 0.845, 0.588, 0.835],
        [0.598, 0.825, 0.606, 0.805, 0.606, 0.782],
        [0.605, 0.760, 0.592, 0.748, 0.578, 0.745],
        [0.568, 0.742, 0.564, 0.741, 0.562, 0.742],
      ], s),
      labelAnchor: (s) => _s(0.614, 0.790, s),
      fiberAngleDeg: 92,
    ),

    // ── Soleus (front/lower shin) ──────────────────────────────────────────
    MuscleZone(
      id: 'soleus_front_left',
      label: 'Soleus',
      pathBuilder: (s) => _ellipse(0.432, 0.862, 0.030, 0.038, s),
      labelAnchor: (s) => _s(0.368, 0.862, s),
      fiberAngleDeg: 88,
    ),
    MuscleZone(
      id: 'soleus_front_right',
      label: 'Soleus',
      pathBuilder: (s) => _ellipse(0.568, 0.862, 0.030, 0.038, s),
      labelAnchor: (s) => _s(0.606, 0.862, s),
      fiberAngleDeg: 92,
    ),
  ];
}

// ─── BACK VIEW muscle zones ───────────────────────────────────────────────────

List<MuscleZone> buildBackZones(String gender) {
  final isFemale = gender == 'female';
  return [
    // ── Trapezius ──────────────────────────────────────────────────────────
    MuscleZone(
      id: 'trap',
      label: 'Trapezius',
      pathBuilder: (s) => _bezier([
        [0.440, 0.185],
        [0.458, 0.178, 0.480, 0.175, 0.500, 0.178],
        [0.520, 0.175, 0.542, 0.178, 0.560, 0.185],
        [0.592, 0.205, 0.625, 0.232, 0.628, 0.258],
        [0.630, 0.278, 0.610, 0.292, 0.575, 0.295],
        [0.548, 0.298, 0.525, 0.295, 0.500, 0.292],
        [0.475, 0.295, 0.452, 0.298, 0.425, 0.295],
        [0.390, 0.292, 0.368, 0.278, 0.370, 0.258],
        [0.372, 0.232, 0.405, 0.205, 0.440, 0.185],
      ], s),
      labelAnchor: (s) => _s(0.500, 0.232, s),
      fiberAngleDeg: 10,
    ),

    // ── Rear Deltoids ──────────────────────────────────────────────────────
    MuscleZone(
      id: 'rear_delt_left',
      label: 'Rear\nDelt',
      pathBuilder: (s) => _bezier([
        [0.300, 0.215],
        [0.278, 0.210, 0.248, 0.225, 0.245, 0.252],
        [0.242, 0.278, 0.260, 0.295, 0.298, 0.298],
        [0.338, 0.298, 0.355, 0.282, 0.355, 0.258],
        [0.355, 0.232, 0.330, 0.210, 0.300, 0.215],
      ], s),
      labelAnchor: (s) => _s(0.200, 0.242, s),
      fiberAngleDeg: 75,
    ),
    MuscleZone(
      id: 'rear_delt_right',
      label: 'Rear\nDelt',
      pathBuilder: (s) => _bezier([
        [0.700, 0.215],
        [0.670, 0.210, 0.645, 0.232, 0.645, 0.258],
        [0.645, 0.282, 0.662, 0.298, 0.702, 0.298],
        [0.740, 0.295, 0.758, 0.278, 0.755, 0.252],
        [0.752, 0.225, 0.722, 0.210, 0.700, 0.215],
      ], s),
      labelAnchor: (s) => _s(0.762, 0.242, s),
      fiberAngleDeg: 105,
    ),

    // ── Infraspinatus (shoulder blade) ────────────────────────────────────
    MuscleZone(
      id: 'infraspinatus_left',
      label: 'Infra-\nspinatus',
      pathBuilder: (s) => _bezier([
        [0.355, 0.272],
        [0.368, 0.265, 0.390, 0.262, 0.408, 0.268],
        [0.428, 0.275, 0.438, 0.290, 0.435, 0.312],
        [0.432, 0.335, 0.418, 0.352, 0.395, 0.355],
        [0.372, 0.358, 0.352, 0.345, 0.345, 0.325],
        [0.338, 0.305, 0.342, 0.282, 0.355, 0.272],
      ], s),
      labelAnchor: (s) => _s(0.268, 0.310, s),
      fiberAngleDeg: 15,
    ),
    MuscleZone(
      id: 'infraspinatus_right',
      label: 'Infra-\nspinatus',
      pathBuilder: (s) => _bezier([
        [0.645, 0.272],
        [0.658, 0.282, 0.662, 0.305, 0.655, 0.325],
        [0.648, 0.345, 0.628, 0.358, 0.605, 0.355],
        [0.582, 0.352, 0.568, 0.335, 0.565, 0.312],
        [0.562, 0.290, 0.572, 0.275, 0.592, 0.268],
        [0.610, 0.262, 0.632, 0.265, 0.645, 0.272],
      ], s),
      labelAnchor: (s) => _s(0.700, 0.310, s),
      fiberAngleDeg: 165,
    ),

    // ── Teres Major ────────────────────────────────────────────────────────
    MuscleZone(
      id: 'teres_left',
      label: 'Teres',
      pathBuilder: (s) => _ellipse(0.330, 0.348, 0.032, 0.050, s),
      labelAnchor: (s) => _s(0.255, 0.348, s),
      fiberAngleDeg: 40,
    ),
    MuscleZone(
      id: 'teres_right',
      label: 'Teres',
      pathBuilder: (s) => _ellipse(0.670, 0.348, 0.032, 0.050, s),
      labelAnchor: (s) => _s(0.710, 0.348, s),
      fiberAngleDeg: 140,
    ),

    // ── Rhomboids (centre upper back) ──────────────────────────────────────
    MuscleZone(
      id: 'rhomboid',
      label: 'Rhomboids',
      pathBuilder: (s) => _bezier([
        [0.500, 0.248],
        [0.522, 0.248, 0.548, 0.258, 0.562, 0.272],
        [0.572, 0.285, 0.572, 0.305, 0.562, 0.320],
        [0.550, 0.338, 0.528, 0.352, 0.500, 0.355],
        [0.472, 0.352, 0.450, 0.338, 0.438, 0.320],
        [0.428, 0.305, 0.428, 0.285, 0.438, 0.272],
        [0.452, 0.258, 0.478, 0.248, 0.500, 0.248],
      ], s),
      labelAnchor: (s) => _s(0.500, 0.300, s),
      fiberAngleDeg: 5,
    ),

    // ── Lats (latissimus dorsi) ────────────────────────────────────────────
    MuscleZone(
      id: 'lat_left',
      label: 'Lats',
      pathBuilder: (s) => _bezier([
        [0.355, 0.272],
        [0.342, 0.268, 0.322, 0.275, 0.315, 0.295],
        [0.308, 0.318, 0.315, 0.352, 0.328, 0.385],
        [0.338, 0.415, 0.345, 0.440, 0.345, 0.460],
        [0.345, 0.478, 0.358, 0.492, 0.375, 0.492],
        [0.395, 0.492, 0.420, 0.478, 0.435, 0.452],
        [0.448, 0.425, 0.450, 0.390, 0.445, 0.358],
        [0.440, 0.325, 0.432, 0.295, 0.418, 0.278],
        [0.405, 0.265, 0.378, 0.262, 0.355, 0.272],
      ], s),
      labelAnchor: (s) => _s(0.270, 0.375, s),
      fiberAngleDeg: 58,
    ),
    MuscleZone(
      id: 'lat_right',
      label: 'Lats',
      pathBuilder: (s) => _bezier([
        [0.645, 0.272],
        [0.622, 0.262, 0.595, 0.265, 0.582, 0.278],
        [0.568, 0.295, 0.560, 0.325, 0.555, 0.358],
        [0.550, 0.390, 0.552, 0.425, 0.565, 0.452],
        [0.580, 0.478, 0.605, 0.492, 0.625, 0.492],
        [0.642, 0.492, 0.655, 0.478, 0.655, 0.460],
        [0.655, 0.440, 0.662, 0.415, 0.672, 0.385],
        [0.685, 0.352, 0.692, 0.318, 0.685, 0.295],
        [0.678, 0.275, 0.658, 0.268, 0.645, 0.272],
      ], s),
      labelAnchor: (s) => _s(0.700, 0.375, s),
      fiberAngleDeg: 122,
    ),

    // ── Triceps ────────────────────────────────────────────────────────────
    MuscleZone(
      id: 'tricep_left',
      label: 'Triceps',
      pathBuilder: (s) => _bezier([
        [0.255, 0.272],
        [0.238, 0.272, 0.212, 0.285, 0.208, 0.315],
        [0.205, 0.345, 0.212, 0.375, 0.225, 0.392],
        [0.238, 0.408, 0.258, 0.412, 0.272, 0.402],
        [0.288, 0.392, 0.298, 0.368, 0.296, 0.338],
        [0.294, 0.308, 0.282, 0.278, 0.265, 0.272],
        [0.258, 0.268, 0.255, 0.270, 0.255, 0.272],
      ], s),
      labelAnchor: (s) => _s(0.160, 0.335, s),
      fiberAngleDeg: 88,
    ),
    MuscleZone(
      id: 'tricep_right',
      label: 'Triceps',
      pathBuilder: (s) => _bezier([
        [0.745, 0.272],
        [0.718, 0.270, 0.704, 0.278, 0.702, 0.308],
        [0.700, 0.338, 0.706, 0.368, 0.722, 0.378],
        [0.730, 0.392, 0.745, 0.402, 0.762, 0.402],
        [0.778, 0.408, 0.796, 0.398, 0.800, 0.382],
        [0.805, 0.362, 0.800, 0.330, 0.792, 0.308],
        [0.786, 0.278, 0.762, 0.268, 0.745, 0.272],
      ], s),
      labelAnchor: (s) => _s(0.802, 0.335, s),
      fiberAngleDeg: 92,
    ),

    // ── Lower Back (erector spinae) ────────────────────────────────────────
    MuscleZone(
      id: 'lower_back',
      label: 'Lower\nBack',
      pathBuilder: (s) => _bezier([
        [0.438, 0.418],
        [0.458, 0.410, 0.478, 0.408, 0.500, 0.410],
        [0.522, 0.408, 0.542, 0.410, 0.562, 0.418],
        [0.572, 0.428, 0.575, 0.448, 0.572, 0.468],
        [0.568, 0.490, 0.558, 0.505, 0.540, 0.508],
        [0.522, 0.512, 0.510, 0.515, 0.500, 0.515],
        [0.490, 0.515, 0.478, 0.512, 0.460, 0.508],
        [0.442, 0.505, 0.430, 0.490, 0.428, 0.468],
        [0.424, 0.448, 0.428, 0.428, 0.438, 0.418],
      ], s),
      labelAnchor: (s) => _s(0.500, 0.462, s),
      fiberAngleDeg: 88,
    ),

    // ── Gluteus Medius ─────────────────────────────────────────────────────
    MuscleZone(
      id: 'glute_med_left',
      label: 'Glute\nMed',
      pathBuilder: (s) => _ellipse(
        isFemale ? 0.388 : 0.398,
        0.528,
        isFemale ? 0.056 : 0.046,
        0.040,
        s,
      ),
      labelAnchor: (s) => _s(0.315, 0.528, s),
      fiberAngleDeg: 65,
    ),
    MuscleZone(
      id: 'glute_med_right',
      label: 'Glute\nMed',
      pathBuilder: (s) => _ellipse(
        isFemale ? 0.612 : 0.602,
        0.528,
        isFemale ? 0.056 : 0.046,
        0.040,
        s,
      ),
      labelAnchor: (s) => _s(0.660, 0.528, s),
      fiberAngleDeg: 115,
    ),

    // ── Glutes (gluteus maximus) ───────────────────────────────────────────
    MuscleZone(
      id: 'glute_left',
      label: 'Glutes',
      pathBuilder: (s) => _bezier([
        [0.368, 0.545],
        isFemale
            ? [0.348, 0.538, 0.322, 0.548, 0.318, 0.572]
            : [0.352, 0.538, 0.332, 0.548, 0.330, 0.568],
        isFemale
            ? [0.315, 0.598, 0.328, 0.625, 0.348, 0.635]
            : [0.328, 0.595, 0.338, 0.620, 0.355, 0.628],
        isFemale
            ? [0.368, 0.645, 0.398, 0.645, 0.415, 0.635]
            : [0.372, 0.635, 0.398, 0.632, 0.412, 0.620],
        isFemale
            ? [0.432, 0.625, 0.442, 0.608, 0.442, 0.590]
            : [0.425, 0.608, 0.432, 0.592, 0.432, 0.575],
        isFemale
            ? [0.442, 0.568, 0.428, 0.548, 0.408, 0.542]
            : [0.432, 0.555, 0.420, 0.542, 0.402, 0.538],
        [0.388, 0.535, 0.375, 0.532, 0.368, 0.545],
      ], s),
      labelAnchor: (s) => _s(0.318, 0.575, s),
      fiberAngleDeg: 45,
    ),
    MuscleZone(
      id: 'glute_right',
      label: 'Glutes',
      pathBuilder: (s) => _bezier([
        [0.632, 0.545],
        [0.625, 0.532, 0.612, 0.535, 0.598, 0.538],
        isFemale
            ? [0.558, 0.542, 0.548, 0.555, 0.548, 0.570]
            : [0.568, 0.542, 0.560, 0.552, 0.560, 0.568],
        isFemale
            ? [0.548, 0.592, 0.558, 0.612, 0.575, 0.628]
            : [0.560, 0.585, 0.568, 0.605, 0.582, 0.618],
        isFemale
            ? [0.592, 0.642, 0.618, 0.648, 0.638, 0.638]
            : [0.598, 0.628, 0.618, 0.635, 0.635, 0.625],
        isFemale
            ? [0.658, 0.628, 0.672, 0.602, 0.672, 0.575]
            : [0.652, 0.612, 0.662, 0.592, 0.660, 0.568],
        isFemale
            ? [0.672, 0.548, 0.658, 0.535, 0.638, 0.528]
            : [0.660, 0.545, 0.650, 0.535, 0.632, 0.528],
        [0.632, 0.528, 0.632, 0.540, 0.632, 0.545],
      ], s),
      labelAnchor: (s) => _s(0.655, 0.575, s),
      fiberAngleDeg: 135,
    ),

    // ── Hamstrings ─────────────────────────────────────────────────────────
    MuscleZone(
      id: 'ham_left',
      label: 'Hamstrings',
      pathBuilder: (s) => _bezier([
        [0.400, 0.638],
        [0.412, 0.630, 0.438, 0.626, 0.458, 0.632],
        [0.478, 0.638, 0.490, 0.658, 0.492, 0.688],
        [0.494, 0.720, 0.490, 0.752, 0.480, 0.768],
        [0.468, 0.780, 0.448, 0.778, 0.428, 0.765],
        [0.408, 0.750, 0.392, 0.722, 0.390, 0.692],
        [0.388, 0.660, 0.392, 0.645, 0.400, 0.638],
      ], s),
      labelAnchor: (s) => _s(0.340, 0.698, s),
      fiberAngleDeg: 88,
    ),
    MuscleZone(
      id: 'ham_right',
      label: 'Hamstrings',
      pathBuilder: (s) => _bezier([
        [0.600, 0.638],
        [0.608, 0.645, 0.612, 0.660, 0.610, 0.692],
        [0.608, 0.722, 0.592, 0.750, 0.572, 0.765],
        [0.552, 0.778, 0.532, 0.780, 0.520, 0.768],
        [0.510, 0.752, 0.506, 0.720, 0.508, 0.688],
        [0.510, 0.658, 0.522, 0.638, 0.542, 0.632],
        [0.562, 0.626, 0.588, 0.630, 0.600, 0.638],
      ], s),
      labelAnchor: (s) => _s(0.625, 0.698, s),
      fiberAngleDeg: 92,
    ),

    // ── Calves (gastrocnemius) ─────────────────────────────────────────────
    MuscleZone(
      id: 'calf_left',
      label: 'Calf',
      pathBuilder: (s) => _bezier([
        [0.405, 0.782],
        [0.395, 0.785, 0.382, 0.798, 0.380, 0.820],
        [0.378, 0.845, 0.388, 0.868, 0.402, 0.878],
        [0.415, 0.888, 0.435, 0.888, 0.448, 0.875],
        [0.460, 0.862, 0.465, 0.840, 0.462, 0.816],
        [0.459, 0.792, 0.448, 0.780, 0.432, 0.778],
        [0.418, 0.778, 0.408, 0.780, 0.405, 0.782],
      ], s),
      labelAnchor: (s) => _s(0.348, 0.830, s),
      fiberAngleDeg: 88,
    ),
    MuscleZone(
      id: 'calf_right',
      label: 'Calf',
      pathBuilder: (s) => _bezier([
        [0.595, 0.782],
        [0.592, 0.780, 0.582, 0.778, 0.568, 0.778],
        [0.552, 0.780, 0.541, 0.792, 0.538, 0.816],
        [0.535, 0.840, 0.540, 0.862, 0.552, 0.875],
        [0.565, 0.888, 0.585, 0.888, 0.598, 0.878],
        [0.612, 0.868, 0.622, 0.845, 0.620, 0.820],
        [0.618, 0.798, 0.605, 0.785, 0.595, 0.782],
      ], s),
      labelAnchor: (s) => _s(0.625, 0.830, s),
      fiberAngleDeg: 92,
    ),

    // ── Soleus (back / lower calf) ─────────────────────────────────────────
    MuscleZone(
      id: 'soleus_left',
      label: 'Soleus',
      pathBuilder: (s) => _ellipse(0.430, 0.888, 0.030, 0.030, s),
      labelAnchor: (s) => _s(0.365, 0.888, s),
      fiberAngleDeg: 88,
    ),
    MuscleZone(
      id: 'soleus_right',
      label: 'Soleus',
      pathBuilder: (s) => _ellipse(0.570, 0.888, 0.030, 0.030, s),
      labelAnchor: (s) => _s(0.608, 0.888, s),
      fiberAngleDeg: 92,
    ),
  ];
}

// ─── Painter ──────────────────────────────────────────────────────────────────

class BodyAnatomyPainter extends CustomPainter {
  final bool isFront;
  final String gender; // 'male' or 'female'
  final Map<String, MuscleState> muscleStates;
  final String? selectedId;
  final Color brand;
  final Color outline;
  final Color labelColor;

  const BodyAnatomyPainter({
    required this.isFront,
    required this.muscleStates,
    required this.brand,
    required this.outline,
    required this.labelColor,
    this.gender = 'male',
    this.selectedId,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawBodySilhouette(canvas, size);
    final zones = isFront ? buildFrontZones(gender) : buildBackZones(gender);
    for (final zone in zones) {
      _paintZone(canvas, size, zone);
    }
  }

  // ── Body silhouette ────────────────────────────────────────────────────────

  void _drawBodySilhouette(Canvas canvas, Size size) {
    final fillPaint = Paint()
      ..color = outline.withOpacity(0.10)
      ..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = outline.withOpacity(0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final path = _buildBodyOutline(size, gender);
    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, strokePaint);
  }

  Path _buildBodyOutline(Size s, String g) {
    final isFemale = g == 'female';
    final path = Path();

    // ── Head ──────────────────────────────────────────────────────────────
    path.addOval(Rect.fromCenter(
      center: _s(0.500, 0.078, s),
      width: 0.125 * s.width,
      height: 0.130 * s.height,
    ));

    // ── Neck ──────────────────────────────────────────────────────────────
    path.addRect(Rect.fromLTRB(
      0.464 * s.width, 0.138 * s.height,
      0.536 * s.width, 0.195 * s.height,
    ));

    // ── Torso (gender-specific) ────────────────────────────────────────────
    if (isFemale) {
      // Hourglass: bust → waist → hip
      path.addPath(
        _bezier([
          [0.330, 0.195],
          [0.330, 0.195, 0.310, 0.210, 0.312, 0.252],
          [0.315, 0.295, 0.338, 0.318, 0.352, 0.345],
          [0.362, 0.368, 0.360, 0.395, 0.352, 0.418],
          [0.344, 0.440, 0.336, 0.462, 0.335, 0.488],
          [0.334, 0.512, 0.340, 0.530, 0.352, 0.542],
          [0.648, 0.542, 0.660, 0.530, 0.665, 0.488],
          // right side in reverse for close
          [0.664, 0.462, 0.656, 0.440, 0.648, 0.418],
          [0.640, 0.395, 0.638, 0.368, 0.648, 0.345],
          [0.662, 0.318, 0.685, 0.295, 0.688, 0.252],
          [0.690, 0.210, 0.670, 0.195, 0.670, 0.195],
          [0.500, 0.195, 0.330, 0.195, 0.330, 0.195],
        ], s),
        Offset.zero,
      );
    } else {
      // Male: V-taper
      path.addRRect(RRect.fromRectAndCorners(
        Rect.fromLTRB(
          0.335 * s.width, 0.195 * s.height,
          0.665 * s.width, 0.532 * s.height,
        ),
        topLeft: const Radius.circular(12),
        topRight: const Radius.circular(12),
        bottomLeft: const Radius.circular(6),
        bottomRight: const Radius.circular(6),
      ));
    }

    // ── Hips / pelvis ──────────────────────────────────────────────────────
    path.addRRect(RRect.fromRectAndRadius(
      Rect.fromLTRB(
        (isFemale ? 0.330 : 0.355) * s.width, 0.518 * s.height,
        (isFemale ? 0.670 : 0.645) * s.width, 0.598 * s.height,
      ),
      const Radius.circular(8),
    ));

    // ── Left arm ──────────────────────────────────────────────────────────
    final lArmL = isFemale ? 0.218 : 0.204;
    final lArmR = isFemale ? 0.335 : 0.338;
    path.addRRect(RRect.fromRectAndRadius(
      Rect.fromLTRB(
        lArmL * s.width, 0.202 * s.height,
        lArmR * s.width, 0.400 * s.height,
      ),
      const Radius.circular(16),
    ));
    path.addRRect(RRect.fromRectAndRadius(
      Rect.fromLTRB(
        (lArmL + 0.002) * s.width, 0.390 * s.height,
        0.272 * s.width, 0.510 * s.height,
      ),
      const Radius.circular(14),
    ));
    path.addOval(Rect.fromCenter(
      center: _s(0.232, 0.538, s),
      width: 0.062 * s.width,
      height: 0.052 * s.height,
    ));

    // ── Right arm ─────────────────────────────────────────────────────────
    final rArmL = isFemale ? 0.665 : 0.662;
    final rArmR = isFemale ? 0.782 : 0.796;
    path.addRRect(RRect.fromRectAndRadius(
      Rect.fromLTRB(
        rArmL * s.width, 0.202 * s.height,
        rArmR * s.width, 0.400 * s.height,
      ),
      const Radius.circular(16),
    ));
    path.addRRect(RRect.fromRectAndRadius(
      Rect.fromLTRB(
        0.728 * s.width, 0.390 * s.height,
        (rArmR - 0.002) * s.width, 0.510 * s.height,
      ),
      const Radius.circular(14),
    ));
    path.addOval(Rect.fromCenter(
      center: _s(0.768, 0.538, s),
      width: 0.062 * s.width,
      height: 0.052 * s.height,
    ));

    // ── Left leg ──────────────────────────────────────────────────────────
    final lLegL = isFemale ? 0.358 : 0.365;
    final lLegR = isFemale ? 0.490 : 0.492;
    path.addRRect(RRect.fromRectAndRadius(
      Rect.fromLTRB(
        lLegL * s.width, 0.582 * s.height,
        lLegR * s.width, 0.768 * s.height,
      ),
      const Radius.circular(10),
    ));
    path.addRRect(RRect.fromRectAndRadius(
      Rect.fromLTRB(
        (lLegL + 0.010) * s.width, 0.758 * s.height,
        (lLegR - 0.008) * s.width, 0.900 * s.height,
      ),
      const Radius.circular(8),
    ));
    path.addRRect(RRect.fromRectAndRadius(
      Rect.fromLTRB(
        (lLegL - 0.005) * s.width, 0.890 * s.height,
        lLegR * s.width, 0.928 * s.height,
      ),
      const Radius.circular(6),
    ));

    // ── Right leg ─────────────────────────────────────────────────────────
    final rLegL = isFemale ? 0.510 : 0.508;
    final rLegR = isFemale ? 0.642 : 0.635;
    path.addRRect(RRect.fromRectAndRadius(
      Rect.fromLTRB(
        rLegL * s.width, 0.582 * s.height,
        rLegR * s.width, 0.768 * s.height,
      ),
      const Radius.circular(10),
    ));
    path.addRRect(RRect.fromRectAndRadius(
      Rect.fromLTRB(
        (rLegL + 0.008) * s.width, 0.758 * s.height,
        (rLegR - 0.010) * s.width, 0.900 * s.height,
      ),
      const Radius.circular(8),
    ));
    path.addRRect(RRect.fromRectAndRadius(
      Rect.fromLTRB(
        rLegL * s.width, 0.890 * s.height,
        (rLegR + 0.005) * s.width, 0.928 * s.height,
      ),
      const Radius.circular(6),
    ));

    return path;
  }

  // ── Zone painting ──────────────────────────────────────────────────────────

  void _paintZone(Canvas canvas, Size size, MuscleZone zone) {
    final state = muscleStates[zone.id] ?? MuscleState.untrained;
    final fillColor = muscleStateColor(state, brand);
    final isSelected = zone.id == selectedId;

    final zonePath = zone.pathBuilder(size);

    // 1. Fill
    canvas.drawPath(
      zonePath,
      Paint()
        ..color = fillColor
        ..style = PaintingStyle.fill,
    );

    // 2. Subtle fiber texture
    _drawFibers(canvas, zonePath, zone.fiberAngleDeg,
        fillColor.withOpacity(0.35), size);

    // 3. Border
    canvas.drawPath(
      zonePath,
      Paint()
        ..color = isSelected
            ? brand.withOpacity(0.92)
            : outline.withOpacity(0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? 2.0 : 0.9,
    );

    // 4. Glow ring if selected
    if (isSelected) {
      canvas.drawPath(
        zonePath,
        Paint()
          ..color = brand.withOpacity(0.32)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6.0
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );
    }

    // 5. Label
    _drawLabel(
        canvas, size, zone.label, zone.labelAnchor(size), isSelected, state);
  }

  // ── Fiber texture ──────────────────────────────────────────────────────────

  void _drawFibers(
    Canvas canvas,
    Path clipPath,
    double angleDeg,
    Color color,
    Size size,
  ) {
    final bounds = clipPath.getBounds();
    if (bounds.isEmpty) return;

    canvas.save();
    canvas.clipPath(clipPath);

    final paint = Paint()
      ..color = color
      ..strokeWidth = 0.6
      ..style = PaintingStyle.stroke;

    final angleRad = angleDeg * math.pi / 180.0;
    final spacing = size.width * 0.018; // ~6px on 330px wide canvas
    final diagonal =
        math.sqrt(bounds.width * bounds.width + bounds.height * bounds.height);
    final steps = (diagonal / spacing).ceil() + 2;
    final cx = bounds.center.dx;
    final cy = bounds.center.dy;
    final cos = math.cos(angleRad);
    final sin = math.sin(angleRad);

    for (var i = -steps; i <= steps; i++) {
      final d = i * spacing;
      final px = cx - sin * d;
      final py = cy + cos * d;
      final halfLen = diagonal;
      canvas.drawLine(
        Offset(px - cos * halfLen, py - sin * halfLen),
        Offset(px + cos * halfLen, py + sin * halfLen),
        paint,
      );
    }

    canvas.restore();
  }

  // ── Label rendering ────────────────────────────────────────────────────────

  void _drawLabel(
    Canvas canvas,
    Size size,
    String text,
    Offset anchor,
    bool isSelected,
    MuscleState state,
  ) {
    final fontSize = math.min(size.width, size.height) * 0.030;

    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: isSelected ? brand : labelColor.withOpacity(0.88),
          fontSize: fontSize,
          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
          height: 1.15,
          shadows: const [
            Shadow(
              color: Color(0xAA000000),
              blurRadius: 3,
            ),
          ],
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width * 0.18);

    tp.paint(
      canvas,
      Offset(anchor.dx - tp.width / 2, anchor.dy - tp.height / 2),
    );
  }

  @override
  bool shouldRepaint(BodyAnatomyPainter old) =>
      old.isFront != isFront ||
      old.gender != gender ||
      old.muscleStates != muscleStates ||
      old.selectedId != selectedId ||
      old.brand != brand;
}
