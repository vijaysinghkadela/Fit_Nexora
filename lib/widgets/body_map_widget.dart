// lib/widgets/body_map_widget.dart
//
// Interactive body map with front/back toggle and optional gender selector.
// Renders the full anatomical silhouette via BodyAnatomyPainter and handles
// muscle-tap hit-testing.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/extensions.dart';
import 'body_anatomy_painter.dart';

// ─── Data model ───────────────────────────────────────────────────────────────

class MuscleData {
  final MuscleState state;
  final double developmentPercent; // 0 – 100
  final double recoveryPercent; // 0 – 100 (100 = fully recovered)
  final double proteinScore; // 0 – 100
  final int trainingCountMonth;
  final String? lastTrained; // e.g. "2 days ago"

  const MuscleData({
    this.state = MuscleState.untrained,
    this.developmentPercent = 0,
    this.recoveryPercent = 100,
    this.proteinScore = 0,
    this.trainingCountMonth = 0,
    this.lastTrained,
  });
}

// ─── Muscle → display name ────────────────────────────────────────────────────

const kMuscleDisplayName = <String, String>{
  // Front
  'neck_left': 'Left Sternocleidomastoid',
  'neck_right': 'Right Sternocleidomastoid',
  'delt_left': 'Left Deltoid',
  'delt_right': 'Right Deltoid',
  'pec_upper': 'Upper Chest',
  'pec_lower': 'Lower Chest',
  'serratus_left': 'Left Serratus Anterior',
  'serratus_right': 'Right Serratus Anterior',
  'bicep_left': 'Left Biceps',
  'bicep_right': 'Right Biceps',
  'forearm_left': 'Left Forearm',
  'forearm_right': 'Right Forearm',
  'abs': 'Abs (Rectus Abdominis)',
  'oblique_left': 'Left Obliques',
  'oblique_right': 'Right Obliques',
  'sartorius_left': 'Left Sartorius',
  'sartorius_right': 'Right Sartorius',
  'adductor_left': 'Left Adductors',
  'adductor_right': 'Right Adductors',
  'quad_left': 'Left Quadriceps',
  'quad_right': 'Right Quadriceps',
  'tibialis_left': 'Left Tibialis Anterior',
  'tibialis_right': 'Right Tibialis Anterior',
  'soleus_front_left': 'Left Soleus',
  'soleus_front_right': 'Right Soleus',
  // Back
  'trap': 'Trapezius',
  'rear_delt_left': 'Left Rear Deltoid',
  'rear_delt_right': 'Right Rear Deltoid',
  'infraspinatus_left': 'Left Infraspinatus',
  'infraspinatus_right': 'Right Infraspinatus',
  'teres_left': 'Left Teres Major',
  'teres_right': 'Right Teres Major',
  'rhomboid': 'Rhomboids',
  'lat_left': 'Left Latissimus Dorsi',
  'lat_right': 'Right Latissimus Dorsi',
  'tricep_left': 'Left Triceps',
  'tricep_right': 'Right Triceps',
  'lower_back': 'Lower Back (Erectors)',
  'glute_med_left': 'Left Gluteus Medius',
  'glute_med_right': 'Right Gluteus Medius',
  'glute_left': 'Left Glutes',
  'glute_right': 'Right Glutes',
  'ham_left': 'Left Hamstrings',
  'ham_right': 'Right Hamstrings',
  'calf_left': 'Left Gastrocnemius',
  'calf_right': 'Right Gastrocnemius',
  'soleus_left': 'Left Soleus',
  'soleus_right': 'Right Soleus',
};

// ─── Muscle state badge ────────────────────────────────────────────────────────

const kMuscleStateLabel = <MuscleState, String>{
  MuscleState.untrained: 'Not Trained',
  MuscleState.recovery: 'Recovering',
  MuscleState.moderate: 'Moderate',
  MuscleState.active: 'Active Today',
  MuscleState.intense: 'Intense',
};

const kMuscleStateIcon = <MuscleState, IconData>{
  MuscleState.untrained: Icons.radio_button_unchecked,
  MuscleState.recovery: Icons.water_drop_rounded,
  MuscleState.moderate: Icons.fitness_center_rounded,
  MuscleState.active: Icons.local_fire_department_rounded,
  MuscleState.intense: Icons.bolt_rounded,
};

// ─── Widget ───────────────────────────────────────────────────────────────────

class BodyMapWidget extends StatefulWidget {
  final Map<String, MuscleData> muscleData;
  final void Function(String muscleId, MuscleData data) onMuscleTap;
  final String? initialSelectedId;

  /// 'male' | 'female' | null → shows inline gender picker
  final String? gender;

  const BodyMapWidget({
    required this.muscleData,
    required this.onMuscleTap,
    this.initialSelectedId,
    this.gender,
    super.key,
  });

  @override
  State<BodyMapWidget> createState() => _BodyMapWidgetState();
}

