import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/extensions.dart';
import '../../models/diet_plan_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/member_provider.dart';
import '../../widgets/glassmorphic_card.dart';
import '../../widgets/member_bottom_nav.dart';

String _formatDietDate(DateTime dt) {
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
  return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
}

/// Member's diet plan hub — shows trainer-assigned plans + self-created plans.
class MemberDietScreen extends ConsumerWidget {
  const MemberDietScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.fitTheme;
    final allPlansAsync = ref.watch(memberAllDietPlansProvider);

    return Scaffold(
      backgroundColor: t.background,
      bottomNavigationBar: const MemberBottomNav(),
      appBar: AppBar(
        backgroundColor: t.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: t.textSecondary, size: 20),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/member'),
        ),
        title: Text(
          'My Diet Plans',
          style: GoogleFonts.inter(
              fontSize: 20, fontWeight: FontWeight.w800, color: t.textPrimary),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: t.textMuted, size: 22),
            onPressed: () => ref.invalidate(memberAllDietPlansProvider),
          ),
        ],
      ),
      body: allPlansAsync.when(
        loading: () => Center(child: CircularProgressIndicator(color: t.brand)),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline_rounded, color: t.danger, size: 48),
              const SizedBox(height: 12),
              Text('Failed to load plans',
                  style:
                      GoogleFonts.inter(color: t.textSecondary, fontSize: 16)),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => ref.invalidate(memberAllDietPlansProvider),
                child: Text('Retry', style: TextStyle(color: t.brand)),
              ),
            ],
          ),
        ),
        data: (allPlans) {
          final assignedPlans =
              allPlans.where((p) => p.isTrainerAssigned).toList();
          final myPlans = allPlans.where((p) => p.isSelfCreated).toList();
          final latestPlan = allPlans.isNotEmpty ? allPlans.first : null;

          if (allPlans.isEmpty) {
            return _buildEmptyState(context, t);
          }

          return CustomScrollView(
            slivers: [
              // Hero card — Latest Plan
              if (latestPlan != null)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('LATEST UPDATED PLAN',
                            style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: t.textMuted,
                                letterSpacing: 1.2)),
                        const SizedBox(height: 10),
                        _PlanHeroCard(plan: latestPlan),
                      ],
                    ).animate().fadeIn(duration: 300.ms),
                  ),
                ),

              // Assigned Plans section
              if (assignedPlans.isNotEmpty) ...[
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      children: [
                        Container(
                          width: 4,
                          height: 18,
                          decoration: BoxDecoration(
                            color: t.warning,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text('ASSIGNED BY TRAINER',
                            style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: t.textMuted,
                                letterSpacing: 1.2)),
                      ],
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => _PlanSummaryCard(
                      plan: assignedPlans[i],
                      canDelete: false,
                      delay: i * 60,
                    ),
                    childCount: assignedPlans.length,
                  ),
                ),
              ],

              // My Plans section
              if (myPlans.isNotEmpty) ...[
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      children: [
                        Container(
                          width: 4,
                          height: 18,
                          decoration: BoxDecoration(
                            color: t.accent,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text('MY PLANS',
                            style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: t.textMuted,
                                letterSpacing: 1.2)),
                      ],
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => _PlanSummaryCard(
                      plan: myPlans[i],
                      canDelete: true,
                      delay: i * 60,
                      onDeleted: () =>
                          ref.invalidate(memberAllDietPlansProvider),
                    ),
                    childCount: myPlans.length,
                  ),
                ),
              ],

              const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, dynamic t) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: t.brand.withOpacity(0.08),
                shape: BoxShape.circle,
                border: Border.all(color: t.brand.withOpacity(0.2), width: 1.5),
              ),
              child: Icon(Icons.restaurant_menu_rounded,
                  size: 52, color: t.brand.withOpacity(0.7)),
            ),
            const SizedBox(height: 24),
            Text(
              'No diet plans yet',
              style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: t.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              'Build your first personalized plan\nin 3 easy steps.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  fontSize: 14, color: t.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => context.push('/member/diet/create'),
              icon: const Icon(Icons.add_rounded, size: 20),
              label: Text(
                'Create My Diet Plan',
                style: GoogleFonts.inter(
                    fontSize: 15, fontWeight: FontWeight.w700),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: t.brand,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18)),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'or ask your trainer to assign a plan',
              style: GoogleFonts.inter(fontSize: 12, color: t.textMuted),
            ),
          ],
        ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05),
      ),
    );
  }
}

