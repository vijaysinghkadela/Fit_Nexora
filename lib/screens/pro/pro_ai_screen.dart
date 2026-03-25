import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/extensions.dart';
import '../../models/ai_generated_plan_model.dart';
import '../../models/ai_generation_request_model.dart';
import '../../models/fitness_profile_model.dart';
import '../../providers/ai_agent_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/member_provider.dart';
import '../../providers/pro_member_provider.dart';
import '../../widgets/glassmorphic_card.dart';
import 'pro_paywall_screen.dart';

class ProAiScreen extends ConsumerStatefulWidget {
  final int initialStep;

  const ProAiScreen({
    super.key,
    this.initialStep = 0,
  });

  @override
  ConsumerState<ProAiScreen> createState() => _ProAiScreenState();
}

class _ProAiScreenState extends ConsumerState<ProAiScreen> {
  final _briefKey = GlobalKey<FormState>();
  final _profileKey = GlobalKey<FormState>();

  final _objectiveCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _bodyFatCtrl = TextEditingController();
  final _muscleMassCtrl = TextEditingController();
  final _daysCtrl = TextEditingController(text: '4');
  final _sessionCtrl = TextEditingController(text: '60');
  final _calorieCtrl = TextEditingController();
  final _allergiesCtrl = TextEditingController();
  final _restrictionsCtrl = TextEditingController();
  final _injuriesCtrl = TextEditingController();
  final _medicalCtrl = TextEditingController();

  String _gender = 'male';
  String _fitnessLevel = 'intermediate';
  String _goal = 'general_fitness';
  String _dietType = 'non_veg';
  String _equipment = 'full_gym';
  String _trainingTime = 'morning';
  String _sleepQuality = 'average';
  String _energyLevel = 'average';

  int _currentStep = 0;
  bool _loadingProfile = true;
  bool _generating = false;
  String? _generationError;
  AiGeneratedPlan? _generatedPlan;

  @override
  void initState() {
    super.initState();
    _currentStep = widget.initialStep.clamp(0, 2);
    Future.microtask(_prefill);
  }

  @override
  void dispose() {
    _objectiveCtrl.dispose();
    _nameCtrl.dispose();
    _descriptionCtrl.dispose();
    _ageCtrl.dispose();
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    _bodyFatCtrl.dispose();
    _muscleMassCtrl.dispose();
    _daysCtrl.dispose();
    _sessionCtrl.dispose();
    _calorieCtrl.dispose();
    _allergiesCtrl.dispose();
    _restrictionsCtrl.dispose();
    _injuriesCtrl.dispose();
    _medicalCtrl.dispose();
    super.dispose();
  }

  Future<void> _prefill() async {
    try {
      final user = ref.read(currentUserProvider).value;
      final membership = await ref.read(memberMembershipProvider.future);
      final measurements = await ref.read(proAllMeasurementsProvider.future);
      final latestMeasurement =
          measurements.isNotEmpty ? measurements.first : null;
      if (user == null || membership == null) {
        if (mounted) setState(() => _loadingProfile = false);
        return;
      }

      final profile = await ref
          .read(aiAgentServiceProvider)
          .getFitnessProfile(user.id, membership.gymId);
      if (!mounted) return;

      _objectiveCtrl.text = profile?.primaryGoal?.replaceAll('_', ' ') ??
          'Build a complete Pro plan for my current goal';
      _nameCtrl.text = '${user.fullName.split(' ').first} Pro Plan';
      _descriptionCtrl.text =
          'AI-generated workout, nutrition, reasoning, and full-body progress insights.';
      _ageCtrl.text = profile?.age?.toString() ?? '';
      _heightCtrl.text = _numText(profile?.heightCm);
      _weightCtrl.text =
          _numText(profile?.weightKg ?? latestMeasurement?.weightKg);
      _bodyFatCtrl.text =
          _numText(profile?.bodyFatPct ?? latestMeasurement?.bodyFatPercent);
      _muscleMassCtrl.text = _numText(profile?.muscleMassKg);
      _daysCtrl.text = '${profile?.availableDays ?? 4}';
      _calorieCtrl.text = profile?.calorieTarget?.toString() ?? '';
      _allergiesCtrl.text = profile?.foodAllergies.join(', ') ?? '';
      _injuriesCtrl.text = profile?.injuries.join(', ') ?? '';

      if ((profile?.gender ?? '').isNotEmpty) _gender = profile!.gender!;
      if ((profile?.fitnessLevel ?? '').isNotEmpty) {
        _fitnessLevel = profile!.fitnessLevel!;
      }
      if ((profile?.primaryGoal ?? '').isNotEmpty) {
        _goal = profile!.primaryGoal!;
      }
      if ((profile?.dietType ?? '').isNotEmpty) _dietType = profile!.dietType!;
    } finally {
      if (mounted) setState(() => _loadingProfile = false);
    }
  }

