import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../core/enums.dart';
import '../../widgets/glassmorphic_card.dart';

/// Diet/nutrition plan list + quick builder screen.
class DietPlansScreen extends ConsumerStatefulWidget {
  const DietPlansScreen({super.key});

  @override
  ConsumerState<DietPlansScreen> createState() => _DietPlansScreenState();
}

class _DietPlansScreenState extends ConsumerState<DietPlansScreen> {
  final _templates = const [
    _DietTemplate(
      name: 'High Protein — Non Veg',
      calories: 2200,
      type: 'Non-Veg',
      icon: Icons.restaurant_rounded,
      color: AppColors.error,
    ),
    _DietTemplate(
      name: 'Vegetarian Bulk',
      calories: 2500,
      type: 'Vegetarian',
      icon: Icons.eco_rounded,
      color: AppColors.success,
    ),
    _DietTemplate(
      name: 'Indian Fat Loss',
      calories: 1600,
      type: 'Indian',
      icon: Icons.local_fire_department_rounded,
      color: AppColors.warning,
    ),
    _DietTemplate(
      name: 'Keto Plan',
      calories: 1800,
      type: 'Keto',
      icon: Icons.spa_rounded,
      color: AppColors.primary,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          floating: true,
          backgroundColor: AppColors.bgDark,
          title: Text(
            'Diet Plans',
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          actions: [
            FilledButton.icon(
              onPressed: _showCreateDietSheet,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(
                'Create Plan',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.black,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(width: 16),
          ],
        ),

        // AI Generation Banner
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          sliver: SliverToBoxAdapter(
            child: _AiDietBanner(
              isLocked: true,
              onGenerate: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content:
                        Text('AI diet generation — upgrade to Pro to unlock'),
                    backgroundColor: AppColors.accent,
                  ),
                );
              },
            ),
          ),
        ),

        // Templates
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
          sliver: SliverToBoxAdapter(
            child: Text(
              'Diet Templates',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ).animate().fadeIn(),
          ),
        ),

        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 280,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.6,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildTemplateCard(_templates[index], index),
              childCount: _templates.length,
            ),
          ),
        ),

        // Macro targets quick info
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
          sliver: SliverToBoxAdapter(
            child: _buildMacroGuide(),
          ),
        ),

        // Empty state
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverToBoxAdapter(
            child: GlassmorphicCard(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.bgElevated,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.restaurant_menu_rounded,
                        size: 36,
                        color: AppColors.textMuted.withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No diet plans yet',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Create a plan manually or use AI to generate one',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ).animate(delay: 300.ms).fadeIn(),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 40)),
      ],
    );
  }

  Widget _buildTemplateCard(_DietTemplate template, int index) {
    final color = template.color;
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Creating ${template.name}…'),
            backgroundColor: color,
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Colored header strip
            Container(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    color.withValues(alpha: 0.2),
                    color.withValues(alpha: 0.06),
                  ],
                ),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(13)),
              ),
              child: Row(
                children: [
                  Icon(template.icon, color: color, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      template.name,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            // Tags
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
              child: Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  _buildTag('${template.calories} kcal', color),
                  _buildTag(template.type, AppColors.textMuted),
                ],
              ),
            ),
          ],
        ),
      ),
    )
        .animate(delay: (200 + index * 80).ms)
        .fadeIn()
        .slideY(begin: 0.08, end: 0);
  }

  Widget _buildMacroGuide() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline_rounded,
                  color: AppColors.accent, size: 18),
              const SizedBox(width: 8),
              Text(
                'Macro Split Guidelines',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildMacroItem('🔥 Fat Loss', 'P: 40% C: 30% F: 30%'),
              const SizedBox(width: 16),
              _buildMacroItem('💪 Muscle Gain', 'P: 30% C: 45% F: 25%'),
              const SizedBox(width: 16),
              _buildMacroItem('⚡ Maintenance', 'P: 30% C: 40% F: 30%'),
            ],
          ),
        ],
      ),
    ).animate(delay: 400.ms).fadeIn();
  }

  Widget _buildMacroItem(String title, String split) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary)),
          const SizedBox(height: 2),
          Text(split,
              style:
                  GoogleFonts.inter(fontSize: 10, color: AppColors.textMuted)),
        ],
      ),
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: color == AppColors.textMuted ? AppColors.textSecondary : color,
        ),
      ),
    );
  }

  void _showCreateDietSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CreateDietSheet(),
    );
  }
}