// ─── Hero Card ────────────────────────────────────────────────────────────────

class _PlanHeroCard extends StatelessWidget {
  final DietPlan plan;
  const _PlanHeroCard({required this.plan});

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;
    final isTrainer = plan.isTrainerAssigned;
    final badgeColor = isTrainer ? t.warning : t.accent;
    final badgeLabel = isTrainer ? '🏋️ Trainer Plan' : '✨ My Plan';

    return GlassmorphicCard(
      borderRadius: 24,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => _showPlanDetail(context, plan),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Source badge + date
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: badgeColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: badgeColor.withOpacity(0.35)),
                    ),
                    child: Text(badgeLabel,
                        style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: badgeColor)),
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (plan.startDate != null)
                        Text(
                          'Starts ${_formatDietDate(plan.startDate!)}',
                          style: GoogleFonts.inter(
                              fontSize: 11, color: t.textSecondary),
                        ),
                      Text(
                        'Updated ${_formatDietDate(plan.updatedAt)}',
                        style:
                            GoogleFonts.inter(fontSize: 11, color: t.textMuted),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Plan name
              Text(
                plan.name,
                style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: t.textPrimary),
              ),
              const SizedBox(height: 4),
              Text(
                'Goal: ${plan.goal.replaceAll('_', ' ').toUpperCase()}',
                style: GoogleFonts.inter(fontSize: 12, color: t.textSecondary),
              ),
              const SizedBox(height: 16),
              // Macro row
              Row(
                children: [
                  _MacroChip('${plan.targetCalories}', 'kcal', t.warning),
                  const SizedBox(width: 6),
                  _MacroChip('${plan.targetProtein}g', 'protein', t.brand),
                  const SizedBox(width: 6),
                  _MacroChip('${plan.targetCarbs}g', 'carbs', t.info),
                  const SizedBox(width: 6),
                  _MacroChip('${plan.targetFat}g', 'fat', t.accent),
                ],
              ),
              const SizedBox(height: 14),
              // View detail
              Row(
                children: [
                  Icon(Icons.water_drop_rounded, size: 14, color: t.info),
                  const SizedBox(width: 4),
                  Text('${plan.hydrationLiters}L hydration',
                      style:
                          GoogleFonts.inter(fontSize: 12, color: t.textMuted)),
                  const Spacer(),
                  Text('View full plan →',
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: t.brand)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPlanDetail(BuildContext context, DietPlan plan) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PlanDetailSheet(plan: plan),
    );
  }
}

// ─── Summary Card ─────────────────────────────────────────────────────────────

class _PlanSummaryCard extends ConsumerWidget {
  final DietPlan plan;
  final bool canDelete;
  final int delay;
  final VoidCallback? onDeleted;

  const _PlanSummaryCard({
    required this.plan,
    required this.canDelete,
    this.delay = 0,
    this.onDeleted,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.fitTheme;
    final isTrainer = plan.isTrainerAssigned;
    final dotColor = isTrainer ? t.warning : t.accent;

    Widget card = Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      child: GlassmorphicCard(
        borderRadius: 18,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => _PlanDetailSheet(plan: plan),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Color dot
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(plan.name,
                          style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: t.textPrimary)),
                      const SizedBox(height: 3),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          _GoalChip(plan.goal),
                          if (plan.startDate != null)
                            Text(
                              'Starts ${_formatDietDate(plan.startDate!)}',
                              style: GoogleFonts.inter(
                                  fontSize: 12, color: t.textSecondary),
                            ),
                          Text(
                            '${plan.targetCalories} kcal',
                            style: GoogleFonts.inter(
                                fontSize: 12, color: t.textMuted),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: t.textMuted, size: 20),
              ],
            ),
          ),
        ),
      ),
    );

    if (canDelete) {
      card = Dismissible(
        key: ValueKey(plan.id),
        direction: DismissDirection.endToStart,
        background: Container(
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
          decoration: BoxDecoration(
            color: t.danger.withOpacity(0.15),
            borderRadius: BorderRadius.circular(18),
          ),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          child: Icon(Icons.delete_outline_rounded, color: t.danger, size: 24),
        ),
        confirmDismiss: (_) async {
          return await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: t.surface,
              title: Text('Delete Plan',
                  style: GoogleFonts.inter(color: t.textPrimary)),
              content: Text('Are you sure you want to delete "${plan.name}"?',
                  style: GoogleFonts.inter(color: t.textSecondary)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text('Cancel', style: TextStyle(color: t.textMuted)),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text('Delete', style: TextStyle(color: t.danger)),
                ),
              ],
            ),
          );
        },
        onDismissed: (_) async {
          final db = ref.read(databaseServiceProvider);
          await db.deleteDietPlan(plan.id);
          onDeleted?.call();
        },
        child: card,
      );
    }

    return card
        .animate(delay: Duration(milliseconds: delay))
        .fadeIn()
        .slideY(begin: 0.04);
  }
}