  String _numText(num? value) {
    if (value == null) return '';
    return value % 1 == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;
    final proAccessAsync = ref.watch(memberHasProAccessProvider);

    return proAccessAsync.when(
      loading: () => Scaffold(
        backgroundColor: t.background,
        body: Center(child: CircularProgressIndicator(color: t.brand)),
      ),
      error: (_, __) => const ProPaywallScreen(),
      data: (hasPro) {
        if (!hasPro) return const ProPaywallScreen();
        return Scaffold(
          backgroundColor: t.background,
          appBar: AppBar(
            backgroundColor: t.background,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_rounded, color: t.textSecondary),
              onPressed: () =>
                  context.canPop() ? context.pop() : context.go('/pro'),
            ),
            title: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: t.brand.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: t.brand.withOpacity(0.24)),
                  ),
                  child: Text(
                    'PRO PLAN',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: t.brand,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Kimi AI Planner',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: t.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => context.push('/pro/progress'),
                child: Text(
                  'AI Progress',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: t.brand,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: _loadingProfile
              ? Center(child: CircularProgressIndicator(color: t.brand))
              : Column(
                  children: [
                    _stepRow(context),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        child: _currentStep == 0
                            ? _briefStep(context)
                            : _currentStep == 1
                                ? _profileStep(context)
                                : _resultsStep(context),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _stepRow(BuildContext context) {
    final t = context.fitTheme;
    const steps = ['Brief', 'Profile', 'Results'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Row(
        children: steps.asMap().entries.map((entry) {
          final index = entry.key;
          final isActive = index == _currentStep;
          return Expanded(
            child: Container(
              margin:
                  EdgeInsets.only(right: index == steps.length - 1 ? 0 : 10),
              padding: const EdgeInsets.symmetric(vertical: 11),
              decoration: BoxDecoration(
                color: isActive ? t.brand.withOpacity(0.14) : t.surfaceAlt,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isActive ? t.brand.withOpacity(0.26) : t.border,
                ),
              ),
              child: Text(
                entry.value,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isActive ? t.brand : t.textSecondary,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _briefStep(BuildContext context) {
    return ListView(
      key: const ValueKey('brief-step'),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        GlassmorphicCard(
          borderRadius: 24,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _briefKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _title(context, 'Step 1 · Plan Brief'),
                  _body(
                    context,
                    'Define the plan objective, base name, and description. This Pro flow always generates AI workout plans, AI diet plans, reasoning, and a full-body progress page.',
                  ),
                  const SizedBox(height: 18),
                  _field(context, 'Plan Objective', _objectiveCtrl,
                      'e.g. Lose fat while preserving strength'),
                  const SizedBox(height: 12),
                  _field(
                      context, 'Plan Name', _nameCtrl, 'e.g. Lean Rebuild Pro'),
                  const SizedBox(height: 12),
                  _field(
                    context,
                    'Plan Description',
                    _descriptionCtrl,
                    'Describe the style, constraints, and desired coaching angle.',
                    maxLines: 4,
                  ),
                ],
              ),
            ),
          ),
        ).animate().fadeIn(duration: 220.ms).slideY(begin: 0.04),
        const SizedBox(height: 16),
        _primaryButton(
          context,
          label: 'Continue to Complete Profile',
          icon: Icons.arrow_forward_rounded,
          onPressed: () {
            if (_briefKey.currentState?.validate() ?? false) {
              setState(() => _currentStep = 1);
            }
          },
        ),
      ],
    );
  }

  Widget _profileStep(BuildContext context) {
    return ListView(
      key: const ValueKey('profile-step'),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        GlassmorphicCard(
          borderRadius: 24,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _profileKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _title(context, 'Step 2 · Complete Profile'),
                  _body(
                    context,
                    'Review the data Kimi will use for analysis, workout programming, and diet design.',
                  ),
                  const SizedBox(height: 16),
                  _inlineFields(context, [
                    _field(context, 'Age', _ageCtrl, '27',
                        keyboardType: TextInputType.number),
                    _field(context, 'Height (cm)', _heightCtrl, '172',
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true)),
                  ]),
                  const SizedBox(height: 12),
                  _inlineFields(context, [
                    _field(context, 'Weight (kg)', _weightCtrl, '74',
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true)),
                    _field(context, 'Body Fat %', _bodyFatCtrl, '18',
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        required: false),
                  ]),
                  const SizedBox(height: 12),
                  _inlineFields(context, [
                    _field(context, 'Muscle Mass (kg)', _muscleMassCtrl, '34',
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        required: false),
                    _field(context, 'Calorie Override', _calorieCtrl, '2200',
                        keyboardType: TextInputType.number, required: false),
                  ]),
                  const SizedBox(height: 12),
                  _inlineFields(context, [
                    _field(context, 'Days / Week', _daysCtrl, '4',
                        keyboardType: TextInputType.number),
                    _field(context, 'Session Mins', _sessionCtrl, '60',
                        keyboardType: TextInputType.number),
                  ]),
                  const SizedBox(height: 16),
                  _chips(
                      context,
                      'Sex',
                      _gender,
                      const {
                        'male': 'Male',
                        'female': 'Female',
                        'other': 'Other',
                      },
                      (value) => setState(() => _gender = value)),
                  const SizedBox(height: 12),
                  _chips(
                      context,
                      'Goal',
                      _goal,
                      const {
                        'general_fitness': 'General Fitness',
                        'weight_loss': 'Weight Loss',
                        'muscle_gain': 'Muscle Gain',
                        'endurance': 'Endurance',
                        'flexibility': 'Flexibility',
                        'sports_performance': 'Sports Performance',
                      },
                      (value) => setState(() => _goal = value)),
                  const SizedBox(height: 12),
                  _chips(
                      context,
                      'Training Level',
                      _fitnessLevel,
                      const {
                        'beginner': 'Beginner',
                        'intermediate': 'Intermediate',
                        'advanced': 'Advanced',
                      },
                      (value) => setState(() => _fitnessLevel = value)),
                  const SizedBox(height: 12),
                  _chips(
                      context,
                      'Equipment',
                      _equipment,
                      const {
                        'full_gym': 'Full Gym',
                        'home_with_equipment': 'Home With Equipment',
                        'home_minimal': 'Home Minimal',
                        'bodyweight_only': 'Bodyweight Only',
                      },
                      (value) => setState(() => _equipment = value)),
                  const SizedBox(height: 12),
                  _chips(
                      context,
                      'Training Time',
                      _trainingTime,
                      const {
                        'morning': 'Morning',
                        'afternoon': 'Afternoon',
                        'evening': 'Evening',
                      },
                      (value) => setState(() => _trainingTime = value)),
                  const SizedBox(height: 12),
                  _chips(
                      context,
                      'Diet Type',
                      _dietType,
                      const {
                        'non_veg': 'Non-Vegetarian',
                        'veg': 'Vegetarian',
                        'vegan': 'Vegan',
                        'keto': 'Keto',
                        'intermittent_fasting': 'Intermittent Fasting',
                      },
                      (value) => setState(() => _dietType = value)),
                  const SizedBox(height: 12),
                  _chips(
                      context,
                      'Sleep Quality',
                      _sleepQuality,
                      const {
                        'poor': 'Poor',
                        'average': 'Average',
                        'good': 'Good',
                        'excellent': 'Excellent',
                      },
                      (value) => setState(() => _sleepQuality = value)),
                  const SizedBox(height: 12),
                  _chips(
                      context,
                      'Energy Level',
                      _energyLevel,
                      const {
                        'poor': 'Poor',
                        'average': 'Average',
                        'good': 'Good',
                        'excellent': 'Excellent',
                      },
                      (value) => setState(() => _energyLevel = value)),
                  const SizedBox(height: 12),
                  _field(context, 'Food Allergies', _allergiesCtrl,
                      'Comma separated, e.g. peanuts, shellfish',
                      required: false),
                  const SizedBox(height: 12),
                  _field(context, 'Food Restrictions', _restrictionsCtrl,
                      'Optional, e.g. Jain, low sodium',
                      required: false),
                  const SizedBox(height: 12),
                  _field(context, 'Injuries / Limitations', _injuriesCtrl,
                      'Optional, e.g. lower back tightness',
                      required: false),
                  const SizedBox(height: 12),
                  _field(context, 'Medical Conditions', _medicalCtrl,
                      'Optional, e.g. diabetes, hypertension',
                      required: false),
                ],
              ),
            ),
          ),
        ).animate().fadeIn(duration: 220.ms).slideY(begin: 0.04),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => setState(() => _currentStep = 0),
                icon: const Icon(Icons.arrow_back_rounded),
                label: Text('Back',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _primaryButton(
                context,
                label: _generating ? 'Generating...' : 'Generate Pro Plan',
                icon: _generating ? null : Icons.auto_awesome_rounded,
                onPressed: _generating ? null : _generatePlan,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _resultsStep(BuildContext context) {
    final t = context.fitTheme;
    return ListView(
      key: const ValueKey('results-step'),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        GlassmorphicCard(
          borderRadius: 24,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _title(context, 'Step 3 · Results + Publish'),
                _body(
                  context,
                  'This saves the AI result for testing and publishes the generated workout and diet plans into the normal member flows.',
                ),
                const SizedBox(height: 16),
                if (_generating)
                  _status(context, t.brand, Icons.auto_awesome_rounded,
                      'Kimi is generating body analysis, workout structure, nutrition targets, and reasoning traces.')
                else if (_generationError != null)
                  _status(context, t.danger, Icons.error_outline_rounded,
                      _generationError!)
                else if (_generatedPlan == null)
                  _status(context, t.warning, Icons.pending_actions_rounded,
                      'Generate the plan to preview the AI output here.')
                else
                  _status(
                      context,
                      t.success,
                      Icons.check_circle_outline_rounded,
                      'Pro plan published successfully. Open the full-body progress page to review the latest AI output.'),
              ],
            ),
          ),
        ),
        if (_generatedPlan != null) ...[
          const SizedBox(height: 16),
          _summaryCard(context, 'Plan Summary', [
            _metric('Plan', _generatedPlan!.planName ?? 'AI Pro Plan'),
            _metric('Tier', _generatedPlan!.planTier.toUpperCase()),
            _metric('Model', _generatedPlan!.modelUsed),
            if (_generatedPlan!.tokensUsed != null)
              _metric('Tokens', '${_generatedPlan!.tokensUsed}'),
          ]),
          const SizedBox(height: 12),
          _summaryCard(context, 'Body Analysis', [
            _metric('Somatotype',
                '${_generatedPlan!.bodyAnalysis?['somatotype'] ?? '—'}'),
            _metric('BMI Category',
                '${_generatedPlan!.bodyAnalysis?['bmi_category'] ?? '—'}'),
            _metric('Recommended Focus',
                '${_generatedPlan!.bodyAnalysis?['recommended_focus'] ?? '—'}'),
          ]),
          const SizedBox(height: 12),
          _summaryCard(context, 'Workout Summary', [
            _metric('Structure',
                '${_generatedPlan!.workoutPlan?['weekly_structure'] ?? '—'}'),
            _metric('Progression',
                '${_generatedPlan!.workoutPlan?['progression_logic'] ?? '—'}'),
          ]),
          const SizedBox(height: 12),
          _summaryCard(context, 'Diet Summary', [
            _metric('Calories',
                '${_generatedPlan!.dietPlan?['calorie_target'] ?? '—'} kcal'),
            _metric('Protein',
                '${_generatedPlan!.dietPlan?['protein_g'] ?? '—'} g'),
            _metric('Hydration',
                '${_generatedPlan!.dietPlan?['hydration_target_litres'] ?? '—'} L'),
          ]),
          const SizedBox(height: 12),
          _summaryCard(context, 'Reasoning Summary', [
            Text(
              _truncate(_generatedPlan!.reasoningContent ??
                  'No reasoning trace returned.'),
              style: GoogleFonts.inter(
                fontSize: 12,
                color: t.textSecondary,
                height: 1.55,
              ),
            ),
          ]),
        ],
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => setState(() => _currentStep = 1),
                icon: const Icon(Icons.edit_note_rounded),
                label: Text(
                  'Edit Profile',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _primaryButton(
                context,
                label: _generatedPlan == null
                    ? 'Generate Now'
                    : 'Open Full-Body Progress',
                icon: _generatedPlan == null
                    ? Icons.refresh_rounded
                    : Icons.monitor_heart_rounded,
                onPressed: _generatedPlan == null
                    ? (_generating ? null : _generatePlan)
                    : () => context.push('/pro/progress'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _title(BuildContext context, String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        color: context.fitTheme.textPrimary,
      ),
    );
  }

  Widget _body(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 14,
          color: context.fitTheme.textSecondary,
          height: 1.55,
        ),
      ),
    );
  }

  Widget _field(
    BuildContext context,
    String label,
    TextEditingController controller,
    String hint, {
    int maxLines = 1,
    TextInputType? keyboardType,
    bool required = true,
  }) {
    final t = context.fitTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: t.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: required
              ? (value) =>
                  (value == null || value.trim().isEmpty) ? 'Required' : null
              : null,
          style: GoogleFonts.inter(fontSize: 14, color: t.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(fontSize: 13, color: t.textMuted),
            filled: true,
            fillColor: t.surfaceAlt,
            contentPadding: const EdgeInsets.all(14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: t.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: t.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: t.brand, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _inlineFields(BuildContext context, List<Widget> children) {
    return Row(
      children: [
        Expanded(child: children[0]),
        const SizedBox(width: 12),
        Expanded(child: children[1]),
      ],
    );
  }

  Widget _chips(
    BuildContext context,
    String label,
    String selected,
    Map<String, String> options,
    ValueChanged<String> onChanged,
  ) {
    final t = context.fitTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: t.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.entries.map((entry) {
            final isSelected = entry.key == selected;
            return ChoiceChip(
              selected: isSelected,
              label: Text(
                entry.value,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? t.brand : t.textSecondary,
                ),
              ),
              selectedColor: t.brand.withOpacity(0.14),
              backgroundColor: t.surfaceAlt,
              side: BorderSide(
                color: isSelected ? t.brand.withOpacity(0.28) : t.border,
              ),
              onSelected: (_) => onChanged(entry.key),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _status(
    BuildContext context,
    Color color,
    IconData icon,
    String message,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: context.fitTheme.textSecondary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard(
      BuildContext context, String title, List<Widget> children) {
    return GlassmorphicCard(
      borderRadius: 24,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: context.fitTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _metric(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Builder(
        builder: (context) => Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: context.fitTheme.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: context.fitTheme.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _primaryButton(
    BuildContext context, {
    required String label,
    IconData? icon,
    required VoidCallback? onPressed,
  }) {
    final t = context.fitTheme;
    return SizedBox(
      height: 54,
      child: FilledButton.icon(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: t.brand,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        icon: icon == null
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Icon(icon),
        label: Text(
          label,
          style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  String _truncate(String value) {
    final normalized = value.trim();
    if (normalized.length <= 900) return normalized;
    return '${normalized.substring(0, 900).trim()}...';
  }

  Future<void> _generatePlan() async {
    if (!(_profileKey.currentState?.validate() ?? false)) return;

    final user = ref.read(currentUserProvider).value;
    final membership = await ref.read(memberMembershipProvider.future);
    if (user == null || membership == null) {
      if (mounted) {
        context.showSnackBar(
          'Missing member or gym context. Please sign in again.',
          isError: true,
        );
      }
      return;
    }

    final fitnessProfile = FitnessProfile(
      memberId: user.id,
      gymId: membership.gymId,
      heightCm: double.tryParse(_heightCtrl.text.trim()),
      weightKg: double.tryParse(_weightCtrl.text.trim()),
      bodyFatPct: double.tryParse(_bodyFatCtrl.text.trim()),
      muscleMassKg: double.tryParse(_muscleMassCtrl.text.trim()),
      bmi: _bmi(),
      age: int.tryParse(_ageCtrl.text.trim()),
      gender: _gender,
      fitnessLevel: _fitnessLevel,
      primaryGoal: _goal,
      injuries: _splitCsv(_injuriesCtrl.text),
      availableDays: int.tryParse(_daysCtrl.text.trim()) ?? 4,
      dietType: _dietType,
      foodAllergies: _splitCsv(_allergiesCtrl.text),
      calorieTarget: int.tryParse(_calorieCtrl.text.trim()),
    );

    final request = AiGenerationRequest(
      planObjective: _objectiveCtrl.text.trim(),
      planName: _nameCtrl.text.trim(),
      planDescription: _descriptionCtrl.text.trim(),
      planTier: 'pro',
      fitnessProfile: fitnessProfile,
      publishToActivePlans: true,
      sessionDurationMins: int.tryParse(_sessionCtrl.text.trim()),
      equipment: _equipment,
      trainingTime: _trainingTime,
      restrictions: _optional(_restrictionsCtrl.text),
      medicalConditions: _optional(_medicalCtrl.text),
      sleepQuality: _sleepQuality,
      energyLevel: _energyLevel,
      fullName: user.fullName,
      phone: user.phone,
    );

    setState(() {
      _currentStep = 2;
      _generating = true;
      _generationError = null;
    });

    try {
      final plan = await ref.read(aiAgentServiceProvider).generateProPlan(
            memberId: user.id,
            gymId: membership.gymId,
            request: request,
          );
      ref.invalidate(memberWorkoutPlanProvider);
      ref.invalidate(memberDietPlanProvider);
      ref.invalidate(proLatestAiPlanProvider);
      ref.invalidate(
        aiGeneratedPlansProvider((memberId: user.id, gymId: membership.gymId)),
      );
      if (!mounted) return;
      setState(() => _generatedPlan = plan);
      context.showSnackBar('Pro plan generated and published successfully.');
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _generationError = error.toString().replaceFirst('Exception: ', '');
      });
      context.showSnackBar('Failed to generate the Pro plan.', isError: true);
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  double? _bmi() {
    final heightCm = double.tryParse(_heightCtrl.text.trim());
    final weightKg = double.tryParse(_weightCtrl.text.trim());
    if (heightCm == null || weightKg == null || heightCm <= 0) return null;
    final heightM = heightCm / 100;
    return weightKg / (heightM * heightM);
  }

  List<String> _splitCsv(String raw) => raw
      .split(',')
      .map((value) => value.trim())
      .where((value) => value.isNotEmpty)
      .toList();

  String? _optional(String raw) {
    final trimmed = raw.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
