import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/extensions.dart';
import '../../providers/member_provider.dart';
import '../../widgets/glassmorphic_card.dart';
import '../../widgets/member_bottom_nav.dart';

/// Full diet plan detail screen for members.
class MemberDietScreen extends ConsumerWidget {
  const MemberDietScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.fitTheme;
    final planAsync = ref.watch(memberDietPlanProvider);

    return Scaffold(
      backgroundColor: t.background,
      bottomNavigationBar: const MemberBottomNav(),
      appBar: AppBar(
        backgroundColor: t.background,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: t.textSecondary,
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/member');
            }
          },
        ),
        title: Text(
          'My Diet Plan',
          style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: t.textPrimary),
        ),
      ),
      body: planAsync.when(
        loading: () => Center(
            child: CircularProgressIndicator(color: t.brand)),
        error: (e, _) => Center(
            child:
                Text('Error: $e', style: GoogleFonts.inter(color: t.danger))),
        data: (plan) {
          if (plan == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.restaurant_rounded,
                      size: 56, color: t.textMuted),
                  const SizedBox(height: 16),
                  Text('No diet plan assigned yet',
                      style: GoogleFonts.inter(
                          color: t.textSecondary, fontSize: 16)),
                  const SizedBox(height: 8),
                  Text('Ask your trainer to assign a diet plan',
                      style: GoogleFonts.inter(
                          color: t.textMuted, fontSize: 13)),
                ],
              ),
            );
          }

          final meals = plan.meals;

          return CustomScrollView(
            slivers: [
              // Plan Header
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(plan.name,
                          style: GoogleFonts.inter(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: t.textPrimary)),
                      const SizedBox(height: 4),
                      Text('Goal: ${plan.goal.replaceAll('_', ' ')}',
                          style: GoogleFonts.inter(
                              color: t.textSecondary, fontSize: 14)),
                    ],
                  ).animate().fadeIn(),
                ),
              ),

              // Macro targets
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    children: [
                      _MacroChip('${plan.targetCalories}', 'kcal',
                          t.warning),
                      const SizedBox(width: 8),
                      _MacroChip('${plan.targetProtein}g', 'protein',
                          t.brand),
                      const SizedBox(width: 8),
                      _MacroChip(
                          '${plan.targetCarbs}g', 'carbs', t.accent),
                      const SizedBox(width: 8),
                      _MacroChip(
                          '${plan.targetFat}g', 'fat', t.info),
                    ],
                  ).animate(delay: 100.ms).fadeIn(),
                ),
              ),

              // Meals
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                sliver: SliverToBoxAdapter(
                  child: Text('MEALS',
                      style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: t.textMuted,
                          letterSpacing: 1.2)),
                ),
              ),

              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) => _MealCard(
                      meal: meals[i], index: i, delay: i * 70),
                  childCount: meals.length,
                ),
              ),

              const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
            ],
          );
        },
      ),
    );
  }
}

class _MacroChip extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _MacroChip(this.value, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(
          children: [
            Text(value,
                style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: color)),
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 10, color: context.fitTheme.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _MealCard extends StatelessWidget {
  final dynamic meal;
  final int index;
  final int delay;
  const _MealCard(
      {required this.meal, required this.index, required this.delay});

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;
    final foods = meal.foods as List;
    final mealIcons = [
      Icons.wb_sunny_rounded,
      Icons.lunch_dining_rounded,
      Icons.coffee_rounded,
      Icons.dinner_dining_rounded,
      Icons.restaurant_rounded,
    ];
    final mealColors = [
      t.warning,
      t.brand,
      t.info,
      t.accent,
      t.danger,
    ];
    final icon = mealIcons[index % mealIcons.length];
    final color = mealColors[index % mealColors.length];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: GlassmorphicCard(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(meal.name as String,
                            style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: t.textPrimary)),
                        if ((meal.timing as String).isNotEmpty)
                          Text(meal.timing as String,
                              style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: t.textMuted)),
                      ],
                    ),
                  ),
                  Text('${meal.totalCalories} kcal',
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: color)),
                ],
              ),
              if (foods.isNotEmpty) ...[
                const SizedBox(height: 12),
                ...foods.map((food) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(food.name as String,
                                style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: t.textPrimary)),
                          ),
                          Text(food.quantity as String,
                              style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: t.textSecondary)),
                        ],
                      ),
                    )),
              ],
            ],
          ),
        ),
      ).animate(delay: Duration(milliseconds: delay)).fadeIn().slideY(begin: 0.04),
    );
  }
}
