import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants.dart';
import '../../models/client_profile_model.dart';
import '../../models/workout_plan_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/client_provider.dart';
import '../../widgets/glassmorphic_card.dart';
import '../workouts/workouts_screen.dart';

class TrainerAssignWorkoutScreen extends ConsumerStatefulWidget {
  const TrainerAssignWorkoutScreen({super.key});

  @override
  ConsumerState<TrainerAssignWorkoutScreen> createState() => _TrainerAssignWorkoutScreenState();
}

class _TrainerAssignWorkoutScreenState extends ConsumerState<TrainerAssignWorkoutScreen> {
  ClientProfile? _selectedClient;
  WorkoutPlan? _selectedPlan;
  bool _isAssigning = false;

  Future<void> _assignPlan() async {
    if (_selectedClient == null || _selectedPlan == null) return;

    setState(() => _isAssigning = true);

    try {
      final db = ref.read(databaseServiceProvider);
      final currentUser = ref.read(currentUserProvider).value;

      final planData = {
        'gym_id': _selectedPlan!.gymId,
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
        'days': _selectedPlan!.days.map((d) => d.toJson()).toList(),
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      await db.createWorkoutPlan(planData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Successfully assigned ${_selectedPlan!.name} to ${_selectedClient!.fullName}')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error assigning plan: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isAssigning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final clientsAsync = ref.watch(trainerClientsProvider);
    final plansAsync = ref.watch(gymWorkoutPlansProvider);

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.bgDark,
        title: Text(
          'Assign Workout Plan',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: clientsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.red))),
        data: (clients) {
          if (clients.isEmpty) {
            return const Center(
              child: Text(
                'No clients available to assign to.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            );
          }

          return plansAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.red))),
            data: (plans) {
              final activePlans = plans.where((p) => p.isTemplate || p.clientId == null).toList();

              return Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '1. Select Client',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      flex: 1,
                      child: ListView.builder(
                        itemCount: clients.length,
                        itemBuilder: (context, index) {
                          final client = clients[index];
                          final isSelected = _selectedClient?.id == client.id;
                          return GestureDetector(
                            onTap: () => setState(() => _selectedClient = client),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected ? AppColors.primary : AppColors.glassBorder,
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: GlassmorphicCard(
                                child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: AppColors.bgElevated,
                                      child: Text(
                                        client.fullName?.isNotEmpty == true
                                            ? client.fullName![0].toUpperCase()
                                            : 'C',
                                        style: const TextStyle(color: Colors.white),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      client.fullName ?? 'Unknown',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const Spacer(),
                                    if (isSelected) const Icon(Icons.check_circle, color: AppColors.primary),
                                  ],
                                ),
                              ),
                            ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      '2. Select Plan',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      flex: 2,
                      child: activePlans.isEmpty
                          ? const Center(
                              child: Text(
                                'No workout templates found. Create one first.',
                                style: TextStyle(color: AppColors.textSecondary),
                              ),
                            )
                          : ListView.builder(
                              itemCount: activePlans.length,
                              itemBuilder: (context, index) {
                                final plan = activePlans[index];
                                final isSelected = _selectedPlan?.id == plan.id;
                                return GestureDetector(
                                  onTap: () => setState(() => _selectedPlan = plan),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: isSelected ? AppColors.primary : AppColors.glassBorder,
                                        width: isSelected ? 2 : 1,
                                      ),
                                    ),
                                    child: GlassmorphicCard(
                                      child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  plan.name,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                              ),
                                              if (isSelected) const Icon(Icons.check_circle, color: AppColors.primary),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${plan.durationWeeks} weeks • ${plan.athleteType} • ${plan.goal}',
                                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  ),
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        disabledBackgroundColor: AppColors.bgElevated,
                      ),
                      onPressed: _selectedClient == null || _selectedPlan == null || _isAssigning
                          ? null
                          : _assignPlan,
                      child: _isAssigning
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text(
                              'Assign Workout Plan',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