// ─── Plan Detail Sheet ────────────────────────────────────────────────────────

class _PlanDetailSheet extends StatelessWidget {
  final DietPlan plan;
  const _PlanDetailSheet({required this.plan});

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;
    final meals = plan.meals;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: t.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: CustomScrollView(
                controller: controller,
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
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
                                  color: t.textSecondary, fontSize: 13)),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              if (plan.startDate != null)
                                _PlanMetaPill(
                                  icon: Icons.event_available_rounded,
                                  label:
                                      'Starts ${_formatDietDate(plan.startDate!)}',
                                  color: t.brand,
                                ),
                              _PlanMetaPill(
                                icon: Icons.update_rounded,
                                label:
                                    'Updated ${_formatDietDate(plan.updatedAt)}',
                                color: t.textMuted,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              _MacroChip(
                                  '${plan.targetCalories}', 'kcal', t.warning),
                              const SizedBox(width: 6),
                              _MacroChip(
                                  '${plan.targetProtein}g', 'protein', t.brand),
                              const SizedBox(width: 6),
                              _MacroChip(
                                  '${plan.targetCarbs}g', 'carbs', t.info),
                              const SizedBox(width: 6),
                              _MacroChip('${plan.targetFat}g', 'fat', t.accent),
                            ],
                          ),
                          const SizedBox(height: 20),
                          if (meals.isNotEmpty)
                            Text('MEALS',
                                style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: t.textMuted,
                                    letterSpacing: 1.2)),
                        ],
                      ),
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) =>
                          _MealCard(meal: meals[i], index: i, delay: i * 60),
                      childCount: meals.length,
                    ),
                  ),
                  const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Helper Widgets ───────────────────────────────────────────────────────────

class _PlanMetaPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _PlanMetaPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
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
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(
          children: [
            Text(value,
                style: GoogleFonts.inter(
                    fontSize: 14, fontWeight: FontWeight.w900, color: color)),
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 9, color: context.fitTheme.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _GoalChip extends StatelessWidget {
  final String goal;
  const _GoalChip(this.goal);

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;
    final label = goal.replaceAll('_', ' ');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: t.brand.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: t.brand.withOpacity(0.25)),
      ),
      child: Text(label,
          style: GoogleFonts.inter(
              fontSize: 10, fontWeight: FontWeight.w600, color: t.brand)),
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
    final mealColors = [t.warning, t.brand, t.info, t.accent, t.danger];
    final icon = mealIcons[index % mealIcons.length];
    final color = mealColors[index % mealColors.length];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
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
                                  fontSize: 11, color: t.textMuted)),
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
                                  color: color, shape: BoxShape.circle)),
                          const SizedBox(width: 10),
                          Expanded(
                              child: Text(food.name as String,
                                  style: GoogleFonts.inter(
                                      fontSize: 13, color: t.textPrimary))),
                          Text(food.quantity as String,
                              style: GoogleFonts.inter(
                                  fontSize: 12, color: t.textSecondary)),
                        ],
                      ),
                    )),
              ],
            ],
          ),
        ),
      )
          .animate(delay: Duration(milliseconds: delay))
          .fadeIn()
          .slideY(begin: 0.04),
    );
  }
}
