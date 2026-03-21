import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants.dart';
import '../../models/workout_plan_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/gym_provider.dart';
import '../../providers/member_provider.dart';
import '../../data/workout_templates.dart';

class MemberAddWorkoutPlanScreen extends ConsumerStatefulWidget {
  const MemberAddWorkoutPlanScreen({super.key});

  @override
  ConsumerState<MemberAddWorkoutPlanScreen> createState() => _MemberAddWorkoutPlanScreenState();
}

class _MemberAddWorkoutPlanScreenState extends ConsumerState<MemberAddWorkoutPlanScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedGoal = 'general_fitness';
  String _selectedAthleteType = 'General';
  int _durationWeeks = 8;
  
  final List<TrainingDay> _days = [];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _addDay() {
    setState(() {
      _days.add(TrainingDay(
        dayName: 'Day ${_days.length + 1}',
        dayIndex: _days.length,
        exercises: const [],
      ));
    });
  }

  void _removeDay(int index) {
    setState(() {
      _days.removeAt(index);
      // Re-index days
      for (int i = 0; i < _days.length; i++) {
        final day = _days[i];
        _days[i] = TrainingDay(
          dayName: day.dayName.startsWith('Day ') ? 'Day ${i + 1}' : day.dayName,
          dayIndex: i,
          exercises: day.exercises,
          muscleGroup: day.muscleGroup,
          notes: day.notes,
        );
      }
    });
  }

  void _addExercise(int dayIndex) {
    setState(() {
      final day = _days[dayIndex];
      final newExercises = List<Exercise>.from(day.exercises);
      newExercises.add(Exercise(
        name: 'New Exercise',
        sets: 3,
        reps: '10',
        orderIndex: day.exercises.length,
      ));
      
      _days[dayIndex] = TrainingDay(
        dayName: day.dayName,
        dayIndex: day.dayIndex,
        exercises: newExercises,
        muscleGroup: day.muscleGroup,
        notes: day.notes,
      );
    });
  }

  void _removeExercise(int dayIndex, int exerciseIndex) {
    setState(() {
      final day = _days[dayIndex];
      final newExercises = List<Exercise>.from(day.exercises);
      newExercises.removeAt(exerciseIndex);
      
      // Re-order exercises
      for (int i = 0; i < newExercises.length; i++) {
        final ex = newExercises[i];
        newExercises[i] = Exercise(
          name: ex.name,
          sets: ex.sets,
          reps: ex.reps,
          restSeconds: ex.restSeconds,
          setTime: ex.setTime,
          rpe: ex.rpe,
          supersetGroupId: ex.supersetGroupId,
          intensity: ex.intensity,
          tempo: ex.tempo,
          equipment: ex.equipment,
          cue: ex.cue,
          substitute: ex.substitute,
          orderIndex: i,
        );
      }

      _days[dayIndex] = TrainingDay(
        dayName: day.dayName,
        dayIndex: day.dayIndex,
        exercises: newExercises,
        muscleGroup: day.muscleGroup,
        notes: day.notes,
      );
    });
  }

  void _updateExercise(int dayIndex, int exerciseIndex, Exercise updatedExercise) {
    setState(() {
      final day = _days[dayIndex];
      final newExercises = List<Exercise>.from(day.exercises);
      newExercises[exerciseIndex] = updatedExercise;
      
      _days[dayIndex] = TrainingDay(
        dayName: day.dayName,
        dayIndex: day.dayIndex,
        exercises: newExercises,
        muscleGroup: day.muscleGroup,
        notes: day.notes,
      );
    });
  }

  Future<void> _savePlan() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_days.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one training day')),
      );
      return;
    }

    final user = ref.read(currentUserProvider).value;
    final gym = ref.read(selectedGymProvider);
    
    if (user == null || gym == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: User or Gym not identified')),
      );
      return;
    }

    final db = ref.read(databaseServiceProvider);
    
    final planData = {
      'gym_id': gym.id,
      'client_id': user.id,
      'name': _nameController.text.trim(),
      'description': _descriptionController.text.trim(),
      'goal': _selectedGoal,
      'athlete_type': _selectedAthleteType,
      'duration_weeks': _durationWeeks,
      'current_week': 1,
      'phase': 'Initial Phase',
      'status': 'active',
      'is_template': false,
      'days': _days.map((d) => d.toJson()).toList(),
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };

    try {
      await db.createWorkoutPlan(planData);
      ref.invalidate(memberWorkoutPlanProvider);
      
      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Workout plan created successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating plan: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStepHeader('1', 'Basic Information'),
                    const SizedBox(height: 20),
                    _buildTextField(
                      controller: _nameController,
                      label: 'Plan Name',
                      hint: 'e.g., Summer Shred, Strength Alpha',
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _descriptionController,
                      label: 'Description (Optional)',
                      hint: 'What is the focus of this plan?',
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),
                    _buildStepHeader('2', 'Target & Duration'),
                    const SizedBox(height: 20),
                    _buildDropdown(
                      label: 'Fitness Goal',
                      value: _selectedGoal,
                      items: const [
                        DropdownMenuItem(value: 'fat_loss', child: Text('Fat Loss')),
                        DropdownMenuItem(value: 'muscle_gain', child: Text('Muscle Gain')),
                        DropdownMenuItem(value: 'strength', child: Text('Strength Build')),
                        DropdownMenuItem(value: 'endurance', child: Text('Endurance')),
                        DropdownMenuItem(value: 'general_fitness', child: Text('General Fitness')),
                      ],
                      onChanged: (v) => setState(() => _selectedGoal = v!),
                    ),
                    const SizedBox(height: 16),
                    _buildDropdown(
                      label: 'Athlete Discipline',
                      value: _selectedAthleteType,
                      items: const [
                        DropdownMenuItem(value: 'General', child: Text('General Fitness')),
                        DropdownMenuItem(value: 'Powerlifting', child: Text('Powerlifting')),
                        DropdownMenuItem(value: 'Bodybuilding', child: Text('Bodybuilding')),
                        DropdownMenuItem(value: 'Arm Wrestling', child: Text('Arm Wrestling')),
                        DropdownMenuItem(value: 'Olympic Weightlifting', child: Text('Olympic Weightlifting')),
                      ],
                      onChanged: (v) => setState(() => _selectedAthleteType = v!),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          _days.clear();
                          _days.addAll(WorkoutTemplates.getTemplate(_selectedAthleteType));
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('$_selectedAthleteType template loaded!')),
                        );
                      },
                      icon: const Icon(Icons.download_rounded, size: 16, color: AppColors.primaryLight),
                      label: const Text('Load Pre-filled Template', style: TextStyle(color: AppColors.primaryLight)),
                    ),
                    const SizedBox(height: 16),
                    _buildDurationSelector(),
                    const SizedBox(height: 32),
                    _buildStepHeader('3', 'Training Split'),
                    const SizedBox(height: 8),
                    Text(
                      'Define your training days and exercises.',
                      style: GoogleFonts.inter(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ...List.generate(_days.length, (idx) => _buildDayCard(idx)),
                    const SizedBox(height: 16),
                    _buildAddDayButton(),
                    const SizedBox(height: 100), // Bottom padding for FAB
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _savePlan,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.save_rounded, color: Colors.white),
        label: Text(
          'Save Workout Plan',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ).animate().scale(delay: 400.ms, curve: Curves.easeOutBack),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      backgroundColor: AppColors.bgDark,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => context.pop(),
      ),
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'Create Workout Plan',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary.withOpacity(0.2),
                AppColors.bgDark,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepHeader(String number, String title) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(color: Colors.white),
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: AppColors.textMuted.withOpacity(0.5)),
            filled: true,
            fillColor: AppColors.bgInput,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            errorStyle: const TextStyle(color: AppColors.error),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.bgInput,
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              items: items,
              onChanged: onChanged,
              dropdownColor: AppColors.bgElevated,
              icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textSecondary),
              style: const TextStyle(color: Colors.white),
              isExpanded: true,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDurationSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Plan Duration (Weeks)',
          style: GoogleFonts.inter(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _durationOption(4),
            const SizedBox(width: 8),
            _durationOption(8),
            const SizedBox(width: 8),
            _durationOption(12),
            const SizedBox(width: 8),
            _durationOption(16),
          ],
        ),
      ],
    );
  }

  Widget _durationOption(int weeks) {
    bool isSelected = _durationWeeks == weeks;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _durationWeeks = weeks),
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary.withOpacity(0.2) : AppColors.bgInput,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.primary : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Center(
            child: Text(
              '$weeks',
              style: GoogleFonts.inter(
                color: isSelected ? AppColors.primaryLight : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDayCard(int dayIdx) {
    final day = _days[dayIdx];
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _buildDayHeader(dayIdx, day),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                ...List.generate(day.exercises.length, (exIdx) => _buildExerciseRow(dayIdx, exIdx)),
                const SizedBox(height: 12),
                _buildAddExerciseButton(dayIdx),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: (dayIdx * 100).ms).slideX(begin: 0.1);
  }

  Widget _buildDayHeader(int dayIdx, TrainingDay day) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.bgElevated.withOpacity(0.5),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              initialValue: day.dayName,
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 16,
              ),
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: 'Day name...',
                hintStyle: TextStyle(color: Colors.grey),
              ),
              onChanged: (v) {
                _days[dayIdx] = TrainingDay(
                  dayName: v,
                  dayIndex: day.dayIndex,
                  exercises: day.exercises,
                  muscleGroup: day.muscleGroup,
                  notes: day.notes,
                );
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
            onPressed: () => _removeDay(dayIdx),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseRow(int dayIdx, int exIdx) {
    final exercise = _days[dayIdx].exercises[exIdx];
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgInput.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 3,
                child: _buildInlineField(
                  hint: 'Exercise name',
                  initialValue: exercise.name,
                  onChanged: (v) => _updateExercise(dayIdx, exIdx, Exercise(
                    name: v, sets: exercise.sets, reps: exercise.reps, setTime: exercise.setTime, rpe: exercise.rpe, tempo: exercise.tempo, intensity: exercise.intensity, supersetGroupId: exercise.supersetGroupId, orderIndex: exercise.orderIndex,
                  )),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildInlineField(
                  hint: 'Sets',
                  initialValue: exercise.sets.toString(),
                  keyboardType: TextInputType.number,
                  onChanged: (v) => _updateExercise(dayIdx, exIdx, Exercise(
                    name: exercise.name, sets: int.tryParse(v) ?? 3, reps: exercise.reps, setTime: exercise.setTime, rpe: exercise.rpe, tempo: exercise.tempo, intensity: exercise.intensity, supersetGroupId: exercise.supersetGroupId, orderIndex: exercise.orderIndex,
                  )),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildInlineField(
                  hint: 'Reps',
                  initialValue: exercise.reps,
                  onChanged: (v) => _updateExercise(dayIdx, exIdx, Exercise(
                    name: exercise.name, sets: exercise.sets, reps: v, setTime: exercise.setTime, rpe: exercise.rpe, tempo: exercise.tempo, intensity: exercise.intensity, supersetGroupId: exercise.supersetGroupId, orderIndex: exercise.orderIndex,
                  )),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: AppColors.error, size: 20),
                onPressed: () => _removeExercise(dayIdx, exIdx),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildInlineField(
                  hint: 'RPE (1-10)',
                  initialValue: exercise.rpe?.toString() ?? '',
                  keyboardType: TextInputType.number,
                  onChanged: (v) => _updateExercise(dayIdx, exIdx, Exercise(
                    name: exercise.name, sets: exercise.sets, reps: exercise.reps, setTime: exercise.setTime, rpe: int.tryParse(v), tempo: exercise.tempo, intensity: exercise.intensity, supersetGroupId: exercise.supersetGroupId, orderIndex: exercise.orderIndex,
                  )),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildInlineField(
                  hint: 'Tempo (3110)',
                  initialValue: exercise.tempo ?? '',
                  onChanged: (v) => _updateExercise(dayIdx, exIdx, Exercise(
                    name: exercise.name, sets: exercise.sets, reps: exercise.reps, setTime: exercise.setTime, rpe: exercise.rpe, tempo: v, intensity: exercise.intensity, supersetGroupId: exercise.supersetGroupId, orderIndex: exercise.orderIndex,
                  )),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildInlineField(
                  hint: 'Time/Dur',
                  initialValue: exercise.setTime ?? '',
                  onChanged: (v) => _updateExercise(dayIdx, exIdx, Exercise(
                    name: exercise.name, sets: exercise.sets, reps: exercise.reps, setTime: v, rpe: exercise.rpe, tempo: exercise.tempo, intensity: exercise.intensity, supersetGroupId: exercise.supersetGroupId, orderIndex: exercise.orderIndex,
                  )),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildInlineField(
                  hint: 'Superset Grp (e.g. A)',
                  initialValue: exercise.supersetGroupId ?? '',
                  onChanged: (v) => _updateExercise(dayIdx, exIdx, Exercise(
                    name: exercise.name, sets: exercise.sets, reps: exercise.reps, setTime: exercise.setTime, rpe: exercise.rpe, tempo: exercise.tempo, intensity: exercise.intensity, supersetGroupId: v, orderIndex: exercise.orderIndex,
                  )),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildInlineField(
                  hint: 'Intensity (High/Mid/Low)',
                  initialValue: exercise.intensity ?? '',
                  onChanged: (v) => _updateExercise(dayIdx, exIdx, Exercise(
                    name: exercise.name, sets: exercise.sets, reps: exercise.reps, setTime: exercise.setTime, rpe: exercise.rpe, tempo: exercise.tempo, intensity: v, supersetGroupId: exercise.supersetGroupId, orderIndex: exercise.orderIndex,
                  )),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildInlineField({
    required String hint,
    required String initialValue,
    required void Function(String) onChanged,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      initialValue: initialValue,
      style: const TextStyle(color: Colors.white, fontSize: 13),
      keyboardType: keyboardType,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
        filled: true,
        fillColor: AppColors.bgInput,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildAddExerciseButton(int dayIdx) {
    return TextButton.icon(
      onPressed: () => _addExercise(dayIdx),
      icon: const Icon(Icons.add, size: 18, color: AppColors.primaryLight),
      label: Text(
        'Add Exercise',
        style: GoogleFonts.inter(
          color: AppColors.primaryLight,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildAddDayButton() {
    return InkWell(
      onTap: _addDay,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 1.5),
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.calendar_today_rounded, color: AppColors.primaryLight, size: 20),
              const SizedBox(width: 12),
              Text(
                'Add Training Day',
                style: GoogleFonts.inter(
                  color: AppColors.primaryLight,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