/// AI diet generation banner.
class _AiDietBanner extends StatelessWidget {
  final bool isLocked;
  final VoidCallback onGenerate;

  const _AiDietBanner({required this.isLocked, required this.onGenerate});

  @override
  Widget build(BuildContext context) {
    const color = AppColors.accent;
    final effectiveColor = isLocked ? AppColors.textMuted : color;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isLocked
              ? [AppColors.bgElevated, AppColors.bgCard]
              : [
                  color.withValues(alpha: 0.16),
                  color.withValues(alpha: 0.06),
                ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLocked ? AppColors.border : color.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: effectiveColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isLocked
                  ? Icons.lock_outline_rounded
                  : Icons.restaurant_menu_rounded,
              color: effectiveColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Generate AI Diet Plan',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isLocked
                        ? AppColors.textSecondary
                        : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  isLocked
                      ? 'Upgrade to Pro to unlock AI diet generation'
                      : 'Claude creates a personalized meal plan with Indian food database',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          isLocked
              ? OutlinedButton(
                  onPressed: onGenerate,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'Upgrade',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              : FilledButton(
                  onPressed: onGenerate,
                  style: FilledButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'Generate',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
        ],
      ),
    ).animate(delay: 150.ms).fadeIn().slideY(begin: 0.05, end: 0);
  }
}

/// Bottom sheet for creating a new diet plan.
class _CreateDietSheet extends StatefulWidget {
  @override
  State<_CreateDietSheet> createState() => _CreateDietSheetState();
}

class _CreateDietSheetState extends State<_CreateDietSheet> {
  final _nameController = TextEditingController();
  final _calorieController = TextEditingController(text: '2000');
  DietType _dietType = DietType.nonVegetarian;
  int _mealCount = 4;

  @override
  void dispose() {
    _nameController.dispose();
    _calorieController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: const BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: AppColors.glassBorder, width: 1),
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textMuted.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Create Diet Plan',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _nameController,
              style:
                  GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                labelText: 'Plan Name',
                hintText: 'e.g., High Protein Fat Loss',
                filled: true,
                fillColor: AppColors.bgInput,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: AppColors.accent, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _calorieController,
              keyboardType: TextInputType.number,
              style:
                  GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                labelText: 'Target Calories (kcal)',
                hintText: '2000',
                filled: true,
                fillColor: AppColors.bgInput,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: AppColors.accent, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<DietType>(
              value: _dietType,
              items: DietType.values
                  .map((d) => DropdownMenuItem(
                        value: d,
                        child: Text(d.label,
                            style: GoogleFonts.inter(
                                color: AppColors.textPrimary, fontSize: 14)),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _dietType = v!),
              decoration: InputDecoration(
                labelText: 'Diet Type',
                filled: true,
                fillColor: AppColors.bgInput,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
              ),
              dropdownColor: AppColors.bgElevated,
            ),
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Meals Per Day',
                    style: GoogleFonts.inter(
                        fontSize: 12, color: AppColors.textMuted)),
                const SizedBox(height: 8),
                Row(
                  children: [3, 4, 5, 6]
                      .map((m) => Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _mealCount = m),
                              child: Container(
                                margin: const EdgeInsets.only(right: 6),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: _mealCount == m
                                      ? AppColors.accent.withValues(alpha: 0.15)
                                      : AppColors.bgInput,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: _mealCount == m
                                        ? AppColors.accent
                                        : AppColors.border,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '$m',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: _mealCount == m
                                        ? FontWeight.w700
                                        : FontWeight.w400,
                                    color: _mealCount == m
                                        ? AppColors.accent
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ],
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'Created "${_nameController.text}" — ${_calorieController.text} kcal, $_mealCount meals'),
                      backgroundColor: AppColors.accent,
                    ),
                  );
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'Create Diet Plan',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    ).animate().slideY(begin: 0.05, end: 0, duration: 300.ms).fadeIn();
  }
}

class _DietTemplate {
  final String name;
  final int calories;
  final String type;
  final IconData icon;
  final Color color;

  const _DietTemplate({
    required this.name,
    required this.calories,
    required this.type,
    required this.icon,
    required this.color,
  });
}
