// lib/screens/member/member_progress_screen.dart
//
// Full-featured Progress Hub for gym members.
// Tabs: Overview | Body Map | Weight | Measurements | Records

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/theme.dart';
import '../../core/dev_bypass.dart';
import '../../core/extensions.dart';
import '../../models/body_measurement_model.dart';
import '../../models/personal_record_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/body_measurement_provider.dart';
import '../../providers/gym_provider.dart';
import '../../providers/member_provider.dart';
import '../../providers/ai_agent_provider.dart';
import '../../providers/personal_records_provider.dart';
import '../../widgets/body_anatomy_painter.dart';
import '../../widgets/body_map_widget.dart';
import '../../widgets/glassmorphic_card.dart';
import '../../widgets/member_bottom_nav.dart';
import '../../widgets/muscle_info_card.dart';

// ─── Screen ──────────────────────────────────────────────────────────────────

class MemberProgressScreen extends ConsumerStatefulWidget {
  const MemberProgressScreen({super.key});

  @override
  ConsumerState<MemberProgressScreen> createState() =>
      _MemberProgressScreenState();
}

class _MemberProgressScreenState
    extends ConsumerState<MemberProgressScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  final _weightController = TextEditingController();

  // Body map state
  String? _selectedMuscleId;
  MuscleData? _selectedMuscleData;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;

    return Scaffold(
      backgroundColor: t.background,
      bottomNavigationBar: const MemberBottomNav(),
      appBar: AppBar(
        backgroundColor: t.background,
        automaticallyImplyLeading: false,
        title: Text(
          'My Progress',
          style: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: t.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: t.textSecondary),
            onPressed: () {
              ref.invalidate(memberProgressProvider);
              ref.invalidate(bodyMeasurementProvider);
              ref.invalidate(personalRecordsProvider);
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: t.brand,
          labelColor: t.brand,
          unselectedLabelColor: t.textMuted,
          indicatorWeight: 2.5,
          labelStyle: GoogleFonts.inter(
              fontSize: 13, fontWeight: FontWeight.w700),
          unselectedLabelStyle:
              GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Body Map'),
            Tab(text: 'Weight'),
            Tab(text: 'Measurements'),
            Tab(text: 'Records'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _OverviewTab(onGoToBodyMap: () => _tabCtrl.animateTo(1)),
          _BodyMapTab(
            selectedMuscleId: _selectedMuscleId,
            selectedMuscleData: _selectedMuscleData,
            onMuscleTap: (id, data) {
              setState(() {
                _selectedMuscleId = id;
                _selectedMuscleData = data;
              });
            },
          ),
          _WeightTab(weightController: _weightController),
          const _MeasurementsTab(),
          const _RecordsTab(),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TAB 0 — OVERVIEW
// ═══════════════════════════════════════════════════════════════════════════════

class _OverviewTab extends ConsumerWidget {
  final VoidCallback onGoToBodyMap;
  const _OverviewTab({required this.onGoToBodyMap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.fitTheme;
    final progressAsync = ref.watch(memberProgressProvider);
    final measureAsync = ref.watch(bodyMeasurementProvider);
    final prsAsync = ref.watch(personalRecordsProvider);
    final workoutAsync = ref.watch(memberWorkoutPlanProvider);

    final withWeight = progressAsync.valueOrNull
            ?.where((e) => e['weight_kg'] != null)
            .toList() ??
        [];
    final currentWeight = withWeight.isNotEmpty
        ? (withWeight.first['weight_kg'] as num).toDouble()
        : null;
    final measurements = measureAsync.valueOrNull ?? [];
    final bodyFat = measurements.isNotEmpty
        ? measurements.first.bodyFatPercent
        : null;
    final prCount = prsAsync.valueOrNull?.length ?? 0;

    // Derive today's target muscles from workout plan
    final todayMuscles = _deriveTodayMuscles(workoutAsync.valueOrNull);

    return CustomScrollView(
      slivers: [
        // ── Today's Focus ─────────────────────────────────────────────
        if (todayMuscles.isNotEmpty) ...[
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            sliver: SliverToBoxAdapter(
              child: _TodayFocusBanner(muscles: todayMuscles, t: t)
                  .animate()
                  .fadeIn(duration: 300.ms),
            ),
          ),
        ],

        // ── Summary cards ─────────────────────────────────────────────
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          sliver: SliverToBoxAdapter(
            child: Row(
              children: [
                Expanded(
                  child: _SummaryCard(
                    label: 'Weight',
                    value: currentWeight != null
                        ? '${currentWeight.toStringAsFixed(1)} kg'
                        : '—',
                    icon: Icons.monitor_weight_rounded,
                    color: t.brand,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _SummaryCard(
                    label: 'Body Fat',
                    value: bodyFat != null
                        ? '${bodyFat.toStringAsFixed(1)}%'
                        : '—',
                    icon: Icons.pie_chart_rounded,
                    color: t.warning,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _SummaryCard(
                    label: 'PRs',
                    value: '$prCount',
                    icon: Icons.emoji_events_rounded,
                    color: t.accent,
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 50.ms),
          ),
        ),

        // ── Quick actions ─────────────────────────────────────────────
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          sliver: SliverToBoxAdapter(
            child: Column(
              children: [
                _QuickActionRow(
                  label: 'Explore Body Map',
                  subtitle: 'See your muscle training status',
                  icon: Icons.accessibility_new_rounded,
                  color: t.brand,
                  onTap: onGoToBodyMap,
                ),
                const SizedBox(height: 10),
                _QuickActionRow(
                  label: 'Log Body Measurements',
                  subtitle: 'Track chest, arms, waist & more',
                  icon: Icons.straighten_rounded,
                  color: t.info,
                  onTap: () =>
                      context.push('/health/body-measurements'),
                ),
                const SizedBox(height: 10),
                _QuickActionRow(
                  label: 'Personal Records',
                  subtitle: 'Your strength milestones',
                  icon: Icons.star_rounded,
                  color: t.warning,
                  onTap: () =>
                      context.push('/workout/personal-records'),
                ),
              ],
            ).animate().fadeIn(delay: 100.ms),
          ),
        ),

        const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
      ],
    );
  }

  List<String> _deriveTodayMuscles(dynamic plan) {
    if (plan == null) return [];
    // plan.days is a list; each day has exercises; derive muscles from exercise names
    try {
      final days = plan.days as List?;
      if (days == null || days.isEmpty) return [];
      final today = days.first;
      final exercises = today.exercises as List?;
      if (exercises == null) return [];

      final muscles = <String>{};
      for (final ex in exercises) {
        final name = (ex['name'] as String? ?? '').toLowerCase();
        if (name.contains('bench') || name.contains('chest') ||
            name.contains('push')) {
          muscles.addAll(['pec_upper', 'pec_lower']);
        }
        if (name.contains('curl') || name.contains('bicep')) {
          muscles.addAll(['bicep_left', 'bicep_right']);
        }
        if (name.contains('squat') || name.contains('leg press') ||
            name.contains('lunge')) {
          muscles.addAll(['quad_left', 'quad_right']);
        }
        if (name.contains('deadlift') || name.contains('row')) {
          muscles.addAll(['lat_left', 'lat_right', 'lower_back']);
        }
        if (name.contains('press') || name.contains('shoulder') ||
            name.contains('delt')) {
          muscles.addAll(['delt_left', 'delt_right']);
        }
        if (name.contains('tricep') || name.contains('dip')) {
          muscles.addAll(['tricep_left', 'tricep_right']);
        }
        if (name.contains('crunch') || name.contains('plank') ||
            name.contains('ab')) {
          muscles.add('abs');
        }
      }
      return muscles.toList();
    } catch (_) {
      return [];
    }
  }
}

class _TodayFocusBanner extends StatelessWidget {
  final List<String> muscles;
  final FitNexoraThemeTokens t;
  const _TodayFocusBanner({required this.muscles, required this.t});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            t.brand.withOpacity(0.15),
            t.brand.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: t.brand.withOpacity(0.30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.local_fire_department_rounded,
                  color: t.brand, size: 16),
              const SizedBox(width: 6),
              Text(
                "TODAY'S TARGET MUSCLES",
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: t.brand,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: muscles.map((id) {
              final name = kMuscleDisplayName[id] ?? id;
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: t.brand.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: t.brand.withOpacity(0.35)),
                ),
                child: Text(
                  name,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: t.brand,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _SummaryCard(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.22)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(value,
              style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: color)),
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 10, color: t.textSecondary)),
        ],
      ),
    );
  }
}

class _QuickActionRow extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _QuickActionRow(
      {required this.label,
      required this.subtitle,
      required this.icon,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;
    return GlassmorphicCard(
      borderRadius: 14,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: t.textPrimary)),
                  Text(subtitle,
                      style: GoogleFonts.inter(
                          fontSize: 11, color: t.textSecondary)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: t.textMuted),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TAB 1 — BODY MAP
// ═══════════════════════════════════════════════════════════════════════════════

class _BodyMapTab extends ConsumerWidget {
  final String? selectedMuscleId;
  final MuscleData? selectedMuscleData;
  final void Function(String id, MuscleData data) onMuscleTap;

  const _BodyMapTab({
    required this.onMuscleTap,
    this.selectedMuscleId,
    this.selectedMuscleData,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.fitTheme;
    final prsAsync = ref.watch(personalRecordsProvider);
    final measureAsync = ref.watch(bodyMeasurementProvider);
    final workoutAsync = ref.watch(memberWorkoutPlanProvider);

    final prs = prsAsync.valueOrNull ?? [];
    final measurements = measureAsync.valueOrNull ?? [];
    final muscleData = _buildMuscleData(prs, measurements, workoutAsync.valueOrNull);

    // ── Resolve gender from FitnessProfile ───────────────────────────────────
    String? gender;
    final user = ref.watch(currentUserProvider).valueOrNull;
    final gym = ref.watch(selectedGymProvider);
    if (user != null && gym != null) {
      final profileAsync = ref.watch(
        fitnessProfileProvider((memberId: user.id, gymId: gym.id)),
      );
      gender = profileAsync.valueOrNull?.gender;
    }

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          sliver: SliverToBoxAdapter(
            child: Text(
              '${gender == 'female' ? '♀' : '♂'}  Tap any muscle to view training analytics',
              style: GoogleFonts.inter(
                  fontSize: 12, color: t.textSecondary),
              textAlign: TextAlign.center,
            ),
          ),
        ),

        // ── Body map diagram ─────────────────────────────────────────
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          sliver: SliverToBoxAdapter(
            child: GlassmorphicCard(
              borderRadius: 20,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: BodyMapWidget(
                  muscleData: muscleData,
                  initialSelectedId: selectedMuscleId,
                  onMuscleTap: onMuscleTap,
                  gender: gender,
                ),
              ),
            ),
          ),
        ),

        // ── Selected muscle info card ─────────────────────────────────
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          sliver: SliverToBoxAdapter(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, anim) =>
                  FadeTransition(opacity: anim, child: child),
              child: selectedMuscleId != null && selectedMuscleData != null
                  ? MuscleInfoCard(
                      key: ValueKey(selectedMuscleId),
                      muscleId: selectedMuscleId!,
                      data: selectedMuscleData!,
                    )
                  : Container(
                      key: const ValueKey('hint'),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: t.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: t.border.withOpacity(0.5)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.touch_app_rounded,
                              color: t.textMuted, size: 18),
                          const SizedBox(width: 10),
                          Text(
                            'Tap a muscle on the diagram above',
                            style: GoogleFonts.inter(
                                fontSize: 13, color: t.textMuted),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ),

        const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
      ],
    );
  }

  Map<String, MuscleData> _buildMuscleData(
    List<PersonalRecord> prs,
    List<BodyMeasurement> measurements,
    dynamic workoutPlan,
  ) {
    // Count PRs per exercise
    final exerciseCount = <String, int>{};
    for (final pr in prs) {
      final key = pr.exerciseName.toLowerCase();
      exerciseCount[key] = (exerciseCount[key] ?? 0) + 1;
    }

    // Derive today's active muscles
    final todayMuscles = <String>{};
    if (workoutPlan != null) {
      try {
        final days = workoutPlan.days as List?;
        if (days != null && days.isNotEmpty) {
          final exercises = days.first.exercises as List? ?? [];
          for (final ex in exercises) {
            final name =
                (ex['name'] as String? ?? '').toLowerCase();
            _mapExerciseToMuscles(name, todayMuscles);
          }
        }
      } catch (_) {}
    }

    // Latest measurements
    final latestM =
        measurements.isNotEmpty ? measurements.first : null;

    // Build map
    final result = <String, MuscleData>{};
    for (final id in [
      ...buildFrontZones('male').map((z) => z.id),
      ...buildBackZones('male').map((z) => z.id),
    ]) {
      final exercises = kMuscleExercises[id] ?? [];
      int trainingCount = 0;
      for (final ex in exercises) {
        trainingCount +=
            exerciseCount[ex.toLowerCase()] ?? 0;
      }

      final isToday = todayMuscles.contains(id);
      MuscleState state;
      if (isToday) {
        state = MuscleState.active;
      } else if (trainingCount >= 8) {
        state = MuscleState.intense;
      } else if (trainingCount >= 4) {
        state = MuscleState.moderate;
      } else if (trainingCount >= 1) {
        state = MuscleState.recovery;
      } else {
        state = MuscleState.untrained;
      }

      // Development % from measurements
      double devPercent = (trainingCount * 8.0).clamp(0, 100);
      if (latestM != null) {
        if ((id.contains('pec') || id.contains('chest')) &&
            latestM.chestCm != null) {
          devPercent = ((latestM.chestCm! / 120.0) * 100).clamp(0, 100);
        } else if (id.contains('bicep') && latestM.armCm != null) {
          devPercent = ((latestM.armCm! / 50.0) * 100).clamp(0, 100);
        } else if (id.contains('quad') && latestM.thighCm != null) {
          devPercent = ((latestM.thighCm! / 70.0) * 100).clamp(0, 100);
        }
      }

      result[id] = MuscleData(
        state: state,
        developmentPercent: devPercent,
        recoveryPercent: isToday ? 45.0 : (100.0 - trainingCount * 5.0).clamp(30, 100),
        proteinScore: (devPercent * 0.8).clamp(0, 100),
        trainingCountMonth: trainingCount,
        lastTrained: trainingCount > 0 ? '$trainingCount sessions' : null,
      );
    }
    return result;
  }

  void _mapExerciseToMuscles(String name, Set<String> out) {
    if (name.contains('bench') || name.contains('chest') ||
        name.contains('push')) {
      out.addAll(['pec_upper', 'pec_lower']);
    }
    if (name.contains('curl') || name.contains('bicep')) {
      out.addAll(['bicep_left', 'bicep_right']);
    }
    if (name.contains('squat') || name.contains('lunge')) {
      out.addAll(['quad_left', 'quad_right']);
    }
    if (name.contains('deadlift') || name.contains('row')) {
      out.addAll(['lat_left', 'lat_right', 'lower_back']);
    }
    if (name.contains('press') || name.contains('shoulder')) {
      out.addAll(['delt_left', 'delt_right']);
    }
    if (name.contains('tricep') || name.contains('dip')) {
      out.addAll(['tricep_left', 'tricep_right']);
    }
    if (name.contains('crunch') || name.contains('plank') ||
        name.contains(' ab')) {
      out.add('abs');
    }
    if (name.contains('glute') || name.contains('hip thrust')) {
      out.addAll(['glute_left', 'glute_right']);
    }
    if (name.contains('ham') || name.contains('rdl')) {
      out.addAll(['ham_left', 'ham_right']);
    }
    if (name.contains('calf')) {
      out.addAll([
        'tibialis_left', 'tibialis_right',
        'calf_left', 'calf_right',
      ]);
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TAB 2 — WEIGHT
// ═══════════════════════════════════════════════════════════════════════════════

class _WeightTab extends ConsumerStatefulWidget {
  final TextEditingController weightController;
  const _WeightTab({required this.weightController});

  @override
  ConsumerState<_WeightTab> createState() => _WeightTabState();
}

class _WeightTabState extends ConsumerState<_WeightTab> {
  void _showLogSheet(BuildContext context) {
    final t = context.fitTheme;
    widget.weightController.clear();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: t.surfaceAlt,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: t.textMuted.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('Log Today\'s Weight',
                style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: t.textPrimary)),
            const SizedBox(height: 20),
            TextFormField(
              controller: widget.weightController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: GoogleFonts.inter(
                  color: t.textPrimary, fontSize: 24),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: '75.0',
                hintStyle: GoogleFonts.inter(color: t.textMuted),
                suffix: Text(' kg',
                    style: GoogleFonts.inter(
                        color: t.textSecondary, fontSize: 18)),
                filled: true,
                fillColor: t.surfaceMuted,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: t.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: t.brand, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: () => _saveWeight(context),
                style: FilledButton.styleFrom(
                  backgroundColor: t.brand,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: Text('Save Weight',
                    style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveWeight(BuildContext context) async {
    final t = context.fitTheme;
    final val = double.tryParse(widget.weightController.text);
    if (val == null || val <= 0) return;

    final user = ref.read(currentUserProvider).value;
    if (user == null) return;

    if (isDevUser(user.email)) {
      ref.invalidate(memberProgressProvider);
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Weight logged: ${val.toStringAsFixed(1)} kg'),
          backgroundColor: t.success,
        ));
      }
      return;
    }

    final gym = ref.read(selectedGymProvider);
    if (gym == null) return;

    try {
      final db = ref.read(databaseServiceProvider);
      await db.logWeight(
          gymId: gym.id, clientId: user.id, weightKg: val);
      ref.invalidate(memberProgressProvider);
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Weight logged: ${val.toStringAsFixed(1)} kg'),
          backgroundColor: t.success,
        ));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Failed: $e'),
            backgroundColor: t.danger));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;
    final progressAsync = ref.watch(memberProgressProvider);

    return progressAsync.when(
      loading: () => Center(
          child: CircularProgressIndicator(color: t.brand)),
      error: (e, _) => Center(
          child: Text('Error: $e',
              style: GoogleFonts.inter(color: t.danger))),
      data: (entries) {
        final withWeight = entries
            .where((e) => e['weight_kg'] != null)
            .toList();

        if (withWeight.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.monitor_weight_rounded,
                    size: 56, color: t.textMuted),
                const SizedBox(height: 16),
                Text('No weight entries yet',
                    style: GoogleFonts.inter(
                        color: t.textSecondary, fontSize: 16)),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => _showLogSheet(context),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Log First Entry'),
                  style: FilledButton.styleFrom(
                      backgroundColor: t.brand),
                ),
              ],
            ),
          );
        }

        final current = (withWeight.first['weight_kg'] as num).toDouble();
        final oldest =
            (withWeight.last['weight_kg'] as num).toDouble();
        final change = current - oldest;

        return CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    Expanded(
                        child: _WStatCard(
                      label: 'Current',
                      value: '${current.toStringAsFixed(1)} kg',
                      color: t.brand,
                    )),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _WStatCard(
                      label: change <= 0 ? '▼ Lost' : '▲ Gained',
                      value: '${change.abs().toStringAsFixed(1)} kg',
                      color:
                          change <= 0 ? t.success : t.warning,
                    )),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _WStatCard(
                      label: 'Entries',
                      value: '${withWeight.length}',
                      color: t.info,
                    )),
                  ],
                ).animate().fadeIn(),
              ),
            ),
            SliverPadding(
              padding:
                  const EdgeInsets.fromLTRB(20, 20, 20, 0),
              sliver: SliverToBoxAdapter(
                child: GlassmorphicCard(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text('Progress Chart',
                                style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight:
                                        FontWeight.w700,
                                    color: t.textPrimary)),
                            const Spacer(),
                            TextButton.icon(
                              onPressed: () =>
                                  _showLogSheet(context),
                              icon: Icon(Icons.add_rounded,
                                  size: 16, color: t.brand),
                              label: Text('Log Weight',
                                  style: GoogleFonts.inter(
                                      color: t.brand,
                                      fontSize: 12)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 160,
                          child: RepaintBoundary(
                            child: _WeightChart(
                                entries: withWeight.reversed
                                    .toList()),
                          ),
                        ),
                      ],
                    ),
                  ),
                ).animate(delay: 100.ms).fadeIn(),
              ),
            ),
            SliverPadding(
              padding:
                  const EdgeInsets.fromLTRB(20, 20, 20, 8),
              sliver: SliverToBoxAdapter(
                child: Text('HISTORY',
                    style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: t.textMuted,
                        letterSpacing: 1.2)),
              ),
            ),
            SliverPadding(
              padding:
                  const EdgeInsets.fromLTRB(20, 0, 20, 40),
              sliver: SliverToBoxAdapter(
                child: GlassmorphicCard(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      children: withWeight
                          .asMap()
                          .entries
                          .map((entry) {
                        final i = entry.key;
                        final e = entry.value;
                        final prevWeight =
                            i < withWeight.length - 1
                                ? withWeight[i + 1]
                                        ['weight_kg'] as num
                                : null;
                        final w = e['weight_kg'] as num;
                        final diff = prevWeight != null
                            ? w - prevWeight
                            : null;
                        final date =
                            e['checkin_date'] as String;
                        return Column(
                          children: [
                            ListTile(
                              contentPadding:
                                  const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 2),
                              title: Text(
                                _formatDate(date),
                                style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: t.textSecondary),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (diff != null)
                                    Text(
                                      diff < 0
                                          ? '▼ ${(-diff).toStringAsFixed(1)}'
                                          : diff > 0
                                              ? '▲ ${diff.toStringAsFixed(1)}'
                                              : '—',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: diff < 0
                                            ? t.success
                                            : diff > 0
                                                ? t.warning
                                                : t.textMuted,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  const SizedBox(width: 12),
                                  Text(
                                    '${w.toStringAsFixed(1)} kg',
                                    style: GoogleFonts.inter(
                                        fontSize: 16,
                                        fontWeight:
                                            FontWeight.w800,
                                        color: t.textPrimary),
                                  ),
                                ],
                              ),
                            ),
                            if (i < withWeight.length - 1)
                              Divider(
                                  color: t.divider, height: 1),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ).animate(delay: 200.ms).fadeIn(),
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatDate(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    return dt.mediumFormatted;
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TAB 3 — MEASUREMENTS
// ═══════════════════════════════════════════════════════════════════════════════

class _MeasurementsTab extends ConsumerWidget {
  const _MeasurementsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.fitTheme;
    final async = ref.watch(bodyMeasurementProvider);

    return async.when(
      loading: () =>
          Center(child: CircularProgressIndicator(color: t.brand)),
      error: (e, _) => Center(
          child: Text('$e',
              style: GoogleFonts.inter(color: t.danger))),
      data: (measurements) {
        if (measurements.isEmpty) {
          return _EmptyState(
            icon: Icons.straighten_rounded,
            title: 'No measurements logged',
            subtitle: 'Track your body composition over time',
            buttonLabel: 'Log Measurements',
            onTap: () =>
                context.push('/health/body-measurements'),
          );
        }

        final latest = measurements.first;
        final prev =
            measurements.length > 1 ? measurements[1] : null;

        return CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              sliver: SliverToBoxAdapter(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('LATEST ENTRY',
                        style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: t.textMuted,
                            letterSpacing: 1.1)),
                    TextButton.icon(
                      onPressed: () => context
                          .push('/health/body-measurements'),
                      icon: Icon(Icons.add_rounded,
                          size: 16, color: t.brand),
                      label: Text('Add',
                          style: GoogleFonts.inter(
                              color: t.brand, fontSize: 12)),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding:
                  const EdgeInsets.fromLTRB(20, 10, 20, 0),
              sliver: SliverToBoxAdapter(
                child: GlassmorphicCard(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _measureRow('Weight', latest.weightKg,
                            prev?.weightKg, 'kg', t),
                        _measureRow('Body Fat',
                            latest.bodyFatPercent,
                            prev?.bodyFatPercent, '%', t),
                        _measureRow('Muscle Mass',
                            latest.muscleMassKg,
                            prev?.muscleMassKg, 'kg', t),
                        _measureRow('Chest', latest.chestCm,
                            prev?.chestCm, 'cm', t),
                        _measureRow('Waist', latest.waistCm,
                            prev?.waistCm, 'cm', t),
                        _measureRow('Arms (Biceps)', latest.armCm,
                            prev?.armCm, 'cm', t),
                        _measureRow('Thighs', latest.thighCm,
                            prev?.thighCm, 'cm', t),
                        _measureRow(
                            'Hips', latest.hipCm, prev?.hipCm, 'cm', t),
                      ],
                    ),
                  ),
                ).animate().fadeIn(),
              ),
            ),
            if (measurements.length > 1) ...[
              SliverPadding(
                padding:
                    const EdgeInsets.fromLTRB(20, 20, 20, 8),
                sliver: SliverToBoxAdapter(
                  child: Text('HISTORY',
                      style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: t.textMuted,
                          letterSpacing: 1.1)),
                ),
              ),
              SliverPadding(
                padding:
                    const EdgeInsets.fromLTRB(20, 0, 20, 40),
                sliver: SliverList.builder(
                  itemCount: measurements.length,
                  itemBuilder: (ctx, i) {
                    final m = measurements[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: GlassmorphicCard(
                        borderRadius: 12,
                        child: ListTile(
                          contentPadding:
                              const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 4),
                          title: Text(
                            _fmt(m.recordedAt),
                            style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: t.textPrimary),
                          ),
                          subtitle: Text(
                            _measureSummary(m),
                            style: GoogleFonts.inter(
                                fontSize: 11,
                                color: t.textSecondary),
                          ),
                          trailing: m.weightKg != null
                              ? Text(
                                  '${m.weightKg!.toStringAsFixed(1)} kg',
                                  style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: t.brand),
                                )
                              : null,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _measureRow(String label, double? value, double? prev,
      String unit, FitNexoraThemeTokens t) {
    if (value == null) return const SizedBox.shrink();
    final diff = prev != null ? value - prev : null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: GoogleFonts.inter(
                    fontSize: 13, color: t.textSecondary)),
          ),
          if (diff != null && diff.abs() > 0.01)
            Text(
              diff > 0
                  ? '+${diff.toStringAsFixed(1)}'
                  : diff.toStringAsFixed(1),
              style: GoogleFonts.inter(
                fontSize: 11,
                color: diff > 0 ? t.success : t.danger,
                fontWeight: FontWeight.w600,
              ),
            ),
          const SizedBox(width: 10),
          Text(
            '${value.toStringAsFixed(1)} $unit',
            style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: t.textPrimary),
          ),
        ],
      ),
    );
  }

  String _fmt(DateTime d) {
    const m = ['Jan','Feb','Mar','Apr','May','Jun',
        'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${d.day} ${m[d.month - 1]} ${d.year}';
  }

  String _measureSummary(BodyMeasurement m) {
    final parts = <String>[];
    if (m.bodyFatPercent != null) {
      parts.add('Fat: ${m.bodyFatPercent!.toStringAsFixed(1)}%');
    }
    if (m.chestCm != null) {
      parts.add('Chest: ${m.chestCm!.toStringAsFixed(0)} cm');
    }
    if (m.armCm != null) {
      parts.add('Arms: ${m.armCm!.toStringAsFixed(0)} cm');
    }
    return parts.join(' · ');
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TAB 4 — RECORDS
// ═══════════════════════════════════════════════════════════════════════════════

class _RecordsTab extends ConsumerWidget {
  const _RecordsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.fitTheme;
    final async = ref.watch(personalRecordsProvider);

    return async.when(
      loading: () =>
          Center(child: CircularProgressIndicator(color: t.brand)),
      error: (e, _) => Center(
          child: Text('$e',
              style: GoogleFonts.inter(color: t.danger))),
      data: (prs) {
        if (prs.isEmpty) {
          return _EmptyState(
            icon: Icons.emoji_events_rounded,
            title: 'No personal records yet',
            subtitle: 'Log your first PR to start tracking strength',
            buttonLabel: 'View Records',
            onTap: () =>
                context.push('/workout/personal-records'),
          );
        }

        // Sort by weight descending for top PRs
        final sorted = [...prs]
          ..sort((a, b) => b.weightKg.compareTo(a.weightKg));
        final top5 = sorted.take(5).toList();

        return CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              sliver: SliverToBoxAdapter(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('TOP LIFTS',
                        style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: t.textMuted,
                            letterSpacing: 1.1)),
                    TextButton(
                      onPressed: () =>
                          context.push('/workout/personal-records'),
                      child: Text('View All',
                          style: GoogleFonts.inter(
                              color: t.brand, fontSize: 12)),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding:
                  const EdgeInsets.fromLTRB(20, 8, 20, 0),
              sliver: SliverList.builder(
                itemCount: top5.length,
                itemBuilder: (ctx, i) {
                  final pr = top5[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: GlassmorphicCard(
                      borderRadius: 14,
                      child: ListTile(
                        contentPadding:
                            const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 6),
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: t.warning.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '#${i + 1}',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: t.warning,
                            ),
                          ),
                        ),
                        title: Text(
                          pr.exerciseName,
                          style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: t.textPrimary),
                        ),
                        subtitle: Text(
                          _prDate(pr.achievedAt),
                          style: GoogleFonts.inter(
                              fontSize: 11,
                              color: t.textMuted),
                        ),
                        trailing: Column(
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          crossAxisAlignment:
                              CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${pr.weightKg.toStringAsFixed(1)} kg',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                color: t.brand,
                              ),
                            ),
                            Text(
                              '× ${pr.reps} reps',
                              style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: t.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ).animate(delay: (i * 40).ms).fadeIn().slideY(begin: 0.04),
                  );
                },
              ),
            ),
            const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
          ],
        );
      },
    );
  }

  String _prDate(DateTime d) {
    const m = ['Jan','Feb','Mar','Apr','May','Jun',
        'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${d.day} ${m[d.month - 1]} ${d.year}';
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SHARED HELPERS
// ═══════════════════════════════════════════════════════════════════════════════

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String buttonLabel;
  final VoidCallback onTap;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 56, color: t.textMuted),
            const SizedBox(height: 16),
            Text(title,
                style: GoogleFonts.inter(
                    color: t.textSecondary, fontSize: 16),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(subtitle,
                style: GoogleFonts.inter(
                    color: t.textMuted, fontSize: 13),
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onTap,
              icon: const Icon(Icons.add_rounded),
              label: Text(buttonLabel),
              style: FilledButton.styleFrom(
                  backgroundColor: t.brand),
            ),
          ],
        ),
      ),
    );
  }
}

