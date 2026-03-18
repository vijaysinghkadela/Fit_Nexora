// lib/screens/tools/macro_calculator_screen.dart
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/extensions.dart';
import '../../widgets/glassmorphic_card.dart';

enum _Sex { male, female }
enum _ActivityLevel { sedentary, light, moderate, active, veryActive }
enum _Goal { lose, maintain, gain }

class MacroCalculatorScreen extends ConsumerStatefulWidget {
  const MacroCalculatorScreen({super.key});

  @override
  ConsumerState<MacroCalculatorScreen> createState() =>
      _MacroCalculatorScreenState();
}

class _MacroCalculatorScreenState
    extends ConsumerState<MacroCalculatorScreen> {
  final _ageCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();

  _Sex _sex = _Sex.male;
  _ActivityLevel _activity = _ActivityLevel.moderate;
  _Goal _goal = _Goal.maintain;

  _MacroResult? _result;

  @override
  void dispose() {
    _ageCtrl.dispose();
    _weightCtrl.dispose();
    _heightCtrl.dispose();
    super.dispose();
  }

  void _calculate() {
    final age = int.tryParse(_ageCtrl.text);
    final weight = double.tryParse(_weightCtrl.text);
    final height = double.tryParse(_heightCtrl.text);

    if (age == null || weight == null || height == null) {
      context.showSnackBar('Fill in all fields.', isError: true);
      return;
    }

    // Mifflin-St Jeor BMR
    final bmr = _sex == _Sex.male
        ? 10 * weight + 6.25 * height - 5 * age + 5
        : 10 * weight + 6.25 * height - 5 * age - 161;

    final activityMultiplier = switch (_activity) {
      _ActivityLevel.sedentary => 1.2,
      _ActivityLevel.light => 1.375,
      _ActivityLevel.moderate => 1.55,
      _ActivityLevel.active => 1.725,
      _ActivityLevel.veryActive => 1.9,
    };

    final tdee = bmr * activityMultiplier;

    final calories = switch (_goal) {
      _Goal.lose => tdee - 500,
      _Goal.maintain => tdee,
      _Goal.gain => tdee + 300,
    };

    // Standard macro split: P 30% / C 45% / F 25%
    final protein = (calories * 0.30) / 4;
    final carbs = (calories * 0.45) / 4;
    final fat = (calories * 0.25) / 9;
    final fiber = math.min(weight * 0.5, 38).toDouble();

    setState(() {
      _result = _MacroResult(
        bmr: bmr.round(),
        tdee: tdee.round(),
        calories: calories.round(),
        proteinG: protein.round(),
        carbsG: carbs.round(),
        fatG: fat.round(),
        fiberG: fiber.round(),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;

    return Scaffold(
      backgroundColor: t.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            backgroundColor: t.surface,
            title: Text(
              'Macro Calculator',
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: t.textPrimary,
              ),
            ),
            leading: IconButton(
              icon: Icon(Icons.arrow_back_rounded, color: t.textPrimary),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Inputs
                  GlassmorphicCard(
                    borderRadius: 24,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _ageCtrl,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                  decoration: const InputDecoration(labelText: 'Age', hintText: '25'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: _weightCtrl,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                                  decoration: const InputDecoration(labelText: 'Weight (kg)', hintText: '75'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: _heightCtrl,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                                  decoration: const InputDecoration(labelText: 'Height (cm)', hintText: '175'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _LabeledRow(
                            label: 'Sex',
                            child: SegmentedButton<_Sex>(
                              segments: const [
                                ButtonSegment(value: _Sex.male, label: Text('Male')),
                                ButtonSegment(value: _Sex.female, label: Text('Female')),
                              ],
                              selected: {_sex},
                              onSelectionChanged: (s) => setState(() => _sex = s.first),
                            ),
                          ),
                          const SizedBox(height: 14),
                          _LabeledRow(
                            label: 'Activity',
                            child: DropdownButtonFormField<_ActivityLevel>(
                              value: _activity,
                              dropdownColor: t.surfaceAlt,
                              style: TextStyle(color: t.textPrimary),
                              decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                              items: const [
                                DropdownMenuItem(value: _ActivityLevel.sedentary, child: Text('Sedentary (desk job)')),
                                DropdownMenuItem(value: _ActivityLevel.light, child: Text('Light (1–3 days/wk)')),
                                DropdownMenuItem(value: _ActivityLevel.moderate, child: Text('Moderate (3–5 days/wk)')),
                                DropdownMenuItem(value: _ActivityLevel.active, child: Text('Active (6–7 days/wk)')),
                                DropdownMenuItem(value: _ActivityLevel.veryActive, child: Text('Very Active (2× day)')),
                              ],
                              onChanged: (v) => setState(() => _activity = v!),
                            ),
                          ),
                          const SizedBox(height: 14),
                          _LabeledRow(
                            label: 'Goal',
                            child: SegmentedButton<_Goal>(
                              segments: const [
                                ButtonSegment(value: _Goal.lose, label: Text('Cut')),
                                ButtonSegment(value: _Goal.maintain, label: Text('Maintain')),
                                ButtonSegment(value: _Goal.gain, label: Text('Bulk')),
                              ],
                              selected: {_goal},
                              onSelectionChanged: (s) => setState(() => _goal = s.first),
                            ),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: _calculate,
                            style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                            child: Text('Calculate Macros', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Results
                  if (_result != null) ...[
                    const SizedBox(height: 24),
                    _ResultsPanel(result: _result!).animate().fadeIn(duration: 350.ms).slideY(begin: 0.08),
                  ],
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LabeledRow extends StatelessWidget {
  const _LabeledRow({required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: t.textMuted)),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

class _ResultsPanel extends StatelessWidget {
  const _ResultsPanel({required this.result});
  final _MacroResult result;

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'YOUR MACROS',
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: t.textMuted,
          ),
        ),
        const SizedBox(height: 12),
        GlassmorphicCard(
          borderRadius: 24,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _CalorieChip(label: 'BMR', value: '${result.bmr}', color: t.textMuted),
                    _CalorieChip(label: 'TDEE', value: '${result.tdee}', color: t.info),
                    _CalorieChip(label: 'Target', value: '${result.calories}', color: t.brand),
                  ],
                ),
                const SizedBox(height: 20),
                _MacroBar(label: 'Protein', grams: result.proteinG, color: t.brand, calories: result.proteinG * 4),
                const SizedBox(height: 10),
                _MacroBar(label: 'Carbs', grams: result.carbsG, color: t.warning, calories: result.carbsG * 4),
                const SizedBox(height: 10),
                _MacroBar(label: 'Fat', grams: result.fatG, color: t.success, calories: result.fatG * 9),
                const Divider(height: 24),
                _MacroBar(label: 'Fiber', grams: result.fiberG, color: t.info, calories: 0, showCalories: false),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CalorieChip extends StatelessWidget {
  const _CalorieChip({required this.label, required this.value, required this.color});
  final String label, value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w900, color: color)),
        Text(label, style: GoogleFonts.inter(fontSize: 11, color: context.fitTheme.textMuted)),
        Text('kcal', style: GoogleFonts.inter(fontSize: 10, color: context.fitTheme.textMuted)),
      ],
    );
  }
}

class _MacroBar extends StatelessWidget {
  const _MacroBar({
    required this.label,
    required this.grams,
    required this.color,
    required this.calories,
    this.showCalories = true,
  });
  final String label;
  final int grams;
  final Color color;
  final int calories;
  final bool showCalories;

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;
    return Row(
      children: [
        SizedBox(
          width: 72,
          child: Text(label,
              style: GoogleFonts.inter(
                  fontSize: 13, fontWeight: FontWeight.w700, color: t.textPrimary)),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: (grams / 300.0).clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: t.ringTrack,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          showCalories ? '$grams g · $calories kcal' : '$grams g',
          style: GoogleFonts.inter(fontSize: 12, color: t.textSecondary),
        ),
      ],
    );
  }
}

class _MacroResult {
  final int bmr, tdee, calories, proteinG, carbsG, fatG, fiberG;

  const _MacroResult({
    required this.bmr,
    required this.tdee,
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.fiberG,
  });
}
