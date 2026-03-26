// lib/screens/trainer/trainer_assign_diet_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/diet_templates.dart';
import '../../core/extensions.dart';
import '../../models/client_profile_model.dart';
import '../../models/diet_plan_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/client_provider.dart';
import '../../providers/gym_provider.dart';
import '../../widgets/glassmorphic_card.dart';

/// 3-step wizard for trainers to assign diet plans to their clients.
/// Mirrors the workout assignment flow.
class TrainerAssignDietScreen extends ConsumerStatefulWidget {
  const TrainerAssignDietScreen({super.key});

  @override
  ConsumerState<TrainerAssignDietScreen> createState() =>
      _TrainerAssignDietScreenState();
}

class _TrainerAssignDietScreenState
    extends ConsumerState<TrainerAssignDietScreen> {
  // 0 = select client, 1 = select template, 2 = preview & customize
  int _step = 0;

  ClientProfile? _selectedClient;
  DietPlan? _selectedPlan;
  String _selectedGoal = 'All';
  bool _isAssigning = false;

  // Deep-copy of selected plan's meals for inline editing
  List<Meal> _editableMeals = [];

  // Track which meals are expanded in step 2
  final Set<int> _expandedMeals = {};

  // Editable macro targets
  int _targetCalories = 2000;
  int _targetProtein = 150;
  int _targetCarbs = 200;
  int _targetFat = 65;

  // Available goal filters
  final List<String> _goalFilters = [
    'All',
    'muscle_gain',
    'fat_loss',
    'maintenance',
    'recomp',
  ];

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  void _selectTemplate(DietPlan plan) {
    // Deep-copy meals so edits don't mutate the source template.
    final meals = plan.meals
        .map((m) => Meal(
              name: m.name,
              timing: m.timing,
              orderIndex: m.orderIndex,
              notes: m.notes,
              foods: m.foods
                  .map((f) => FoodItem(
                        name: f.name,
                        quantity: f.quantity,
                        protein: f.protein,
                        carbs: f.carbs,
                        fat: f.fat,
                        calories: f.calories,
                        isIndian: f.isIndian,
                      ))
                  .toList(),
            ))
        .toList();

    setState(() {
      _selectedPlan = plan;
      _editableMeals = meals;
      _targetCalories = plan.targetCalories;
      _targetProtein = plan.targetProtein;
      _targetCarbs = plan.targetCarbs;
      _targetFat = plan.targetFat;
      _expandedMeals.clear();
      _step = 2;
    });
  }

  int get _actualCalories =>
      _editableMeals.fold<int>(0, (sum, m) => sum + m.totalCalories);

  int get _actualProtein =>
      _editableMeals.fold<int>(0, (sum, m) => sum + m.totalProtein);

  int get _actualCarbs =>
      _editableMeals.fold<int>(0, (sum, m) => sum + m.totalCarbs);

  int get _actualFat =>
      _editableMeals.fold<int>(0, (sum, m) => sum + m.totalFat);

  // ---------------------------------------------------------------------------
  // Assignment
  // ---------------------------------------------------------------------------

  Future<void> _assignPlan() async {
    if (_selectedClient == null || _selectedPlan == null) return;

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
        'target_calories': _targetCalories,
        'target_protein': _targetProtein,
        'target_carbs': _targetCarbs,
        'target_fat': _targetFat,
        'hydration_liters': _selectedPlan!.hydrationLiters,
        'status': 'active',
        'is_template': false,
        'meals': _editableMeals.map((m) => m.toJson()).toList(),
        'start_date': DateTime.now().toIso8601String().split('T').first,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      await db.createDietPlan(planData);

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
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;
    final clientsAsync = ref.watch(trainerClientsProvider);

    return Scaffold(
      backgroundColor: t.background,
      appBar: AppBar(
        backgroundColor: t.surface,
        title: Text(
          _step == 0
              ? 'Select Client'
              : _step == 1
                  ? 'Select Diet Plan'
                  : 'Review & Assign',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            color: t.textPrimary,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: t.textPrimary),
          onPressed: () {
            if (_step > 0) {
              setState(() => _step--);
            } else if (context.canPop()) {
              context.pop();
            } else {
              context.go('/trainer');
            }
          },
        ),
        actions: [
          if (_step > 0)
            TextButton(
              onPressed: () => setState(() {
                _step = 0;
                _selectedClient = null;
                _selectedPlan = null;
              }),
              child: Text('Reset', style: TextStyle(color: t.brand)),
            ),
        ],
      ),
      body: _step == 0
          ? _buildClientSelection(clientsAsync, t)
          : _step == 1
              ? _buildTemplateSelection(t)
              : _buildReviewStep(t),
      bottomNavigationBar: _step == 2 ? _buildAssignButton(t) : null,
    );
  }

  // ---------------------------------------------------------------------------
  // Step 0: Client Selection
  // ---------------------------------------------------------------------------

  Widget _buildClientSelection(
    AsyncValue<List<ClientProfile>> clientsAsync,
    dynamic t,
  ) {
    return clientsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text('Error loading clients: $e',
            style: TextStyle(color: t.danger)),
      ),
      data: (clients) {
        if (clients.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline_rounded,
                    size: 64, color: t.textMuted),
                const SizedBox(height: 16),
                Text(
                  'No clients assigned to you',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: t.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: clients.length,
          itemBuilder: (context, index) {
            final client = clients[index];
            final isSelected = _selectedClient?.id == client.id;

            return GlassmorphicCard(
              borderRadius: 16,
              onTap: () {
                setState(() {
                  _selectedClient = client;
                  _step = 1;
                });
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected
                      ? t.brand.withOpacity(0.15)
                      : t.surfaceAlt.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? t.brand : t.border.withOpacity(0.3),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: t.brand.withOpacity(0.2),
                      child: Text(
                        (client.fullName ?? 'C')[0].toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: t.brand,
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
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: t.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Goal: ${_formatGoal(client.goal.value)}',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: t.textSecondary,
                            ),
                          ),
                          if (client.currentPlanName != null)
                            Text(
                              'Current: ${client.currentPlanName}',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: t.textMuted,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: t.textMuted,
                    ),
                  ],
                ),
              ),
            ).animate(delay: (index * 50).ms).fadeIn().slideX(begin: 0.05);
          },
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Step 1: Template Selection
  // ---------------------------------------------------------------------------

  Widget _buildTemplateSelection(dynamic t) {
    final templates = kDietTemplates.where((p) {
      if (_selectedGoal == 'All') return true;
      return p.goal == _selectedGoal;
    }).toList();

    return Column(
      children: [
        // Goal filter chips
        Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _goalFilters.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final goal = _goalFilters[index];
              final isSelected = _selectedGoal == goal;
              return FilterChip(
                label: Text(_formatGoal(goal)),
                selected: isSelected,
                onSelected: (_) => setState(() => _selectedGoal = goal),
                backgroundColor: t.surfaceAlt,
                selectedColor: t.brand.withOpacity(0.2),
                labelStyle: GoogleFonts.inter(
                  color: isSelected ? t.brand : t.textSecondary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: isSelected ? t.brand : t.border.withOpacity(0.3),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        // Template list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: templates.length,
            itemBuilder: (context, index) {
              final template = templates[index];
              return _buildTemplateCard(template, t, index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTemplateCard(DietPlan template, dynamic t, int index) {
    return GlassmorphicCard(
      borderRadius: 16,
      onTap: () => _selectTemplate(template),
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: t.surfaceAlt.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: t.border.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: t.brand.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child:
                      Icon(Icons.restaurant_rounded, color: t.brand, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        template.name,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: t.textPrimary,
                        ),
                      ),
                      Text(
                        _formatGoal(template.goal),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: t.brand,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: t.textMuted),
              ],
            ),
            const SizedBox(height: 12),
            // Macro summary
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _MacroChip(
                  label: 'Calories',
                  value: '${template.targetCalories}',
                  color: t.brand,
                ),
                _MacroChip(
                  label: 'Protein',
                  value: '${template.targetProtein}g',
                  color: t.accent,
                ),
                _MacroChip(
                  label: 'Carbs',
                  value: '${template.targetCarbs}g',
                  color: t.info,
                ),
                _MacroChip(
                  label: 'Fat',
                  value: '${template.targetFat}g',
                  color: t.warning,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${template.meals.length} meals • ${template.hydrationLiters}L water/day',
              style: GoogleFonts.inter(fontSize: 12, color: t.textMuted),
            ),
          ],
        ),
      ),
    ).animate(delay: (index * 50).ms).fadeIn().slideY(begin: 0.05);
  }

  // ---------------------------------------------------------------------------
  // Step 2: Review & Customize
  // ---------------------------------------------------------------------------

  Widget _buildReviewStep(dynamic t) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Client info
          _buildInfoCard(
            t,
            title: 'Assigning To',
            icon: Icons.person_rounded,
            content: _selectedClient?.fullName ?? 'Unknown',
            subtitle: 'Goal: ${_formatGoal(_selectedClient?.goal.value ?? '')}',
          ),
          const SizedBox(height: 12),
          // Plan info
          _buildInfoCard(
            t,
            title: 'Diet Plan',
            icon: Icons.restaurant_menu_rounded,
            content: _selectedPlan?.name ?? 'Unknown',
            subtitle: _formatGoal(_selectedPlan?.goal ?? ''),
          ),
          const SizedBox(height: 20),

          // Macro targets (editable)
          Text(
            'MACRO TARGETS',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: t.textMuted,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          _buildMacroEditor(t),
          const SizedBox(height: 20),

          // Actual vs Target comparison
          _buildMacroComparison(t),
          const SizedBox(height: 20),

          // Meals preview
          Text(
            'MEALS (${_editableMeals.length})',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: t.textMuted,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          ...List.generate(_editableMeals.length, (index) {
            return _buildMealCard(index, t);
          }),
          const SizedBox(height: 80), // Space for bottom button
        ],
      ),
    );
  }

  Widget _buildInfoCard(
    dynamic t, {
    required String title,
    required IconData icon,
    required String content,
    required String subtitle,
  }) {
    return GlassmorphicCard(
      borderRadius: 14,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: t.surfaceAlt.withOpacity(0.5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: t.border.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: t.brand.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: t.brand, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: t.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    content,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: t.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: t.brand,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMacroEditor(dynamic t) {
    return GlassmorphicCard(
      borderRadius: 14,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: t.surfaceAlt.withOpacity(0.5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: t.border.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            _buildMacroSlider(
              t,
              label: 'Calories',
              value: _targetCalories,
              min: 1200,
              max: 5000,
              unit: 'kcal',
              color: t.brand,
              onChanged: (v) => setState(() => _targetCalories = v.round()),
            ),
            const SizedBox(height: 16),
            _buildMacroSlider(
              t,
              label: 'Protein',
              value: _targetProtein,
              min: 50,
              max: 400,
              unit: 'g',
              color: t.accent,
              onChanged: (v) => setState(() => _targetProtein = v.round()),
            ),
            const SizedBox(height: 16),
            _buildMacroSlider(
              t,
              label: 'Carbs',
              value: _targetCarbs,
              min: 50,
              max: 600,
              unit: 'g',
              color: t.info,
              onChanged: (v) => setState(() => _targetCarbs = v.round()),
            ),
            const SizedBox(height: 16),
            _buildMacroSlider(
              t,
              label: 'Fat',
              value: _targetFat,
              min: 20,
              max: 200,
              unit: 'g',
              color: t.warning,
              onChanged: (v) => setState(() => _targetFat = v.round()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMacroSlider(
    dynamic t, {
    required String label,
    required int value,
    required double min,
    required double max,
    required String unit,
    required Color color,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: t.textSecondary,
              ),
            ),
            Text(
              '$value $unit',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: color,
            inactiveTrackColor: color.withOpacity(0.2),
            thumbColor: color,
            overlayColor: color.withOpacity(0.1),
          ),
          child: Slider(
            value: value.toDouble(),
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildMacroComparison(dynamic t) {
    return GlassmorphicCard(
      borderRadius: 14,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: t.surfaceAlt.withOpacity(0.5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: t.border.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Actual vs Target',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: t.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildCompareItem(
                    t, 'Calories', _actualCalories, _targetCalories, 'kcal'),
                _buildCompareItem(
                    t, 'Protein', _actualProtein, _targetProtein, 'g'),
                _buildCompareItem(t, 'Carbs', _actualCarbs, _targetCarbs, 'g'),
                _buildCompareItem(t, 'Fat', _actualFat, _targetFat, 'g'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompareItem(
      dynamic t, String label, int actual, int target, String unit) {
    final diff = actual - target;
    final isOver = diff > 0;
    final color = diff.abs() < target * 0.05
        ? t.accent
        : isOver
            ? t.warning
            : t.info;

    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 11, color: t.textMuted),
        ),
        const SizedBox(height: 4),
        Text(
          '$actual',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: t.textPrimary,
          ),
        ),
        Text(
          '${diff > 0 ? '+' : ''}$diff$unit',
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildMealCard(int index, dynamic t) {
    final meal = _editableMeals[index];
    final isExpanded = _expandedMeals.contains(index);

    return GlassmorphicCard(
      borderRadius: 14,
      onTap: () {
        setState(() {
          if (isExpanded) {
            _expandedMeals.remove(index);
          } else {
            _expandedMeals.add(index);
          }
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: t.surfaceAlt.withOpacity(0.5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: t.border.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: t.brand.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${index + 1}',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: t.brand,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        meal.name,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: t.textPrimary,
                        ),
                      ),
                      Text(
                        meal.timing,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: t.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${meal.totalCalories} kcal',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: t.brand,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  isExpanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: t.textMuted,
                ),
              ],
            ),
            if (isExpanded) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              ...meal.foods.map((food) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                food.name,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: t.textPrimary,
                                ),
                              ),
                              Text(
                                food.quantity,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: t.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${food.calories} kcal',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: t.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  )),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _MiniMacro(
                      label: 'P', value: meal.totalProtein, color: t.accent),
                  _MiniMacro(label: 'C', value: meal.totalCarbs, color: t.info),
                  _MiniMacro(
                      label: 'F', value: meal.totalFat, color: t.warning),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Bottom Button
  // ---------------------------------------------------------------------------

  Widget _buildAssignButton(dynamic t) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(
        color: t.surface,
        border: Border(top: BorderSide(color: t.border.withOpacity(0.3))),
      ),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: _isAssigning ? null : _assignPlan,
          style: ElevatedButton.styleFrom(
            backgroundColor: t.brand,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: _isAssigning
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  'Assign Diet Plan',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Utilities
  // ---------------------------------------------------------------------------

  String _formatGoal(String goal) {
    return goal
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }
}

// ─── Supporting Widgets ─────────────────────────────────────────────────────

class _MacroChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MacroChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            color: context.fitTheme.textMuted,
          ),
        ),
      ],
    );
  }
}

class _MiniMacro extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _MiniMacro({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
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
        Text(
          '$label: ${value}g',
          style: GoogleFonts.inter(
            fontSize: 11,
            color: context.fitTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}