class _BodyMapWidgetState extends State<BodyMapWidget>
    with SingleTickerProviderStateMixin {
  bool _isFront = true;
  String? _selectedId;
  String _localGender = 'male'; // used when widget.gender == null
  late final AnimationController _flipCtrl;
  late final Animation<double> _flipAnim;

  String get _activeGender => widget.gender ?? _localGender;

  @override
  void initState() {
    super.initState();
    _selectedId = widget.initialSelectedId;
    _flipCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _flipAnim =
        CurvedAnimation(parent: _flipCtrl, curve: Curves.easeInOutCubic);
  }

  @override
  void dispose() {
    _flipCtrl.dispose();
    super.dispose();
  }

  void _toggleView() {
    HapticFeedback.selectionClick();
    if (_isFront) {
      _flipCtrl.forward();
    } else {
      _flipCtrl.reverse();
    }
    setState(() {
      _isFront = !_isFront;
      _selectedId = null;
    });
  }

  void _handleTap(TapUpDetails details, Size size) {
    final zones = _isFront
        ? buildFrontZones(_activeGender)
        : buildBackZones(_activeGender);
    for (final zone in zones) {
      if (zone.contains(details.localPosition, size)) {
        HapticFeedback.lightImpact();
        setState(() => _selectedId = zone.id);
        final data = widget.muscleData[zone.id] ?? const MuscleData();
        widget.onMuscleTap(zone.id, data);
        return;
      }
    }
    setState(() => _selectedId = null);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Front / Back toggle ────────────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _ViewToggleButton(
              label: 'Front View',
              icon: Icons.person_rounded,
              isActive: _isFront,
              onTap: _isFront ? null : _toggleView,
              t: t,
            ),
            const SizedBox(width: 8),
            _ViewToggleButton(
              label: 'Back View',
              icon: Icons.person_outline_rounded,
              isActive: !_isFront,
              onTap: _isFront ? _toggleView : null,
              t: t,
            ),
          ],
        ),

        // ── Gender picker (only when gender not provided from profile) ──────
        if (widget.gender == null) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _GenderChip(
                label: '♂  Male',
                isSelected: _localGender == 'male',
                onTap: () => setState(() {
                  _localGender = 'male';
                  _selectedId = null;
                }),
                t: t,
              ),
              const SizedBox(width: 8),
              _GenderChip(
                label: '♀  Female',
                isSelected: _localGender == 'female',
                onTap: () => setState(() {
                  _localGender = 'female';
                  _selectedId = null;
                }),
                t: t,
              ),
            ],
          ),
        ],

        const SizedBox(height: 14),

        // ── Body diagram ───────────────────────────────────────────────────
        AnimatedBuilder(
          animation: _flipAnim,
          builder: (context, child) {
            final angle = _flipAnim.value * 3.14159;
            final isReversed = angle > 1.5708;
            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateY(angle),
              child: isReversed
                  ? Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()..rotateY(3.14159),
                      child: child,
                    )
                  : child,
            );
          },
          child: LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              final h = w * 2.0;
              final displaySize = Size(w, h);

              return SizedBox(
                width: w,
                height: h,
                child: GestureDetector(
                  onTapUp: (d) => _handleTap(d, displaySize),
                  child: RepaintBoundary(
                    child: CustomPaint(
                      size: displaySize,
                      painter: BodyAnatomyPainter(
                        isFront: _isFront,
                        gender: _activeGender,
                        muscleStates: {
                          for (final e in widget.muscleData.entries)
                            e.key: e.value.state,
                        },
                        selectedId: _selectedId,
                        brand: t.brand,
                        outline: t.textSecondary,
                        labelColor: t.textPrimary,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // ── Legend ────────────────────────────────────────────────────────
        const SizedBox(height: 16),
        _MuscleLegend(brand: t.brand),
      ],
    );
  }
}

// ─── Toggle button ─────────────────────────────────────────────────────────────

class _ViewToggleButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback? onTap;
  final dynamic t;

  const _ViewToggleButton({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.t,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.fitTheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? colors.brand.withOpacity(0.15)
              : colors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive
                ? colors.brand.withOpacity(0.60)
                : colors.border,
            width: isActive ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 16,
                color: isActive ? colors.brand : colors.textMuted),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight:
                    isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? colors.brand : colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Gender chip ───────────────────────────────────────────────────────────────

class _GenderChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final dynamic t;

  const _GenderChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.fitTheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? colors.brand.withOpacity(0.18)
              : colors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? colors.brand.withOpacity(0.70)
                : colors.border,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? colors.brand : colors.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ─── Legend ────────────────────────────────────────────────────────────────────

class _MuscleLegend extends StatelessWidget {
  final Color brand;
  const _MuscleLegend({required this.brand});

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;
    final items = [
      (MuscleState.untrained, 'Not Trained'),
      (MuscleState.recovery, 'Recovering'),
      (MuscleState.moderate, 'Moderate'),
      (MuscleState.active, 'Active Today'),
      (MuscleState.intense, 'Intense'),
    ];
    return Wrap(
      spacing: 12,
      runSpacing: 6,
      alignment: WrapAlignment.center,
      children: items.map((item) {
        final (state, label) = item;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: muscleStateColor(state, brand),
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: t.border, width: 0.5),
              ),
            ),
            const SizedBox(width: 4),
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 10, color: t.textMuted)),
          ],
        );
      }).toList(),
    );
  }
}