class _WStatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _WStatCard(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        children: [
          Text(value,
              style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: color)),
          const SizedBox(height: 2),
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 11, color: t.textSecondary)),
        ],
      ),
    );
  }
}

// ─── Weight chart (CustomPaint) ───────────────────────────────────────────────

class _WeightChart extends StatelessWidget {
  final List<Map<String, dynamic>> entries;
  const _WeightChart({required this.entries});

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.shrink();
    final brandColor = context.fitTheme.brand;
    final weights = entries
        .map((e) => (e['weight_kg'] as num).toDouble())
        .toList();
    return CustomPaint(
      painter: _ChartPainter(weights: weights, brandColor: brandColor),
      size: const Size(double.infinity, 160),
    );
  }
}

class _ChartPainter extends CustomPainter {
  final List<double> weights;
  final Color brandColor;
  _ChartPainter({required this.weights, required this.brandColor});

  @override
  void paint(Canvas canvas, Size size) {
    if (weights.length < 2) return;
    final minW = weights.reduce((a, b) => a < b ? a : b) - 1;
    final maxW = weights.reduce((a, b) => a > b ? a : b) + 1;
    final range = maxW - minW;

    final linePaint = Paint()
      ..color = brandColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final dotPaint = Paint()
      ..color = brandColor
      ..style = PaintingStyle.fill;
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          brandColor.withOpacity(0.30),
          brandColor.withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final n = weights.length;
    final path = Path();
    final fillPath = Path();

    for (var i = 0; i < n; i++) {
      final x = i * size.width / (n - 1);
      final y =
          size.height - ((weights[i] - minW) / range) * size.height;
      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
      canvas.drawCircle(Offset(x, y), 4, dotPaint);
    }
    fillPath.lineTo((n - 1) * size.width / (n - 1), size.height);
    fillPath.close();
    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => true;
}
