import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/enums.dart';
import '../../core/extensions.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/gym_provider.dart';
import '../../widgets/glassmorphic_card.dart';

/// Multi-step onboarding: goals → metrics → experience → summary.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  // Gym workspace controllers (step 3 / completion)
  final _gymNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _phoneController = TextEditingController();

  // Metrics controllers (step 2)
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _ageController = TextEditingController();

  int _step = 0;
  bool _isLoading = false;

  // Step 1 state
  FitnessGoal _goal = FitnessGoal.muscleGain;

  // Step 2 state
  String _gender = 'Male';
  bool _useMetricHeight = true; // cm vs ft
  bool _useMetricWeight = true; // kg vs lbs

  // Step 3 state
  TrainingLevel _level = TrainingLevel.beginner;

  static const int _totalSteps = 4;

  @override
  void dispose() {
    _gymNameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _phoneController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _createGym() async {
    setState(() => _isLoading = true);
    try {
      final userId = ref.read(currentUserProvider).value?.id ??
          Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) throw Exception('Not authenticated. Please sign in again.');

      final db = ref.read(databaseServiceProvider);
      final gym = await db.createGym(
        name: _gymNameController.text.trim().isEmpty
            ? 'My Gym'
            : _gymNameController.text.trim(),
        ownerId: userId,
        address: _addressController.text.trim(),
        city: _cityController.text.trim(),
        phone: _phoneController.text.trim(),
      );

      ref.read(selectedGymProvider.notifier).state = gym;
      if (!mounted) return;
      context.go('/');
    } catch (error) {
      if (!mounted) return;
      context.showSnackBar('Error: $error', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _advance() {
    if (_step < _totalSteps - 1) {
      setState(() => _step++);
    } else {
      _createGym();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;

    return Scaffold(
      backgroundColor: t.background,
      body: Stack(
        children: [
          // Background glow orbs
          Positioned(
            top: -120,
            right: -100,
            child: _GlowOrb(color: t.brand.withOpacity(0.15), size: 300),
          ),
          Positioned(
            bottom: -140,
            left: -100,
            child: _GlowOrb(color: t.accent.withOpacity(0.10), size: 320),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(t),
                _buildProgressBar(t),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: _buildStepContent(t),
                  ),
                ),
                _buildBottomNav(t),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(FitNexoraThemeTokens t) {
    final titles = [
      "What's your primary goal?",
      'Tell us about you',
      'Experience Level',
      'You are all set!',
    ];
    final subtitles = [
      'Choose the outcome you want FitNexora to optimize for.',
      'We personalize your plan based on these details.',
      'This helps us calibrate your workout intensity.',
      'Review your profile and launch your dashboard.',
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (_step > 0)
                GestureDetector(
                  onTap: () => setState(() => _step--),
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: t.glassFill,
                      shape: BoxShape.circle,
                      border: Border.all(color: t.glassBorder),
                    ),
                    child: Icon(Icons.arrow_back_rounded,
                        color: t.textPrimary, size: 20),
                  ),
                )
              else
                const SizedBox(width: 42),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: t.brand.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                  border:
                      Border.all(color: t.brand.withOpacity(0.28)),
                ),
                child: Text(
                  'Step ${_step + 1} of $_totalSteps',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: t.brand,
                  ),
                ),
              ),
              const SizedBox(width: 42),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            titles[_step],
            style: GoogleFonts.inter(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: t.textPrimary,
              letterSpacing: -0.6,
            ),
          ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0),
          const SizedBox(height: 6),
          Text(
            subtitles[_step],
            style: GoogleFonts.inter(
              fontSize: 14,
              color: t.textSecondary,
              height: 1.45,
            ),
          ).animate().fadeIn(duration: 350.ms, delay: 50.ms),
        ],
      ),
    );
  }

  Widget _buildProgressBar(FitNexoraThemeTokens t) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Row(
        children: List.generate(_totalSteps, (index) {
          final isActive = index <= _step;
          final isCurrent = index == _step;
          return Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
              height: 5,
              margin: EdgeInsets.only(right: index == _totalSteps - 1 ? 0 : 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                gradient: isActive
                    ? LinearGradient(colors: [t.brand, t.accent])
                    : null,
                color: isActive ? null : t.ringTrack,
                boxShadow: isCurrent
                    ? [
                        BoxShadow(
                          color: t.brand.withOpacity(0.5),
                          blurRadius: 8,
                        )
                      ]
                    : null,
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStepContent(FitNexoraThemeTokens t) {
    switch (_step) {
      case 0:
        return _GoalStep(
          selectedGoal: _goal,
          onGoalSelected: (goal) => setState(() => _goal = goal),
        ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05, end: 0);
      case 1:
        return _MetricsStep(
          gender: _gender,
          onGenderChanged: (g) => setState(() => _gender = g),
          weightController: _weightController,
          heightController: _heightController,
          ageController: _ageController,
          useMetricHeight: _useMetricHeight,
          useMetricWeight: _useMetricWeight,
          onToggleHeight: () =>
              setState(() => _useMetricHeight = !_useMetricHeight),
          onToggleWeight: () =>
              setState(() => _useMetricWeight = !_useMetricWeight),
        ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05, end: 0);
      case 2:
        return _ExperienceStep(
          selectedLevel: _level,
          onLevelSelected: (l) => setState(() => _level = l),
        ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05, end: 0);
      case 3:
        return _SummaryStep(
          goal: _goal,
          gender: _gender,
          weight: _weightController.text,
          height: _heightController.text,
          age: _ageController.text,
          level: _level,
          useMetricHeight: _useMetricHeight,
          useMetricWeight: _useMetricWeight,
        ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05, end: 0);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildBottomNav(FitNexoraThemeTokens t) {
    final isLast = _step == _totalSteps - 1;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(
        color: t.background.withOpacity(0.95),
        border: Border(top: BorderSide(color: t.border)),
      ),
      child: SizedBox(
        width: double.infinity,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isLast ? [t.accent, t.brand] : [t.brand, t.brandSecondary],
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: t.brand.withOpacity(0.35),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18)),
            ),
            onPressed: _isLoading ? null : _advance,
            child: _isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.2, color: Colors.white),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isLast ? 'Get Started' : 'Continue',
                        style: GoogleFonts.inter(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        isLast
                            ? Icons.rocket_launch_rounded
                            : Icons.arrow_forward_rounded,
                        size: 18,
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Step 1 – Primary Goal
// ---------------------------------------------------------------------------

class _GoalStep extends StatelessWidget {
  final FitnessGoal selectedGoal;
  final ValueChanged<FitnessGoal> onGoalSelected;

  const _GoalStep({
    required this.selectedGoal,
    required this.onGoalSelected,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;

    const goals = [
      _GoalOption(
        goal: FitnessGoal.muscleGain,
        label: 'Build Muscle',
        icon: Icons.fitness_center_rounded,
        colorKey: 'brand',
      ),
      _GoalOption(
        goal: FitnessGoal.fatLoss,
        label: 'Lose Weight',
        icon: Icons.local_fire_department_rounded,
        colorKey: 'danger',
      ),
      _GoalOption(
        goal: FitnessGoal.athleticPerformance,
        label: 'Improve Endurance',
        icon: Icons.directions_run_rounded,
        colorKey: 'accent',
      ),
      _GoalOption(
        goal: FitnessGoal.generalFitness,
        label: 'Overall Health',
        icon: Icons.favorite_rounded,
        colorKey: 'success',
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.05,
      children: goals.map((opt) {
        final isSelected = opt.goal == selectedGoal;
        final cardColor = _resolveColor(opt.colorKey, t);

        return GestureDetector(
          onTap: () => onGoalSelected(opt.goal),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isSelected
                  ? cardColor.withOpacity(0.13)
                  : t.surfaceAlt,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isSelected ? cardColor : t.border,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: cardColor.withOpacity(0.22),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      )
                    ]
                  : null,
            ),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: cardColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(opt.icon, color: cardColor, size: 24),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        opt.label,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? cardColor : t.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: cardColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check_rounded,
                          color: Colors.white, size: 16),
                    ),
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Color _resolveColor(String key, FitNexoraThemeTokens t) {
    switch (key) {
      case 'danger':
        return t.danger;
      case 'accent':
        return t.accent;
      case 'success':
        return t.success;
      default:
        return t.brand;
    }
  }
}

class _GoalOption {
  final FitnessGoal goal;
  final String label;
  final IconData icon;
  final String colorKey;

  const _GoalOption({
    required this.goal,
    required this.label,
    required this.icon,
    required this.colorKey,
  });
}

// ---------------------------------------------------------------------------
// Step 2 – Metrics
// ---------------------------------------------------------------------------

class _MetricsStep extends StatelessWidget {
  final String gender;
  final ValueChanged<String> onGenderChanged;
  final TextEditingController weightController;
  final TextEditingController heightController;
  final TextEditingController ageController;
  final bool useMetricHeight;
  final bool useMetricWeight;
  final VoidCallback onToggleHeight;
  final VoidCallback onToggleWeight;

  const _MetricsStep({
    required this.gender,
    required this.onGenderChanged,
    required this.weightController,
    required this.heightController,
    required this.ageController,
    required this.useMetricHeight,
    required this.useMetricWeight,
    required this.onToggleHeight,
    required this.onToggleWeight,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;
    const genders = ['Male', 'Female', 'Other'];

    return GlassmorphicCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Gender',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: t.textSecondary,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: genders.map((g) {
                final isSelected = g == gender;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => onGenderChanged(g),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      margin: EdgeInsets.only(
                          right: g == genders.last ? 0 : 8),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? t.brand.withOpacity(0.14)
                            : t.surfaceAlt,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected ? t.brand : t.border,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Text(
                        g,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? t.brand : t.textSecondary,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            _MetricField(
              controller: heightController,
              label: 'Height',
              icon: Icons.height_rounded,
              unit: useMetricHeight ? 'cm' : 'ft',
              altUnit: useMetricHeight ? 'ft' : 'cm',
              onToggleUnit: onToggleHeight,
            ),
            const SizedBox(height: 14),
            _MetricField(
              controller: weightController,
              label: 'Weight',
              icon: Icons.monitor_weight_outlined,
              unit: useMetricWeight ? 'kg' : 'lbs',
              altUnit: useMetricWeight ? 'lbs' : 'kg',
              onToggleUnit: onToggleWeight,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: ageController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: 'Age',
                prefixIcon: const Icon(Icons.cake_outlined),
                suffixText: 'yrs',
                suffixStyle: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: t.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String unit;
  final String altUnit;
  final VoidCallback onToggleUnit;

  const _MetricField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.unit,
    required this.altUnit,
    required this.onToggleUnit,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;

    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
      ],
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        suffix: GestureDetector(
          onTap: onToggleUnit,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: t.brand.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: t.brand.withOpacity(0.3)),
            ),
            child: Text(
              unit,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: t.brand,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Step 3 – Experience Level
// ---------------------------------------------------------------------------

class _ExperienceStep extends StatelessWidget {
  final TrainingLevel selectedLevel;
  final ValueChanged<TrainingLevel> onLevelSelected;

  const _ExperienceStep({
    required this.selectedLevel,
    required this.onLevelSelected,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;

    final levels = [
      _LevelOption(
        level: TrainingLevel.beginner,
        icon: Icons.spa_outlined,
        subtitle: '0–1 years of training',
        color: t.accent,
      ),
      _LevelOption(
        level: TrainingLevel.intermediate,
        icon: Icons.bolt_rounded,
        subtitle: '1–3 years of consistent training',
        color: t.warning,
      ),
      _LevelOption(
        level: TrainingLevel.advanced,
        icon: Icons.local_fire_department_rounded,
        subtitle: '3+ years, structured programming',
        color: t.brand,
      ),
    ];

    return Column(
      children: levels.asMap().entries.map((entry) {
        final opt = entry.value;
        final isSelected = opt.level == selectedLevel;

        return GestureDetector(
          onTap: () => onLevelSelected(opt.level),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isSelected
                  ? opt.color.withOpacity(0.10)
                  : t.surfaceAlt,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? opt.color : t.border,
                width: isSelected ? 1.8 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: opt.color.withOpacity(0.18),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      )
                    ]
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: opt.color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(opt.icon, color: opt.color, size: 26),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        opt.level.label,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color:
                              isSelected ? opt.color : t.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        opt.subtitle,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: t.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? opt.color : Colors.transparent,
                    border: Border.all(
                      color: isSelected ? opt.color : t.border,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check_rounded,
                          color: Colors.white, size: 14)
                      : null,
                ),
              ],
            ),
          ),
        )
            .animate(delay: (entry.key * 80).ms)
            .fadeIn(duration: 280.ms)
            .slideX(begin: 0.05, end: 0);
      }).toList(),
    );
  }
}

class _LevelOption {
  final TrainingLevel level;
  final IconData icon;
  final String subtitle;
  final Color color;

  const _LevelOption({
    required this.level,
    required this.icon,
    required this.subtitle,
    required this.color,
  });
}

// ---------------------------------------------------------------------------
// Step 4 – Summary
// ---------------------------------------------------------------------------

class _SummaryStep extends StatelessWidget {
  final FitnessGoal goal;
  final String gender;
  final String weight;
  final String height;
  final String age;
  final TrainingLevel level;
  final bool useMetricHeight;
  final bool useMetricWeight;

  const _SummaryStep({
    required this.goal,
    required this.gender,
    required this.weight,
    required this.height,
    required this.age,
    required this.level,
    required this.useMetricHeight,
    required this.useMetricWeight,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;

    final summaryItems = [
      _SummaryItem(
          label: 'Primary Goal', value: goal.label, icon: Icons.flag_rounded),
      _SummaryItem(label: 'Gender', value: gender, icon: Icons.person_rounded),
      _SummaryItem(
          label: 'Height',
          value: height.isEmpty
              ? 'Not set'
              : '$height ${useMetricHeight ? "cm" : "ft"}',
          icon: Icons.height_rounded),
      _SummaryItem(
          label: 'Weight',
          value: weight.isEmpty
              ? 'Not set'
              : '$weight ${useMetricWeight ? "kg" : "lbs"}',
          icon: Icons.monitor_weight_outlined),
      _SummaryItem(
          label: 'Age',
          value: age.isEmpty ? 'Not set' : '$age yrs',
          icon: Icons.cake_outlined),
      _SummaryItem(
          label: 'Experience',
          value: level.label,
          icon: Icons.stars_rounded),
    ];

    return Column(
      children: [
        // Celebration header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                t.brand.withOpacity(0.16),
                t.accent.withOpacity(0.10),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: t.brand.withOpacity(0.22)),
          ),
          child: Column(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                      colors: [t.brand, t.accent]),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: t.brand.withOpacity(0.4),
                      blurRadius: 22,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(Icons.check_rounded,
                    color: Colors.white, size: 36),
              )
                  .animate()
                  .scale(
                      begin: const Offset(0.6, 0.6),
                      end: const Offset(1, 1),
                      duration: 400.ms,
                      curve: Curves.elasticOut)
                  .fadeIn(),
              const SizedBox(height: 16),
              Text(
                'Profile Complete!',
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: t.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'FitNexora is ready to personalize\nyour fitness journey.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                    fontSize: 14, color: t.textSecondary, height: 1.5),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        GlassmorphicCard(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: summaryItems.asMap().entries.map((entry) {
                final item = entry.value;
                final isLast = entry.key == summaryItems.length - 1;
                return Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: t.brand.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(item.icon,
                              color: t.brand, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          item.label,
                          style: GoogleFonts.inter(
                              fontSize: 13, color: t.textSecondary),
                        ),
                        const Spacer(),
                        Text(
                          item.value,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: t.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    if (!isLast) ...[
                      const SizedBox(height: 10),
                      Divider(color: t.divider, height: 1),
                      const SizedBox(height: 10),
                    ],
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}

class _SummaryItem {
  final String label;
  final String value;
  final IconData icon;

  const _SummaryItem(
      {required this.label, required this.value, required this.icon});
}

// ---------------------------------------------------------------------------
// Shared glow orb
// ---------------------------------------------------------------------------

class _GlowOrb extends StatelessWidget {
  final Color color;
  final double size;

  const _GlowOrb({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, Colors.transparent],
          ),
        ),
      ),
    );
  }
}
