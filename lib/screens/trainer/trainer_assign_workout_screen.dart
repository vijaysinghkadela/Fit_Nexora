import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/theme.dart';
import '../../config/workout_templates.dart';
import '../../core/extensions.dart';
import '../../models/client_profile_model.dart';
import '../../models/workout_plan_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/client_provider.dart';
import '../../providers/gym_provider.dart';
import '../../screens/workouts/workouts_screen.dart';
import '../../widgets/glassmorphic_card.dart';

class TrainerAssignWorkoutScreen extends ConsumerStatefulWidget {
  const TrainerAssignWorkoutScreen({super.key});

  @override
  ConsumerState<TrainerAssignWorkoutScreen> createState() =>
      _TrainerAssignWorkoutScreenState();
}

class _TrainerAssignWorkoutScreenState
    extends ConsumerState<TrainerAssignWorkoutScreen> {
  // 0 = select client, 1 = select template, 2 = preview & edit
  int _step = 0;

  ClientProfile? _selectedClient;
  WorkoutPlan? _selectedPlan;
  String _selectedAthleteType = 'All';
  bool _isAssigning = false;

  // Deep-copy of selected plan's days for inline editing
  List<TrainingDay> _editableDays = [];

  // Track which days are expanded in step 2
  final Set<int> _expandedDays = {};

  // Reps text controllers keyed by "dayIndex_exerciseIndex"
  final Map<String, TextEditingController> _repsControllers = {};

  @override
  void dispose() {
    for (final c in _repsControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  void _selectTemplate(WorkoutPlan plan) {
    // Deep-copy days so edits don't mutate the source template.
    final days = plan.days
        .map(
          (d) => TrainingDay(
            dayName: d.dayName,
            muscleGroup: d.muscleGroup,
            dayIndex: d.dayIndex,
            notes: d.notes,
            exercises: d.exercises
                .map(
                  (e) => Exercise(
                    name: e.name,
                    sets: e.sets,
                    reps: e.reps,
                    restSeconds: e.restSeconds,
                    rpe: e.rpe,
                    intensity: e.intensity,
                    equipment: e.equipment,
                    cue: e.cue,
                    orderIndex: e.orderIndex,
                    setTime: e.setTime,
                    supersetGroupId: e.supersetGroupId,
                    tempo: e.tempo,
                    substitute: e.substitute,
                  ),
                )
                .toList(),
          ),
        )
        .toList();

    // Dispose old controllers and build new ones.
    for (final c in _repsControllers.values) {
      c.dispose();
    }
    _repsControllers.clear();
    for (var di = 0; di < days.length; di++) {
      for (var ei = 0; ei < days[di].exercises.length; ei++) {
        _repsControllers['${di}_$ei'] =
            TextEditingController(text: days[di].exercises[ei].reps);
      }
    }

    setState(() {
      _selectedPlan = plan;
      _editableDays = days;
      _expandedDays.clear();
      _step = 2;
    });
  }

  void _incrementSets(int dayIndex, int exerciseIndex) {
    setState(() {
      final day = _editableDays[dayIndex];
      final ex = day.exercises[exerciseIndex];
      final updated = List<Exercise>.from(day.exercises)
        ..[exerciseIndex] = Exercise(
          name: ex.name,
          sets: ex.sets + 1,
          reps: ex.reps,
          restSeconds: ex.restSeconds,
          rpe: ex.rpe,
          intensity: ex.intensity,
          equipment: ex.equipment,
          cue: ex.cue,
          orderIndex: ex.orderIndex,
          setTime: ex.setTime,
          supersetGroupId: ex.supersetGroupId,
          tempo: ex.tempo,
          substitute: ex.substitute,
        );
      _editableDays[dayIndex] = TrainingDay(
        dayName: day.dayName,
        muscleGroup: day.muscleGroup,
        dayIndex: day.dayIndex,
        notes: day.notes,
        exercises: updated,
      );
    });
  }

  void _decrementSets(int dayIndex, int exerciseIndex) {
    final ex = _editableDays[dayIndex].exercises[exerciseIndex];
    if (ex.sets <= 1) return;
    setState(() {
      final day = _editableDays[dayIndex];
      final updated = List<Exercise>.from(day.exercises)
        ..[exerciseIndex] = Exercise(
          name: ex.name,
          sets: ex.sets - 1,
          reps: ex.reps,
          restSeconds: ex.restSeconds,
          rpe: ex.rpe,
          intensity: ex.intensity,
          equipment: ex.equipment,
          cue: ex.cue,
          orderIndex: ex.orderIndex,
          setTime: ex.setTime,
          supersetGroupId: ex.supersetGroupId,
          tempo: ex.tempo,
          substitute: ex.substitute,
        );
      _editableDays[dayIndex] = TrainingDay(
        dayName: day.dayName,
        muscleGroup: day.muscleGroup,
        dayIndex: day.dayIndex,
        notes: day.notes,
        exercises: updated,
      );
    });
  }

  void _updateRpe(int dayIndex, int exerciseIndex, int rpe) {
    setState(() {
      final day = _editableDays[dayIndex];
      final ex = day.exercises[exerciseIndex];
      final updated = List<Exercise>.from(day.exercises)
        ..[exerciseIndex] = Exercise(
          name: ex.name,
          sets: ex.sets,
          reps: ex.reps,
          restSeconds: ex.restSeconds,
          rpe: rpe,
          intensity: ex.intensity,
          equipment: ex.equipment,
          cue: ex.cue,
          orderIndex: ex.orderIndex,
          setTime: ex.setTime,
          supersetGroupId: ex.supersetGroupId,
          tempo: ex.tempo,
          substitute: ex.substitute,
        );
      _editableDays[dayIndex] = TrainingDay(
        dayName: day.dayName,
        muscleGroup: day.muscleGroup,
        dayIndex: day.dayIndex,
        notes: day.notes,
        exercises: updated,
      );
    });
  }

  // Flush reps text controllers back into _editableDays before saving.
  void _flushRepsControllers() {
    for (var di = 0; di < _editableDays.length; di++) {
      final day = _editableDays[di];
      final updated = List<Exercise>.from(day.exercises);
      for (var ei = 0; ei < day.exercises.length; ei++) {
        final key = '${di}_$ei';
        final text = _repsControllers[key]?.text.trim() ?? '';
        if (text.isNotEmpty) {
          final ex = day.exercises[ei];
          updated[ei] = Exercise(
            name: ex.name,
            sets: ex.sets,
            reps: text,
            restSeconds: ex.restSeconds,
            rpe: ex.rpe,
            intensity: ex.intensity,
            equipment: ex.equipment,
            cue: ex.cue,
            orderIndex: ex.orderIndex,
            setTime: ex.setTime,
            supersetGroupId: ex.supersetGroupId,
            tempo: ex.tempo,
            substitute: ex.substitute,
          );
        }
      }
      _editableDays[di] = TrainingDay(
        dayName: day.dayName,
        muscleGroup: day.muscleGroup,
        dayIndex: day.dayIndex,
        notes: day.notes,
        exercises: updated,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Assignment
  // ---------------------------------------------------------------------------

  Future<void> _assignPlan() async {
    if (_selectedClient == null || _selectedPlan == null) return;
    _flushRepsControllers();

    setState(() => _isAssigning = true);
    try {
      final db = ref.read(databaseServiceProvider);
      final currentUser = ref.read(currentUserProvider).value;
      final gym = ref.read(selectedGymProvider);

      final planData = {
        'gym_id': gym?.id ?? _selectedPlan!.gymId,
        'client_id': _selectedClient!.id,
        'trainer_id': currentUser?.id,
        'name': _selectedPlan!.name,
        'description': _selectedPlan!.description,
        'goal': _selectedPlan!.goal,
        'athlete_type': _selectedPlan!.athleteType,
        'duration_weeks': _selectedPlan!.durationWeeks,
        'current_week': 1,
        'phase': _selectedPlan!.phase,
        'status': 'active',
        'is_template': false,
        'days': _editableDays.map((d) => d.toJson()).toList(),
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      await db.createWorkoutPlan(planData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${_selectedPlan!.name} assigned to ${_selectedClient!.fullName ?? 'client'}',
            ),
            backgroundColor: context.fitTheme.accent,
          ),
        );
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/trainer');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: context.fitTheme.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isAssigning = false);
    }
  }

  // ---------------------------------------------------------------------------
  // Back handling
  // ---------------------------------------------------------------------------

  void _handleBack() {
    if (_step > 0) {
      setState(() => _step--);
    } else if (context.canPop()) {
      context.pop();
    } else {
      context.go('/trainer');
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;

    final stepTitles = ['Select Client', 'Select Plan', 'Review & Customize'];

    return Scaffold(
      backgroundColor: t.background,
      appBar: AppBar(
        backgroundColor: t.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: t.textPrimary),
          onPressed: _handleBack,
        ),
        title: Text(
          stepTitles[_step],
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: t.textPrimary,
          ),
        ),
        actions: [
          if (_step > 0)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  '${_step + 1}/3',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: t.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: _buildStep(context, t),
      ),
    );
  }

  Widget _buildStep(BuildContext context, FitNexoraThemeTokens t) {
    switch (_step) {
      case 0:
        return _StepSelectClient(
          key: const ValueKey('step0'),
          selectedClient: _selectedClient,
          onClientSelected: (client) {
            setState(() {
              _selectedClient = client;
              _step = 1;
            });
          },
        );
      case 1:
        return _StepSelectPlan(
          key: const ValueKey('step1'),
          selectedAthleteType: _selectedAthleteType,
          selectedPlan: _selectedPlan,
          onAthleteTypeChanged: (type) =>
              setState(() => _selectedAthleteType = type),
          onPlanSelected: _selectTemplate,
        );
      case 2:
        return _StepPreviewEdit(
          key: const ValueKey('step2'),
          selectedClient: _selectedClient!,
          selectedPlan: _selectedPlan!,
          editableDays: _editableDays,
          expandedDays: _expandedDays,
          repsControllers: _repsControllers,
          isAssigning: _isAssigning,
          onIncrementSets: _incrementSets,
          onDecrementSets: _decrementSets,
          onUpdateRpe: _updateRpe,
          onToggleDay: (i) => setState(() {
            if (_expandedDays.contains(i)) {
              _expandedDays.remove(i);
            } else {
              _expandedDays.add(i);
            }
          }),
          onAssign: _assignPlan,
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

// =============================================================================
// Step 0 — Select Client
// =============================================================================

class _StepSelectClient extends ConsumerWidget {
  final ClientProfile? selectedClient;
  final ValueChanged<ClientProfile> onClientSelected;

  const _StepSelectClient({
    super.key,
    required this.selectedClient,
    required this.onClientSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.fitTheme;
    final clientsAsync = ref.watch(trainerClientsProvider);

    return clientsAsync.when(
      loading: () => Center(
        child: CircularProgressIndicator(color: t.brand),
      ),
      error: (e, _) => Center(
        child: Text('Error loading clients: $e',
            style: GoogleFonts.inter(color: t.danger)),
      ),
      data: (clients) {
        if (clients.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.people_outline_rounded,
                      size: 56, color: t.textMuted),
                  const SizedBox(height: 16),
                  Text(
                    'No clients assigned to you yet',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: t.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          itemCount: clients.length,
          itemBuilder: (context, index) {
            final client = clients[index];
            final isSelected = selectedClient?.id == client.id;
            final initials = _initials(client.fullName);
            return _ClientCard(
              client: client,
              initials: initials,
              isSelected: isSelected,
              onTap: () => onClientSelected(client),
            );
          },
        );
      },
    );
  }

  String _initials(String? name) {
    if (name == null || name.isEmpty) return 'C';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }
}

class _ClientCard extends StatelessWidget {
  final ClientProfile client;
  final String initials;
  final bool isSelected;
  final VoidCallback onTap;

  const _ClientCard({
    required this.client,
    required this.initials,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? t.brand : t.border,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: GlassmorphicCard(
            borderRadius: 16,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor:
                        isSelected ? t.brand.withOpacity(0.2) : t.surfaceAlt,
                    child: Text(
                      initials,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: isSelected ? t.brand : t.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          client.fullName ?? 'Unknown',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: t.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          client.currentPlanName ?? 'No plan assigned',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: t.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    Icon(Icons.check_circle_rounded,
                        color: t.brand, size: 22)
                  else
                    Icon(Icons.chevron_right_rounded,
                        color: t.textMuted, size: 22),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Step 1 — Select Plan
// =============================================================================

class _StepSelectPlan extends ConsumerWidget {
  final String selectedAthleteType;
  final WorkoutPlan? selectedPlan;
  final ValueChanged<String> onAthleteTypeChanged;
  final ValueChanged<WorkoutPlan> onPlanSelected;

  const _StepSelectPlan({
    super.key,
    required this.selectedAthleteType,
    required this.selectedPlan,
    required this.onAthleteTypeChanged,
    required this.onPlanSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.fitTheme;
    final gymPlansAsync = ref.watch(gymWorkoutPlansProvider);

    // Merge templates + gym plans, deduplicated by id.
    final allPlans = gymPlansAsync.maybeWhen(
      data: (gymPlans) {
        final gymTemplates =
            gymPlans.where((p) => p.isTemplate || p.clientId == null).toList();
        final merged = [...kWorkoutTemplates, ...gymTemplates];
        // Deduplicate
        final seen = <String>{};
        return merged.where((p) => seen.add(p.id)).toList();
      },
      orElse: () => kWorkoutTemplates,
    );

    final filtered = selectedAthleteType == 'All'
        ? allPlans
        : allPlans
            .where((p) => p.athleteType == selectedAthleteType)
            .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Filter chips
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _AthleteChip(
                label: 'All',
                color: t.brand,
                isSelected: selectedAthleteType == 'All',
                onTap: () => onAthleteTypeChanged('All'),
              ),
              ...kAthleteTypes.map(
                (type) => _AthleteChip(
                  label: type,
                  color: kAthleteTypeColors[type] ?? t.brand,
                  isSelected: selectedAthleteType == type,
                  onTap: () => onAthleteTypeChanged(type),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Text(
                    'No plans for this category',
                    style: GoogleFonts.inter(color: t.textMuted),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final plan = filtered[index];
                    return _PlanCard(
                      plan: plan,
                      isSelected: selectedPlan?.id == plan.id,
                      onUseTemplate: () => onPlanSelected(plan),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _AthleteChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _AthleteChip({
    required this.label,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.18) : t.surfaceAlt,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? color : t.border,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? color : t.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final WorkoutPlan plan;
  final bool isSelected;
  final VoidCallback onUseTemplate;

  const _PlanCard({
    required this.plan,
    required this.isSelected,
    required this.onUseTemplate,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;
    final typeColor =
        kAthleteTypeColors[plan.athleteType] ?? t.brand;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassmorphicCard(
        borderRadius: 16,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      plan.name,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: t.textPrimary,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: typeColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: typeColor.withOpacity(0.4), width: 1),
                    ),
                    child: Text(
                      plan.athleteType,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: typeColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${plan.durationWeeks} weeks  •  '
                '${plan.trainingDaysCount} days  •  '
                '${plan.totalExercises} exercises',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: t.textSecondary,
                ),
              ),
              if (plan.goal.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  plan.goal.replaceAll('_', ' ').toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: t.textMuted,
                    letterSpacing: 0.6,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: onUseTemplate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: t.brandGradient,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Use Template',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Step 2 — Preview & Edit
// =============================================================================

class _StepPreviewEdit extends StatelessWidget {
  final ClientProfile selectedClient;
  final WorkoutPlan selectedPlan;
  final List<TrainingDay> editableDays;
  final Set<int> expandedDays;
  final Map<String, TextEditingController> repsControllers;
  final bool isAssigning;
  final void Function(int dayIndex, int exerciseIndex) onIncrementSets;
  final void Function(int dayIndex, int exerciseIndex) onDecrementSets;
  final void Function(int dayIndex, int exerciseIndex, int rpe) onUpdateRpe;
  final ValueChanged<int> onToggleDay;
  final VoidCallback onAssign;

  const _StepPreviewEdit({
    super.key,
    required this.selectedClient,
    required this.selectedPlan,
    required this.editableDays,
    required this.expandedDays,
    required this.repsControllers,
    required this.isAssigning,
    required this.onIncrementSets,
    required this.onDecrementSets,
    required this.onUpdateRpe,
    required this.onToggleDay,
    required this.onAssign,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;
    final typeColor =
        kAthleteTypeColors[selectedPlan.athleteType] ?? t.brand;

    return Column(
      children: [
        // Header card
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          child: GlassmorphicCard(
            borderRadius: 16,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          selectedPlan.name,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: t.textPrimary,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: typeColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: typeColor.withOpacity(0.4), width: 1),
                        ),
                        child: Text(
                          selectedPlan.athleteType,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: typeColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.person_outline_rounded,
                          size: 14, color: t.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        'Assigned to: ',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: t.textMuted,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: t.brand.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          selectedClient.fullName ?? 'Client',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: t.brand,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Training days list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
            itemCount: editableDays.length,
            itemBuilder: (context, dayIndex) {
              final day = editableDays[dayIndex];
              final isExpanded = expandedDays.contains(dayIndex);
              return _DayExpansionCard(
                day: day,
                dayIndex: dayIndex,
                isExpanded: isExpanded,
                repsControllers: repsControllers,
                onToggle: () => onToggleDay(dayIndex),
                onIncrementSets: (ei) => onIncrementSets(dayIndex, ei),
                onDecrementSets: (ei) => onDecrementSets(dayIndex, ei),
                onUpdateRpe: (ei, rpe) => onUpdateRpe(dayIndex, ei, rpe),
              );
            },
          ),
        ),
        // Assign button
        _AssignButton(isAssigning: isAssigning, onAssign: onAssign),
      ],
    );
  }
}

class _DayExpansionCard extends StatelessWidget {
  final TrainingDay day;
  final int dayIndex;
  final bool isExpanded;
  final Map<String, TextEditingController> repsControllers;
  final VoidCallback onToggle;
  final ValueChanged<int> onIncrementSets;
  final ValueChanged<int> onDecrementSets;
  final void Function(int exerciseIndex, int rpe) onUpdateRpe;

  const _DayExpansionCard({
    required this.day,
    required this.dayIndex,
    required this.isExpanded,
    required this.repsControllers,
    required this.onToggle,
    required this.onIncrementSets,
    required this.onDecrementSets,
    required this.onUpdateRpe,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassmorphicCard(
        borderRadius: 14,
        child: Column(
          children: [
            // Day header — tap to expand
            InkWell(
              onTap: onToggle,
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(14),
                  bottom: Radius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: t.brand.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          '${dayIndex + 1}',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: t.brand,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            day.dayName,
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: t.textPrimary,
                            ),
                          ),
                          Text(
                            '${day.exercises.length} exercises',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: t.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(Icons.keyboard_arrow_down_rounded,
                          color: t.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
            // Exercises
            if (isExpanded) ...[
              Divider(height: 1, color: t.divider),
              ...List.generate(day.exercises.length, (ei) {
                final ex = day.exercises[ei];
                final key = '${dayIndex}_$ei';
                return _ExerciseEditRow(
                  exercise: ex,
                  repsController: repsControllers[key],
                  isLast: ei == day.exercises.length - 1,
                  onIncrement: () => onIncrementSets(ei),
                  onDecrement: () => onDecrementSets(ei),
                  onRpeChanged: (rpe) => onUpdateRpe(ei, rpe),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}

class _ExerciseEditRow extends StatelessWidget {
  final Exercise exercise;
  final TextEditingController? repsController;
  final bool isLast;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final ValueChanged<int> onRpeChanged;

  const _ExerciseEditRow({
    required this.exercise,
    required this.repsController,
    required this.isLast,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRpeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;
    return Container(
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(bottom: BorderSide(color: t.divider, width: 1)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Exercise name + equipment
          Row(
            children: [
              Expanded(
                child: Text(
                  exercise.name,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: t.textPrimary,
                  ),
                ),
              ),
              if (exercise.equipment != null)
                Text(
                  exercise.equipment!,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: t.textMuted,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          // Sets stepper + Reps field + Rest label
          Row(
            children: [
              // Sets stepper
              _FieldLabel(label: 'Sets', child: _SetsStepper(
                sets: exercise.sets,
                onIncrement: onIncrement,
                onDecrement: onDecrement,
              )),
              const SizedBox(width: 16),
              // Reps field
              _FieldLabel(
                label: 'Reps',
                child: SizedBox(
                  width: 72,
                  height: 36,
                  child: TextField(
                    controller: repsController,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: t.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      filled: true,
                      fillColor: t.surfaceAlt,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: t.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: t.brand, width: 1.5),
                      ),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Rest
              _FieldLabel(
                label: 'Rest',
                child: Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: t.surfaceAlt,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: t.border),
                  ),
                  child: Center(
                    child: Text(
                      '${exercise.restSeconds}s',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: t.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          // RPE slider (optional)
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                'RPE: ${exercise.rpe ?? '—'}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: t.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: t.brand,
                    inactiveTrackColor: t.surfaceMuted,
                    thumbColor: t.brand,
                    overlayColor: t.brand.withOpacity(0.12),
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 7),
                  ),
                  child: Slider(
                    value: (exercise.rpe ?? 7).toDouble().clamp(1, 10),
                    min: 1,
                    max: 10,
                    divisions: 9,
                    onChanged: (v) => onRpeChanged(v.round()),
                  ),
                ),
              ),
            ],
          ),
          // Coaching cue
          if (exercise.cue != null && exercise.cue!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  Icon(Icons.lightbulb_outline_rounded,
                      size: 12, color: t.warning),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      exercise.cue!,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: t.textMuted,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;
  final Widget child;

  const _FieldLabel({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            color: t.textMuted,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 4),
        child,
      ],
    );
  }
}

class _SetsStepper extends StatelessWidget {
  final int sets;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const _SetsStepper({
    required this.sets,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: t.surfaceAlt,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: t.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepButton(
            icon: Icons.remove_rounded,
            onTap: onDecrement,
            isLeft: true,
          ),
          SizedBox(
            width: 32,
            child: Center(
              child: Text(
                '$sets',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: t.textPrimary,
                ),
              ),
            ),
          ),
          _StepButton(
            icon: Icons.add_rounded,
            onTap: onIncrement,
            isLeft: false,
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isLeft;

  const _StepButton({
    required this.icon,
    required this.onTap,
    required this.isLeft,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 36,
        decoration: BoxDecoration(
          color: t.surfaceMuted,
          borderRadius: isLeft
              ? const BorderRadius.horizontal(left: Radius.circular(8))
              : const BorderRadius.horizontal(right: Radius.circular(8)),
        ),
        child: Icon(icon, size: 16, color: t.textSecondary),
      ),
    );
  }
}

class _AssignButton extends StatelessWidget {
  final bool isAssigning;
  final VoidCallback onAssign;

  const _AssignButton({
    required this.isAssigning,
    required this.onAssign,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: t.background,
        border: Border(top: BorderSide(color: t.divider, width: 1)),
      ),
      child: GestureDetector(
        onTap: isAssigning ? null : onAssign,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 52,
          decoration: BoxDecoration(
            gradient: isAssigning ? null : t.brandGradient,
            color: isAssigning ? t.surfaceMuted : null,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: isAssigning
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation(t.brand),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.assignment_turned_in_outlined,
                          color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Assign Plan',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
