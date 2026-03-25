import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/diet_templates.dart';
import '../../core/extensions.dart';
import '../../models/diet_plan_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/gym_provider.dart';
import '../../providers/member_provider.dart';
import '../../widgets/glassmorphic_card.dart';

// ---------------------------------------------------------------------------
// Data class — sport preset
// ---------------------------------------------------------------------------

class _SportPreset {
  final String label;
  final IconData icon;
  final String key;
  final String description;
  const _SportPreset(this.label, this.icon, this.key, this.description);
}

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class CreateDietPlanScreen extends ConsumerStatefulWidget {
  const CreateDietPlanScreen({super.key});

  @override
  ConsumerState<CreateDietPlanScreen> createState() =>
      _CreateDietPlanScreenState();
}

class _CreateDietPlanScreenState extends ConsumerState<CreateDietPlanScreen>
    with SingleTickerProviderStateMixin {
  // ── Controllers ────────────────────────────────────────────────────────────
  late final TabController _tabController;
  late final PageController _pageController;
  final _formKey = GlobalKey<FormState>();
  final _planNameCtrl = TextEditingController();
  final _ageCtrl = TextEditingController(text: '25');
  final _heightCtrl = TextEditingController(text: '170');
  final _weightCtrl = TextEditingController(text: '70');

  // ── State ──────────────────────────────────────────────────────────────────
  _SportPreset? _selectedSport;
  String _gender = 'male';
  String _activityLevel = 'moderate';
  String _goal = 'maintain';
  String _dietType = 'non_veg';
  bool _includeIndianFoods = true;

  int _currentStep = 0;
  int _targetCalories = 2000;
  int _proteinG = 150;
  int _carbsG = 200;
  int _fatG = 65;
  double _hydrationL = 3.5;
  DietPlan? _matchedTemplate;
  bool _isSaving = false;
  String? _savingTemplateId;
  String? _expandedTemplateId;
  final Map<String, DateTime> _templateStartDates = {};
  final Map<String, List<TextEditingController>> _templateTimingControllers =
      {};

  // ── Sports list ────────────────────────────────────────────────────────────
  static const _sports = [
    _SportPreset('Bodybuilding', Icons.fitness_center, 'bodybuilding',
        'Hypertrophy + aesthetics'),
    _SportPreset('Powerlifting', Icons.sports_gymnastics_rounded,
        'powerlifting', 'Squat · Bench · Deadlift'),
    _SportPreset('Arm Wrestling', Icons.front_hand_rounded, 'arm_wrestling',
        'Grip strength & pulling power'),
    _SportPreset('Weightlifting', Icons.sports_outlined, 'weightlifting',
        'Snatch & Clean & Jerk'),
    _SportPreset('CrossFit', Icons.loop_rounded, 'crossfit',
        'High-intensity functional'),
    _SportPreset('General Fitness', Icons.directions_run_rounded,
        'general_fitness', 'All-round health & wellness'),
    _SportPreset('Fat Loss', Icons.trending_down_rounded, 'fat_loss',
        'Caloric deficit & lean phase'),
  ];

  // ── Lifecycle ──────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // PageController must be created after the widget is in the tree
    // Using a lazy init guard
    if (!_pageControllerInitialized) {
      _pageController = PageController();
      _pageControllerInitialized = true;
    }
  }

  bool _pageControllerInitialized = false;

  @override
  void dispose() {
    _tabController.dispose();
    _pageController.dispose();
    _planNameCtrl.dispose();
    _ageCtrl.dispose();
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    for (final controllers in _templateTimingControllers.values) {
      for (final controller in controllers) {
        controller.dispose();
      }
    }
    super.dispose();
  }

  DateTime _defaultStartDate() => DateUtils.dateOnly(DateTime.now());

  DateTime _startDateForTemplate(DietPlan template) =>
      _templateStartDates[template.id] ?? _defaultStartDate();

  List<TextEditingController> _timingControllersFor(DietPlan template) {
    return _templateTimingControllers.putIfAbsent(
      template.id,
      () => template.meals
          .map((meal) => TextEditingController(text: meal.timing))
          .toList(growable: false),
    );
  }

  List<Meal> _customizedMealsForTemplate(DietPlan template) {
    final timingControllers = _timingControllersFor(template);
    return List<Meal>.generate(template.meals.length, (index) {
      final meal = template.meals[index];
      return Meal(
        name: meal.name,
        timing: timingControllers[index].text.trim(),
        orderIndex: meal.orderIndex,
        foods: List<FoodItem>.from(meal.foods),
        notes: meal.notes,
      );
    }, growable: false);
  }

  Future<void> _pickTemplateStartDate(DietPlan template) async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _startDateForTemplate(template),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (selected == null || !mounted) return;

    setState(() {
      _templateStartDates[template.id] = DateUtils.dateOnly(selected);
    });
  }

  void _toggleTemplateExpansion(String templateId) {
    setState(() {
      _expandedTemplateId =
          _expandedTemplateId == templateId ? null : templateId;
    });
  }

  // ── TDEE / macro computation ───────────────────────────────────────────────
  void _computeMacros() {
    final age = int.tryParse(_ageCtrl.text) ?? 25;
    final height = double.tryParse(_heightCtrl.text) ?? 170;
    final weight = double.tryParse(_weightCtrl.text) ?? 70;

    final double bmr = _gender == 'male'
        ? 10 * weight + 6.25 * height - 5 * age + 5
        : 10 * weight + 6.25 * height - 5 * age - 161;

    const multipliers = {
      'sedentary': 1.2,
      'light': 1.375,
      'moderate': 1.55,
      'active': 1.725,
      'very_active': 1.9,
    };
    final tdee = bmr * (multipliers[_activityLevel] ?? 1.55);

    const adjustments = {
      'bulk': 400.0,
      'cut': -500.0,
      'maintain': 0.0,
      'recomp': -200.0,
    };
    _targetCalories = (tdee + (adjustments[_goal] ?? 0)).round();

    // Sport macro splits: record with named fields p/c/f
    const splits = <String, ({double p, double c, double f})>{
      'bodybuilding': (p: 0.35, c: 0.45, f: 0.20),
      'powerlifting': (p: 0.30, c: 0.50, f: 0.20),
      'arm_wrestling': (p: 0.30, c: 0.45, f: 0.25),
      'weightlifting': (p: 0.25, c: 0.55, f: 0.20),
      'crossfit': (p: 0.28, c: 0.48, f: 0.24),
      'general_fitness': (p: 0.25, c: 0.50, f: 0.25),
      'fat_loss': (p: 0.35, c: 0.40, f: 0.25),
    };
    final split = splits[_selectedSport?.key ?? 'general_fitness'] ??
        const (p: 0.25, c: 0.50, f: 0.25);

    _proteinG = (_targetCalories * split.p / 4).round();
    _carbsG = (_targetCalories * split.c / 4).round();
    _fatG = (_targetCalories * split.f / 9).round();
    _hydrationL = (_selectedSport?.key == 'bodybuilding' ||
            _selectedSport?.key == 'powerlifting')
        ? 4.5
        : 4.0;

    // Find matched template
    final sportKey = _selectedSport?.key ?? 'general_fitness';
    _matchedTemplate = kDietTemplates.firstWhere(
      (t) => t.goal == sportKey,
      orElse: () => kDietTemplates.first,
    );
  }

  // ── Step navigation ────────────────────────────────────────────────────────
  void _goToStep(int step) {
    setState(() => _currentStep = step);
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  // ── Save plan ──────────────────────────────────────────────────────────────
  Future<void> _savePlan({
    DietPlan? sourceTemplate,
    List<Meal>? mealsOverride,
    DateTime? startDateOverride,
  }) async {
    if (_isSaving) return;
    setState(() {
      _isSaving = true;
      _savingTemplateId = sourceTemplate?.id;
    });
    try {
      final user = ref.read(currentUserProvider).value;
      if (user == null) throw Exception('Not logged in');

      final gym = ref.read(selectedGymProvider);
      final membership = ref.read(memberMembershipProvider).valueOrNull;
      final gymId = gym?.id ?? membership?.gymId;
      final clientId =
          membership?.clientId ?? await ref.read(memberClientIdProvider.future);
      if (gymId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: const Text(
                'Could not determine your gym. Please select your gym first.'),
            backgroundColor: context.fitTheme.danger,
          ));
        }
        return;
      }
      if (clientId == null) {
        throw Exception('Could not resolve your member profile for this gym.');
      }

      final db = ref.read(databaseServiceProvider);
      final now = DateTime.now();
      final template = sourceTemplate ?? _matchedTemplate;
      final meals = mealsOverride ?? template?.meals ?? [];
      final isTemplateSave = sourceTemplate != null;
      final startDate = startDateOverride == null
          ? null
          : DateUtils.dateOnly(startDateOverride);
      final name =
          (isTemplateSave ? sourceTemplate.name : _planNameCtrl.text.trim())
              .trim();
      final description = isTemplateSave
          ? sourceTemplate.description
          : '${_selectedSport?.label ?? ''} plan — $_goal phase';
      final goal = isTemplateSave
          ? sourceTemplate.goal
          : _selectedSport?.key ?? 'general_fitness';
      final targetCalories =
          isTemplateSave ? sourceTemplate.targetCalories : _targetCalories;
      final targetProtein =
          isTemplateSave ? sourceTemplate.targetProtein : _proteinG;
      final targetCarbs = isTemplateSave ? sourceTemplate.targetCarbs : _carbsG;
      final targetFat = isTemplateSave ? sourceTemplate.targetFat : _fatG;
      final hydrationLiters =
          isTemplateSave ? sourceTemplate.hydrationLiters : _hydrationL;

      await db.createDietPlan({
        'gym_id': gymId,
        'client_id': clientId,
        'trainer_id': null,
        'name': name,
        'description': description,
        'goal': goal,
        'target_calories': targetCalories,
        'target_protein': targetProtein,
        'target_carbs': targetCarbs,
        'target_fat': targetFat,
        'hydration_liters': hydrationLiters,
        'meals': meals.map((m) => m.toJson()).toList(),
        'start_date': startDate?.toIso8601String().split('T').first,
        'status': 'active',
        'is_template': false,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      });

      ref.invalidate(memberAllDietPlansProvider);
      ref.invalidate(memberDietPlanProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            isTemplateSave
                ? 'Template saved to your diet plans.'
                : '🎉 Diet plan created!',
          ),
          backgroundColor: context.fitTheme.brand,
          behavior: SnackBarBehavior.floating,
        ));
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to save: $e'),
          backgroundColor: context.fitTheme.danger,
        ));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _savingTemplateId = null;
        });
      }
    }
  }

  // ── Use template shortcut ──────────────────────────────────────────────────
  void _useTemplate(DietPlan template) {
    final meals = _customizedMealsForTemplate(template);
    final startDate = _startDateForTemplate(template);
    setState(() {
      _planNameCtrl.text = template.name;
      _targetCalories = template.targetCalories;
      _proteinG = template.targetProtein;
      _carbsG = template.targetCarbs;
      _fatG = template.targetFat;
      _hydrationL = template.hydrationLiters;
      _matchedTemplate = template;
    });
    _savePlan(
      sourceTemplate: template,
      mealsOverride: meals,
      startDateOverride: startDate,
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;
    return Scaffold(
      backgroundColor: t.background,
      appBar: AppBar(
        backgroundColor: t.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: t.textSecondary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Create Diet Plan',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: t.textPrimary,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: t.brand,
          unselectedLabelColor: t.textMuted,
          indicatorColor: t.brand,
          tabs: const [Tab(text: 'AI Builder'), Tab(text: 'Templates')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _buildAIBuilder(t),
          _buildTemplatesTab(t),
        ],
      ),
    );
  }

  // ── AI Builder tab ─────────────────────────────────────────────────────────
  Widget _buildAIBuilder(dynamic t) {
    if (!_pageControllerInitialized) {
      return const SizedBox.shrink();
    }
    return Column(
      children: [
        _buildStepIndicator(t),
        Expanded(
          child: PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildStep1(t),
              _buildStep2(t),
              _buildStep3(t),
            ],
          ),
        ),
      ],
    );
  }

  // ── Step indicator dots ────────────────────────────────────────────────────
  Widget _buildStepIndicator(dynamic t) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(3, (i) {
          final isActive = i == _currentStep;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 5),
            width: isActive ? 28 : 10,
            height: 10,
            decoration: BoxDecoration(
              color: isActive ? t.brand : t.border,
              borderRadius: BorderRadius.circular(5),
            ),
          );
        }),
      ),
    );
  }

  // ── STEP 1 — Choose sport ──────────────────────────────────────────────────
  Widget _buildStep1(dynamic t) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Text(
            'Choose Your Sport',
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: t.textPrimary,
            ),
          ).animate().fadeIn(duration: 300.ms),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
          child: Text(
            'We\'ll tailor your macros to your training style.',
            style: GoogleFonts.inter(fontSize: 14, color: t.textMuted),
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.1,
            ),
            itemCount: _sports.length,
            itemBuilder: (context, i) => _sportCard(_sports[i], t),
          ),
        ),
        _buildNextButton(
          label: 'Next →',
          enabled: _selectedSport != null,
          onPressed: () => _goToStep(1),
          t: t,
        ),
      ],
    );
  }

  Widget _sportCard(_SportPreset sport, dynamic t) {
    final isSelected = _selectedSport?.key == sport.key;
    return GlassmorphicCard(
      borderRadius: 20,
      onTap: () {
        setState(() {
          _selectedSport = sport;
          // Pre-fill plan name
          _planNameCtrl.text = '${sport.label} Nutrition Plan';
        });
      },
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [t.brand, t.accent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(sport.icon, color: Colors.white, size: 22),
                ),
                const SizedBox(height: 10),
                Text(
                  sport.label,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: t.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  sport.description,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: t.textMuted,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (isSelected)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: t.brand,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded,
                    color: Colors.white, size: 14),
              ),
            ),
          // Selected border overlay
          if (isSelected)
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: t.brand, width: 2),
                  ),
                ),
              ),
            ),
        ],
      ),
    ).animate().fadeIn(duration: 250.ms);
  }

  // ── STEP 2 — Questionnaire ─────────────────────────────────────────────────
  Widget _buildStep2(dynamic t) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Build Your Plan',
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: t.textPrimary,
              ),
            ).animate().fadeIn(duration: 300.ms),
            const SizedBox(height: 4),
            Text(
              'Fill in your stats for a personalised macro target.',
              style: GoogleFonts.inter(fontSize: 14, color: t.textMuted),
            ),
            const SizedBox(height: 20),

            // ── Plan name ────────────────────────────────────────────────────
            _sectionLabel('Plan Name', t),
            TextFormField(
              controller: _planNameCtrl,
              style: GoogleFonts.inter(color: t.textPrimary),
              decoration: _inputDecoration('e.g. Bodybuilding Bulk Plan', t),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Please enter a name'
                  : null,
            ),
            const SizedBox(height: 20),

            // ── Body stats ───────────────────────────────────────────────────
            _sectionLabel('Body Stats', t),
            GlassmorphicCard(
              borderRadius: 20,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _compactField(
                              'Age', _ageCtrl, TextInputType.number, t),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _compactField(
                              'Height (cm)',
                              _heightCtrl,
                              const TextInputType.numberWithOptions(
                                  decimal: true),
                              t),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _compactField(
                              'Weight (kg)',
                              _weightCtrl,
                              const TextInputType.numberWithOptions(
                                  decimal: true),
                              t),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── Gender ───────────────────────────────────────────────────────
            _sectionLabel('Gender', t),
            _chipRow(
              options: const ['male', 'female'],
              labels: const ['Male', 'Female'],
              selected: _gender,
              onSelected: (v) => setState(() => _gender = v),
              t: t,
            ),
            const SizedBox(height: 20),

            // ── Activity level ───────────────────────────────────────────────
            _sectionLabel('Activity Level', t),
            _chipRow(
              options: const [
                'sedentary',
                'light',
                'moderate',
                'active',
                'very_active'
              ],
              labels: const [
                'Sedentary',
                'Light',
                'Moderate',
                'Active',
                'Very Active'
              ],
              selected: _activityLevel,
              onSelected: (v) => setState(() => _activityLevel = v),
              t: t,
            ),
            const SizedBox(height: 20),

            // ── Goal ─────────────────────────────────────────────────────────
            _sectionLabel('Goal', t),
            _chipRow(
              options: const ['bulk', 'cut', 'maintain', 'recomp'],
              labels: const ['Bulk', 'Cut', 'Maintain', 'Recomp'],
              selected: _goal,
              onSelected: (v) => setState(() => _goal = v),
              t: t,
            ),
            const SizedBox(height: 20),

            // ── Diet type ────────────────────────────────────────────────────
            _sectionLabel('Diet Type', t),
            _chipRow(
              options: const ['non_veg', 'vegetarian', 'vegan', 'keto'],
              labels: const ['Non-Veg', 'Vegetarian', 'Vegan', 'Keto'],
              selected: _dietType,
              onSelected: (v) => setState(() => _dietType = v),
              t: t,
            ),
            const SizedBox(height: 20),

            // ── Indian foods toggle ───────────────────────────────────────────
            GlassmorphicCard(
              borderRadius: 16,
              child: SwitchListTile(
                value: _includeIndianFoods,
                onChanged: (v) => setState(() => _includeIndianFoods = v),
                activeColor: t.brand,
                title: Text(
                  'Include Indian Foods',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: t.textPrimary,
                  ),
                ),
                subtitle: Text(
                  'Dal, roti, rice, paneer and more',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: t.textMuted,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── Back + Calculate buttons ──────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _goToStep(0),
                    icon: Icon(Icons.arrow_back_rounded,
                        size: 18, color: t.textSecondary),
                    label: Text(
                      '← Back',
                      style: GoogleFonts.inter(
                          color: t.textSecondary, fontSize: 14),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: t.border),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: () {
                      if (_formKey.currentState?.validate() ?? false) {
                        _computeMacros();
                        _goToStep(2);
                      }
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: t.brand,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(
                      'Calculate & Preview →',
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── STEP 3 — Review & Save ─────────────────────────────────────────────────
  Widget _buildStep3(dynamic t) {
    final template = _matchedTemplate;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Review & Save',
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: t.textPrimary,
            ),
          ).animate().fadeIn(duration: 300.ms),
          const SizedBox(height: 4),
          Text(
            'Your personalised nutrition plan is ready.',
            style: GoogleFonts.inter(fontSize: 14, color: t.textMuted),
          ),
          const SizedBox(height: 20),

          // ── Hero macro card ─────────────────────────────────────────────────
          GlassmorphicCard(
            borderRadius: 24,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    t.brand.withOpacity(0.15),
                    t.accent.withOpacity(0.08)
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(
                    '$_targetCalories',
                    style: GoogleFonts.inter(
                      fontSize: 56,
                      fontWeight: FontWeight.w900,
                      color: t.brand,
                      height: 1,
                    ),
                  ),
                  Text(
                    'kcal / day',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: t.textMuted,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      _macroBadge('$_targetCalories kcal', t.brand, t),
                      _macroBadge('${_proteinG}g P', t.success, t),
                      _macroBadge('${_carbsG}g C', t.info, t),
                      _macroBadge('${_fatG}g F', t.warning, t),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.water_drop_rounded, size: 16, color: t.info),
                      const SizedBox(width: 4),
                      Text(
                        '${_hydrationL.toStringAsFixed(1)}L water daily',
                        style: GoogleFonts.inter(
                            fontSize: 13, color: t.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.1),
          const SizedBox(height: 20),

          // ── Plan name editable ──────────────────────────────────────────────
          _sectionLabel('Plan Name', t),
          TextFormField(
            controller: _planNameCtrl,
            style: GoogleFonts.inter(color: t.textPrimary),
            decoration: _inputDecoration('Plan name', t),
          ),
          const SizedBox(height: 20),

          // ── Template meals preview ──────────────────────────────────────────
          if (template != null && template.meals.isNotEmpty) ...[
            _sectionLabel('Meal Schedule Preview', t),
            GlassmorphicCard(
              borderRadius: 20,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: template.meals.map((meal) {
                    final mealCals =
                        meal.foods.fold(0, (s, f) => s + f.calories);
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: t.brand.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.restaurant_rounded,
                                size: 18, color: t.brand),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  meal.name,
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: t.textPrimary,
                                  ),
                                ),
                                if (meal.timing.isNotEmpty)
                                  Text(
                                    meal.timing,
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: t.textMuted,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Text(
                            '$mealCals kcal',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: t.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],

          // ── Edit + Save buttons ─────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _goToStep(1),
                  icon: Icon(Icons.edit_rounded,
                      size: 16, color: t.textSecondary),
                  label: Text(
                    'Edit Macros',
                    style:
                        GoogleFonts.inter(color: t.textSecondary, fontSize: 14),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: t.border),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: _isSaving ? null : _savePlan,
                  style: FilledButton.styleFrom(
                    backgroundColor: t.brand,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _isSaving && _savingTemplateId == null
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          'Save My Plan',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Templates tab ──────────────────────────────────────────────────────────
  Widget _buildTemplatesTab(dynamic t) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: kDietTemplates.length,
      itemBuilder: (context, i) => _buildTemplateCard(kDietTemplates[i], t, i),
    );
  }

  Widget _buildTemplateCard(DietPlan template, dynamic t, int index) {
    final isExpanded = _expandedTemplateId == template.id;
    final isSavingThisTemplate = _isSaving && _savingTemplateId == template.id;
    final startDate = _startDateForTemplate(template);
    final timingControllers = isExpanded
        ? _timingControllersFor(template)
        : const <TextEditingController>[];

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: GlassmorphicCard(
        borderRadius: 20,
        child: AnimatedSize(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeInOut,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _isSaving
                      ? null
                      : () => _toggleTemplateExpansion(template.id),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              template.name,
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: t.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          _goalBadge(template.goal, t),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _infoChip('${template.targetCalories} kcal',
                              Icons.local_fire_department_rounded, t),
                          _infoChip('P${template.targetProtein}',
                              Icons.egg_alt_rounded, t),
                          _infoChip('C${template.targetCarbs}',
                              Icons.grain_rounded, t),
                          _infoChip('F${template.targetFat}',
                              Icons.water_drop_outlined, t),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(Icons.restaurant_menu_rounded,
                              size: 15, color: t.textMuted),
                          const SizedBox(width: 5),
                          Text(
                            '${template.meals.length} meals',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: t.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(Icons.water_drop_rounded,
                              size: 15, color: t.info),
                          const SizedBox(width: 5),
                          Text(
                            '${template.hydrationLiters.toStringAsFixed(1)}L hydration',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: t.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            isExpanded
                                ? Icons.keyboard_arrow_up_rounded
                                : Icons.keyboard_arrow_down_rounded,
                            color: t.textMuted,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isExpanded
                            ? 'Edit the start date and meal timing below.'
                            : 'Tap to review every meal and customize the schedule.',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: t.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isExpanded) ...[
                  const SizedBox(height: 16),
                  Container(height: 1, color: t.border.withOpacity(0.6)),
                  const SizedBox(height: 16),
                  if (template.description?.trim().isNotEmpty ?? false) ...[
                    _sectionLabel('Template Notes', t),
                    Text(
                      template.description!.trim(),
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: t.textSecondary,
                        height: 1.55,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  _sectionLabel('Plan Start Date', t),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isSaving
                          ? null
                          : () => _pickTemplateStartDate(template),
                      icon: Icon(Icons.event_available_rounded,
                          size: 18, color: t.brand),
                      label: Text(
                        _formatScheduleDate(startDate),
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: t.textPrimary,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: t.border),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _sectionLabel('Plan Summary', t),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _macroBadge(
                          '${template.targetCalories} kcal', t.brand, t),
                      _macroBadge('P${template.targetProtein}', t.success, t),
                      _macroBadge('C${template.targetCarbs}', t.info, t),
                      _macroBadge('F${template.targetFat}', t.warning, t),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: t.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: t.border),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.water_drop_rounded, size: 16, color: t.info),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '${template.hydrationLiters.toStringAsFixed(1)}L hydration target',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: t.textSecondary,
                            ),
                          ),
                        ),
                        Text(
                          '${template.meals.length} scheduled meals',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: t.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _sectionLabel('Meals', t),
                  ...List.generate(template.meals.length, (mealIndex) {
                    final meal = template.meals[mealIndex];
                    return Padding(
                      padding: EdgeInsets.only(
                          bottom:
                              mealIndex == template.meals.length - 1 ? 0 : 12),
                      child: _buildTemplateMealEditor(
                        meal: meal,
                        mealIndex: mealIndex,
                        timingController: timingControllers[mealIndex],
                        t: t,
                      ),
                    );
                  }),
                ],
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _isSaving ? null : () => _useTemplate(template),
                    style: FilledButton.styleFrom(
                      backgroundColor: t.brand,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: isSavingThisTemplate
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Use This Plan',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ).animate().fadeIn(duration: 250.ms, delay: (index * 40).ms),
    );
  }

  Widget _buildTemplateMealEditor({
    required Meal meal,
    required int mealIndex,
    required TextEditingController timingController,
    required dynamic t,
  }) {
    final mealColors = [
      t.brand,
      t.warning,
      t.info,
      t.accent,
      t.success,
      t.danger,
    ];
    final mealIcons = [
      Icons.wb_sunny_rounded,
      Icons.lunch_dining_rounded,
      Icons.local_cafe_rounded,
      Icons.restaurant_rounded,
      Icons.dinner_dining_rounded,
      Icons.bedtime_rounded,
    ];
    final color = mealColors[mealIndex % mealColors.length];
    final icon = mealIcons[mealIndex % mealIcons.length];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: t.surfaceAlt,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: t.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 20, color: color),
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
                    const SizedBox(height: 3),
                    Text(
                      '${meal.totalCalories} kcal · P${meal.totalProtein} · C${meal.totalCarbs} · F${meal.totalFat}',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: t.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Meal timing',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: t.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: timingController,
            enabled: !_isSaving,
            style: GoogleFonts.inter(color: t.textPrimary, fontSize: 14),
            decoration:
                _inputDecoration('e.g. 7:30 AM or 60 min before training', t)
                    .copyWith(
              prefixIcon: Icon(Icons.schedule_rounded, color: color, size: 18),
            ),
          ),
          if (meal.notes?.trim().isNotEmpty ?? false) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: t.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: t.border),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.notes_rounded, size: 16, color: color),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      meal.notes!.trim(),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: t.textSecondary,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          ...meal.foods.asMap().entries.map((entry) {
            return Padding(
              padding: EdgeInsets.only(
                  bottom: entry.key == meal.foods.length - 1 ? 0 : 10),
              child: _buildTemplateFoodRow(
                food: entry.value,
                accentColor: color,
                t: t,
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTemplateFoodRow({
    required FoodItem food,
    required Color accentColor,
    required dynamic t,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: t.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  food.name,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: t.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              if (food.quantity.isNotEmpty)
                Text(
                  food.quantity,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: t.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.local_fire_department_rounded,
                  size: 14, color: accentColor),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${food.calories} kcal · P${food.protein} · C${food.carbs} · F${food.fat}',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: t.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatScheduleDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  // ── Helper widgets ─────────────────────────────────────────────────────────

  Widget _buildNextButton({
    required String label,
    required bool enabled,
    required VoidCallback onPressed,
    required dynamic t,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: enabled ? onPressed : null,
          style: FilledButton.styleFrom(
            backgroundColor: enabled ? t.brand : t.border,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: enabled ? Colors.white : t.textMuted,
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String label, dynamic t) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: t.textSecondary,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, dynamic t) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(color: t.textMuted, fontSize: 14),
      filled: true,
      fillColor: t.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: t.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: t.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: t.brand, width: 1.5),
      ),
    );
  }

  Widget _compactField(
    String label,
    TextEditingController ctrl,
    TextInputType keyboardType,
    dynamic t,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: t.textMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: ctrl,
          keyboardType: keyboardType,
          style: GoogleFonts.inter(color: t.textPrimary, fontSize: 14),
          decoration: InputDecoration(
            filled: true,
            fillColor: t.surfaceAlt,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: t.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: t.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: t.brand, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _chipRow({
    required List<String> options,
    required List<String> labels,
    required String selected,
    required void Function(String) onSelected,
    required dynamic t,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(options.length, (i) {
        final isActive = selected == options[i];
        return ChoiceChip(
          label: Text(
            labels[i],
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isActive ? Colors.white : t.textSecondary,
            ),
          ),
          selected: isActive,
          onSelected: (_) => onSelected(options[i]),
          selectedColor: t.brand,
          backgroundColor: t.surface,
          side: BorderSide(color: isActive ? t.brand : t.border),
          showCheckmark: false,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        );
      }),
    );
  }

  Widget _macroBadge(String label, Color color, dynamic t) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _goalBadge(String goal, dynamic t) {
    final label = goal.replaceAll('_', ' ').toUpperCase();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: t.brand.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: t.brand,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _infoChip(String label, IconData icon, dynamic t) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: t.textMuted),
        const SizedBox(width: 3),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: t.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
