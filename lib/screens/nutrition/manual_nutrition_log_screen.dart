import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/extensions.dart';
import '../../config/theme.dart';

class ManualNutritionLogScreen extends ConsumerStatefulWidget {
  const ManualNutritionLogScreen({super.key});

  @override
  ConsumerState<ManualNutritionLogScreen> createState() =>
      _ManualNutritionLogScreenState();
}

class _ManualNutritionLogScreenState
    extends ConsumerState<ManualNutritionLogScreen> {
  final _formKey = GlobalKey<FormState>();

  final _mealNameCtrl = TextEditingController();
  final _caloriesCtrl = TextEditingController();
  final _proteinCtrl = TextEditingController();
  final _carbsCtrl = TextEditingController();
  final _fatCtrl = TextEditingController();
  final _tagsCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  String _selectedMealType = 'Breakfast';
  DateTime _selectedDate = DateTime.now();

  final _mealTypes = ['Breakfast', 'Lunch', 'Dinner', 'Snack'];

  @override
  void dispose() {
    _mealNameCtrl.dispose();
    _caloriesCtrl.dispose();
    _proteinCtrl.dispose();
    _carbsCtrl.dispose();
    _fatCtrl.dispose();
    _tagsCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      builder: (context, child) {
        final t = context.fitTheme;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: t.brand,
                  surface: t.surface,
                ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  void _logMeal() {
    if (!_formKey.currentState!.validate()) return;
    final t = context.fitTheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${_mealNameCtrl.text.isEmpty ? _selectedMealType : _mealNameCtrl.text} logged successfully',
          style: GoogleFonts.inter(fontWeight: FontWeight.w500),
        ),
        backgroundColor: t.accent,
        behavior: SnackBarBehavior.floating,
      ),
    );
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;

    return Scaffold(
      backgroundColor: t.background,
      appBar: AppBar(
        backgroundColor: t.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded,
              color: t.textPrimary, size: 20),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'Log Meal',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: t.textPrimary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _logMeal,
            child: Text(
              'Save',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: t.accent,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Meal Name
            _SectionLabel('Meal Name', t),
            const SizedBox(height: 8),
            TextFormField(
              controller: _mealNameCtrl,
              style: GoogleFonts.inter(
                  color: t.textPrimary, fontSize: 15),
              decoration: InputDecoration(
                hintText: 'e.g., Chicken Rice Bowl',
                hintStyle:
                    GoogleFonts.inter(color: t.textMuted, fontSize: 14),
                prefixIcon:
                    Icon(Icons.restaurant_rounded, color: t.textMuted, size: 20),
              ),
            ).animate().fadeIn(delay: 80.ms).slideY(begin: 0.06, end: 0),

            const SizedBox(height: 24),

            // Meal Type
            _SectionLabel('Meal Type', t),
            const SizedBox(height: 10),
            _MealTypeChips(
              types: _mealTypes,
              selected: _selectedMealType,
              onSelect: (v) => setState(() => _selectedMealType = v),
              themeTokens: t,
            ).animate().fadeIn(delay: 120.ms),

            const SizedBox(height: 24),

            // Macro Inputs 2x2 grid
            _SectionLabel('Nutrition Info', t),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _MacroInput(
                    controller: _caloriesCtrl,
                    label: 'Calories',
                    unit: 'kcal',
                    color: t.brand,
                    icon: Icons.local_fire_department_rounded,
                    themeTokens: t,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MacroInput(
                    controller: _proteinCtrl,
                    label: 'Protein',
                    unit: 'g',
                    color: t.info,
                    icon: Icons.fitness_center_rounded,
                    themeTokens: t,
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 160.ms).slideY(begin: 0.05, end: 0),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _MacroInput(
                    controller: _carbsCtrl,
                    label: 'Carbs',
                    unit: 'g',
                    color: t.warning,
                    icon: Icons.grain_rounded,
                    themeTokens: t,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MacroInput(
                    controller: _fatCtrl,
                    label: 'Fat',
                    unit: 'g',
                    color: t.danger,
                    icon: Icons.water_drop_rounded,
                    themeTokens: t,
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.05, end: 0),

            const SizedBox(height: 24),

            // Date picker
            _SectionLabel('Date', t),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 18, vertical: 16),
                decoration: BoxDecoration(
                  color: t.surfaceAlt,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: t.border),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_rounded,
                        color: t.brand, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      _selectedDate.formatted,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: t.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    Icon(Icons.chevron_right_rounded,
                        color: t.textMuted, size: 20),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 240.ms),

            const SizedBox(height: 24),

            // Tags
            _SectionLabel('Tags', t),
            const SizedBox(height: 8),
            TextFormField(
              controller: _tagsCtrl,
              style:
                  GoogleFonts.inter(color: t.textPrimary, fontSize: 15),
              decoration: InputDecoration(
                hintText: 'e.g., high-protein, post-workout',
                hintStyle:
                    GoogleFonts.inter(color: t.textMuted, fontSize: 14),
                prefixIcon:
                    Icon(Icons.label_outline_rounded, color: t.textMuted, size: 20),
              ),
            ).animate().fadeIn(delay: 280.ms),

            const SizedBox(height: 24),

            // Notes
            _SectionLabel('Notes', t),
            const SizedBox(height: 8),
            TextFormField(
              controller: _notesCtrl,
              maxLines: 3,
              style:
                  GoogleFonts.inter(color: t.textPrimary, fontSize: 15),
              decoration: InputDecoration(
                hintText: 'How did this meal make you feel?',
                hintStyle:
                    GoogleFonts.inter(color: t.textMuted, fontSize: 14),
                alignLabelWithHint: true,
              ),
            ).animate().fadeIn(delay: 320.ms),

            const SizedBox(height: 32),

            // LOG MEAL button
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [t.accent, t.accent.withOpacity(0.8)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: t.accent.withOpacity(0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _logMeal,
                  borderRadius: BorderRadius.circular(18),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    child: Center(
                      child: Text(
                        'LOG MEAL',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ).animate().fadeIn(delay: 380.ms).slideY(begin: 0.06, end: 0),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  final FitNexoraThemeTokens t;

  const _SectionLabel(this.text, this.t);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: t.textMuted,
        letterSpacing: 0.4,
      ),
    );
  }
}

class _MealTypeChips extends StatelessWidget {
  final List<String> types;
  final String selected;
  final ValueChanged<String> onSelect;
  final FitNexoraThemeTokens themeTokens;

  const _MealTypeChips({
    required this.types,
    required this.selected,
    required this.onSelect,
    required this.themeTokens,
  });

  @override
  Widget build(BuildContext context) {
    final t = themeTokens;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: types.map((type) {
          final isSelected = type == selected;
          return GestureDetector(
            onTap: () => onSelect(type),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 10),
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? t.brand.withOpacity(0.15)
                    : t.surfaceAlt,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: isSelected ? t.brand : t.border,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Text(
                type,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight:
                      isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? t.brand : t.textSecondary,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _MacroInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String unit;
  final Color color;
  final IconData icon;
  final FitNexoraThemeTokens themeTokens;

  const _MacroInput({
    required this.controller,
    required this.label,
    required this.unit,
    required this.color,
    required this.icon,
    required this.themeTokens,
  });

  @override
  Widget build(BuildContext context) {
    final t = themeTokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 15),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: t.surfaceAlt,
            borderRadius:
                const BorderRadius.vertical(bottom: Radius.circular(14)),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: TextFormField(
            controller: controller,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: t.textPrimary,
            ),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 14),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              hintText: '0',
              hintStyle: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: t.textMuted.withOpacity(0.5),
              ),
              suffix: Text(
                unit,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: t.textMuted,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
