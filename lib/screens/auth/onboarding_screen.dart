import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/enums.dart';
import '../../core/extensions.dart';
import '../../providers/auth_provider.dart';
import '../../providers/gym_provider.dart';
import '../../widgets/fit_auth_scaffold.dart';
import '../../widgets/glassmorphic_card.dart';

/// Multi-step onboarding with goals, metrics, and gym workspace setup.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _gymFormKey = GlobalKey<FormState>();
  final _gymNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();

  int _step = 0;
  bool _isLoading = false;
  FitnessGoal _goal = FitnessGoal.generalFitness;

  @override
  void dispose() {
    _gymNameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  Future<void> _createGym() async {
    if (!_gymFormKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final userId = ref.read(currentUserProvider).value?.id ??
          Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('Not authenticated. Please sign in again.');
      }

      final db = ref.read(databaseServiceProvider);
      final gym = await db.createGym(
        name: _gymNameController.text.trim(),
        ownerId: userId,
        address: _addressController.text.trim(),
        phone: _phoneController.text.trim(),
      );

      ref.read(selectedGymProvider.notifier).state = gym;
      if (!mounted) return;
      context.go('/dashboard');
    } catch (error) {
      if (!mounted) return;
      context.showSnackBar('Error creating gym: $error', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.fitTheme;
    final pages = [
      _GoalStep(
        selectedGoal: _goal,
        onGoalSelected: (goal) => setState(() => _goal = goal),
      ),
      _MetricsStep(
        weightController: _weightController,
        heightController: _heightController,
      ),
      _GymStep(
        formKey: _gymFormKey,
        gymNameController: _gymNameController,
        addressController: _addressController,
        phoneController: _phoneController,
      ),
    ];

    return FitAuthScaffold(
      title: _step == 0
          ? 'Set your direction'
          : _step == 1
              ? 'Capture your baseline'
              : 'Create your workspace',
      subtitle: _step == 0
          ? 'Choose the primary outcome you want FitNexora to optimize for.'
          : _step == 1
              ? 'We use these numbers to personalize recommendations and UI states.'
              : 'Finish with the gym details we need to provision your dashboard.',
      heroIcon: _step == 2
          ? Icons.storefront_rounded
          : _step == 1
              ? Icons.straighten_rounded
              : Icons.flag_rounded,
      heroLabel: 'Step ${_step + 1} of 3',
      showBack: _step > 0,
      onBack: () => setState(() => _step--),
      child: Column(
        children: [
          Row(
            children: List.generate(
              3,
              (index) => Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsets.only(right: index == 2 ? 0 : 8),
                  decoration: BoxDecoration(
                    color: index <= _step ? colors.brand : colors.ringTrack,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          pages[_step],
          const SizedBox(height: 20),
          SizedBox(
            height: 54,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : _step == 2
                      ? _createGym
                      : () => setState(() => _step++),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(_step == 2 ? 'Launch dashboard' : 'Continue'),
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalStep extends StatelessWidget {
  final FitnessGoal selectedGoal;
  final ValueChanged<FitnessGoal> onGoalSelected;

  const _GoalStep({
    required this.selectedGoal,
    required this.onGoalSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.fitTheme;
    return GlassmorphicCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: FitnessGoal.values.map((goal) {
            final isSelected = goal == selectedGoal;
            return InkWell(
              onTap: () => onGoalSelected(goal),
              borderRadius: BorderRadius.circular(18),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 180,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected
                      ? colors.brand.withValues(alpha: 0.12)
                      : colors.surfaceAlt,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isSelected ? colors.brand : colors.border,
                  ),
                ),
                child: Text(
                  goal.label,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: isSelected ? colors.brand : colors.textPrimary,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _MetricsStep extends StatelessWidget {
  final TextEditingController weightController;
  final TextEditingController heightController;

  const _MetricsStep({
    required this.weightController,
    required this.heightController,
  });

  @override
  Widget build(BuildContext context) {
    return GlassmorphicCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextFormField(
              controller: weightController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Current weight (kg)',
                prefixIcon: Icon(Icons.monitor_weight_outlined),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: heightController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Height (cm)',
                prefixIcon: Icon(Icons.height_rounded),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GymStep extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController gymNameController;
  final TextEditingController addressController;
  final TextEditingController phoneController;

  const _GymStep({
    required this.formKey,
    required this.gymNameController,
    required this.addressController,
    required this.phoneController,
  });

  @override
  Widget build(BuildContext context) {
    return GlassmorphicCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: formKey,
          child: Column(
            children: [
              TextFormField(
                controller: gymNameController,
                decoration: const InputDecoration(
                  labelText: 'Gym name',
                  prefixIcon: Icon(Icons.storefront_outlined),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Gym name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: addressController,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Contact number',
                  prefixIcon: Icon(Icons.call_outlined),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
