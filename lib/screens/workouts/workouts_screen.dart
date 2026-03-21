import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/theme.dart';
import '../../core/enums.dart';
import '../../core/extensions.dart';
import '../../models/workout_plan_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/gym_provider.dart';
import '../../widgets/glassmorphic_card.dart';

// ─── Provider ─────────────────────────────────────────────────────────────────

final gymWorkoutPlansProvider =
    FutureProvider.autoDispose<List<WorkoutPlan>>((ref) async {
  final gym = ref.watch(selectedGymProvider);
  if (gym == null) return [];
  return ref.read(databaseServiceProvider).getWorkoutPlansForGym(gym.id);
});

/// Workout plan list + quick builder screen.
class WorkoutsScreen extends ConsumerStatefulWidget {
  const WorkoutsScreen({super.key});

  @override
  ConsumerState<WorkoutsScreen> createState() => _WorkoutsScreenState();
}

class _WorkoutsScreenState extends ConsumerState<WorkoutsScreen> {
  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;
    final subscriptionAsync = ref.watch(currentGymSubscriptionProvider);
    final hasAiAccess = subscriptionAsync.value?.hasAiAccess ?? false;
    final plansAsync = ref.watch(gymWorkoutPlansProvider);

    // Template data defined here so colors resolve from theme
    final templates = [
      _PlanTemplate(
        name: 'PPL — Push Pull Legs',
        days: 6,
        goal: 'Muscle Gain',
        level: 'Intermediate',
        icon: Icons.fitness_center_rounded,
        color: t.brand,
      ),
      _PlanTemplate(
        name: 'Upper/Lower Split',
        days: 4,
        goal: 'Strength',
        level: 'Intermediate',
        icon: Icons.sports_gymnastics_rounded,
        color: t.accent,
      ),
      _PlanTemplate(
        name: 'Full Body 3x',
        days: 3,
        goal: 'General Fitness',
        level: 'Beginner',
        icon: Icons.accessibility_new_rounded,
        color: t.info,
      ),
      _PlanTemplate(
        name: 'Body Recomp',
        days: 5,
        goal: 'Fat Loss + Muscle',
        level: 'Advanced',
        icon: Icons.local_fire_department_rounded,
        color: t.warning,
      ),
    ];

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          floating: true,
          leading: BackButton(
            onPressed: () => context.canPop() ? context.pop() : context.go('/dashboard'),
          ),
          backgroundColor: t.background,
          title: Text(
            'Workout Plans',
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: t.textPrimary,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.calendar_month_rounded),
              color: t.textPrimary,
              tooltip: 'Workout Calendar',
              onPressed: () => context.push('/workout/calendar'),
            ),
            FilledButton.icon(
              onPressed: _showCreatePlanSheet,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(
                'Create Plan',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: t.brand,
                foregroundColor: Colors.white,
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
            child: _AiGenerationBanner(
              title: 'Generate AI Workout Plan',
              subtitle:
                  'Claude creates a personalized plan based on client goals, level & equipment',
              isLocked: !hasAiAccess,
              color: t.brand,
              icon: Icons.fitness_center_rounded,
              onGenerate: () {
                if (!hasAiAccess) {
                  context.push('/pricing');
                  return;
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('AI workout generation started…'),
                    backgroundColor: t.brand,
                  ),
                );
              },
            ),
          ),
        ),

        // Templates section
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
          sliver: SliverToBoxAdapter(
            child: Text(
              'Quick Start Templates',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: t.textPrimary,
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
              childAspectRatio: 1.55,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildTemplateCard(templates[index], index, t),
              childCount: templates.length,
            ),
          ),
        ),

        // Recent plans header
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
          sliver: SliverToBoxAdapter(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Plans',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: t.textPrimary,
                  ),
                ),
                TextButton(
                  onPressed: () => context.push('/workout/history'),
                  child: const Text('View All'),
                ),
              ],
            ),
          ),
        ),

        // Recent plans list
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
          sliver: SliverToBoxAdapter(
            child: plansAsync.when(
              loading: () => const Center(
                  child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              )),
              error: (_, __) => GlassmorphicCard(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Could not load plans.',
                    style: GoogleFonts.inter(color: t.textMuted),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              data: (plans) {
                if (plans.isEmpty) {
                  return GlassmorphicCard(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: t.surface,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              Icons.fitness_center_rounded,
                              size: 36,
                              color: t.textMuted.withOpacity(0.5),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No workout plans yet',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: t.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Create a plan manually or use a template to get started',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: t.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ).animate(delay: 300.ms).fadeIn();
                }

                return Column(
                  children: plans.asMap().entries.map((entry) {
                    final i = entry.key;
                    final plan = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _PlanListTile(plan: plan, t: t)
                          .animate(delay: Duration(milliseconds: 60 * i))
                          .fadeIn()
                          .slideY(begin: 0.04, end: 0),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTemplateCard(_PlanTemplate template, int index, FitNexoraThemeTokens t) {
    final color = template.color;
    return GestureDetector(
      onTap: () => _showCreatePlanSheet(
        prefillName: template.name,
        prefillGoal: template.goal,
        prefillDays: template.days,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: t.surfaceAlt,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.3)),
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
                    color.withOpacity(0.2),
                    color.withOpacity(0.06),
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
                        color: t.textPrimary,
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
                  _buildTag('${template.days}d/wk', color, t),
                  _buildTag(template.goal, t.textMuted, t),
                  _buildTag(template.level, t.textMuted, t),
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

  Widget _buildTag(String text, Color color, FitNexoraThemeTokens t) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: color == t.textMuted ? t.textSecondary : color,
        ),
      ),
    );
  }

  void _showCreatePlanSheet({
    String? prefillName,
    String? prefillGoal,
    int? prefillDays,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CreatePlanSheet(
        prefillName: prefillName,
        prefillGoal: prefillGoal,
        prefillDays: prefillDays,
      ),
    );
  }
}

/// AI Generation banner widget — shown at the top of Workouts and Diet screens.
class _AiGenerationBanner extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isLocked;
  final Color color;
  final IconData icon;
  final VoidCallback onGenerate;

  const _AiGenerationBanner({
    required this.title,
    required this.subtitle,
    required this.isLocked,
    required this.color,
    required this.icon,
    required this.onGenerate,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;
    final effectiveColor = isLocked ? t.textMuted : color;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isLocked
              ? [
                  t.surface,
                  t.surfaceAlt,
                ]
              : [
                  color.withOpacity(0.16),
                  color.withOpacity(0.06),
                ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLocked ? t.border : color.withOpacity(0.35),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: effectiveColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isLocked ? Icons.lock_outline_rounded : Icons.auto_awesome,
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
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isLocked ? t.textSecondary : t.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  isLocked
                      ? 'Upgrade to Pro to unlock AI plan generation'
                      : subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: t.textMuted,
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
                    foregroundColor: t.brand,
                    side: BorderSide(color: t.brand),
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
                    foregroundColor: Colors.white,
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

/// Bottom sheet for creating a new workout plan.
class _CreatePlanSheet extends ConsumerStatefulWidget {
  const _CreatePlanSheet({this.prefillName, this.prefillGoal, this.prefillDays});
  final String? prefillName;
  final String? prefillGoal;
  final int? prefillDays;

  @override
  ConsumerState<_CreatePlanSheet> createState() => _CreatePlanSheetState();
}

class _CreatePlanSheetState extends ConsumerState<_CreatePlanSheet> {
  late final TextEditingController _nameController;
  FitnessGoal _goal = FitnessGoal.generalFitness;
  int _durationWeeks = 8;
  int _daysPerWeek = 4;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.prefillName ?? '');
    if (widget.prefillDays != null) _daysPerWeek = widget.prefillDays!;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      context.showSnackBar('Please enter a plan name.', isError: true);
      return;
    }
    setState(() => _saving = true);
    try {
      final gym = ref.read(selectedGymProvider);
      if (gym == null) {
        context.showSnackBar('No gym selected.', isError: true);
        return;
      }
      await ref.read(databaseServiceProvider).createWorkoutPlan({
        'gym_id': gym.id,
        'name': name,
        'goal': _goal.value,
        'duration_weeks': _durationWeeks,
        'days': List.generate(
            _daysPerWeek, (i) => {'day': i + 1, 'exercises': []}),
        'status': 'active',
        'is_template': false,
      });
      ref.invalidate(gymWorkoutPlansProvider);
      if (mounted) {
        final messenger = ScaffoldMessenger.of(context);
        final brand = context.fitTheme.brand;
        Navigator.pop(context);
        messenger.showSnackBar(SnackBar(
          content: Text('Plan "$name" created!'),
          backgroundColor: brand,
        ));
      }
    } catch (e) {
      if (mounted) {
        context.showSnackBar('Failed to create plan: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: BoxDecoration(
        color: t.surfaceAlt,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: t.glassBorder, width: 1),
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
                  color: t.textMuted.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            Text(
              'Create Workout Plan',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: t.textPrimary,
              ),
            ),
            const SizedBox(height: 20),

            // Plan name
            TextFormField(
              controller: _nameController,
              style: GoogleFonts.inter(color: t.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                labelText: 'Plan Name',
                hintText: 'e.g., Hypertrophy Phase 1',
                filled: true,
                fillColor: t.surfaceMuted,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: t.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: t.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: t.brand, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Goal dropdown
            DropdownButtonFormField<FitnessGoal>(
              value: _goal,
              items: FitnessGoal.values
                  .map((g) => DropdownMenuItem(
                        value: g,
                        child: Text(g.label,
                            style: GoogleFonts.inter(
                                color: t.textPrimary, fontSize: 14)),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _goal = v!),
              decoration: InputDecoration(
                labelText: 'Primary Goal',
                filled: true,
                fillColor: t.surfaceMuted,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: t.border),
                ),
              ),
              dropdownColor: t.surface,
            ),
            const SizedBox(height: 16),

            // Duration
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Duration',
                    style: GoogleFonts.inter(
                        fontSize: 12, color: t.textMuted)),
                const SizedBox(height: 8),
                Row(
                  children: [4, 6, 8, 12]
                      .map((w) => Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _durationWeeks = w),
                              child: Container(
                                margin: const EdgeInsets.only(right: 6),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: _durationWeeks == w
                                      ? t.brand.withOpacity(0.15)
                                      : t.surfaceMuted,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: _durationWeeks == w
                                        ? t.brand
                                        : t.border,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '${w}wk',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: _durationWeeks == w
                                        ? FontWeight.w700
                                        : FontWeight.w400,
                                    color: _durationWeeks == w
                                        ? t.brand
                                        : t.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Days per week
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Training Days / Week',
                    style: GoogleFonts.inter(
                        fontSize: 12, color: t.textMuted)),
                const SizedBox(height: 8),
                Row(
                  children: List.generate(6, (i) {
                    final d = i + 2;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _daysPerWeek = d),
                        child: Container(
                          margin: EdgeInsets.only(right: i < 5 ? 6 : 0),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _daysPerWeek == d
                                ? t.brand.withOpacity(0.15)
                                : t.surfaceMuted,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _daysPerWeek == d
                                  ? t.brand
                                  : t.border,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '$d',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: _daysPerWeek == d
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                              color: _daysPerWeek == d
                                  ? t.brand
                                  : t.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Create button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: t.brand,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'Create Plan',
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

class _PlanTemplate {
  final String name;
  final int days;
  final String goal;
  final String level;
  final IconData icon;
  final Color color;

  const _PlanTemplate({
    required this.name,
    required this.days,
    required this.goal,
    required this.level,
    required this.icon,
    required this.color,
  });
}

class _PlanListTile extends StatelessWidget {
  const _PlanListTile({required this.plan, required this.t});
  final WorkoutPlan plan;
  final FitNexoraThemeTokens t;

  @override
  Widget build(BuildContext context) {
    return GlassmorphicCard(
      borderRadius: 14,
      applyBlur: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: t.brand.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.fitness_center_rounded,
                  color: t.brand, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plan.name,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: t.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${plan.durationWeeks}wk · ${plan.trainingDaysCount}d/wk · ${plan.goal.replaceAll('_', ' ')}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: t.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: t.success.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                plan.status.label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: t.success,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
