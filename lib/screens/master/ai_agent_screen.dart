import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/extensions.dart';
import '../../models/ai_generated_plan_model.dart';
import '../../providers/ai_agent_provider.dart';
import '../../widgets/glassmorphic_card.dart';

/// AI Agent Report screen — gym owners can generate comprehensive
/// AI-powered body analysis, workout plans, diet plans, and monthly reports.
class AiAgentScreen extends ConsumerStatefulWidget {
  final String memberId;
  final String gymId;
  final String memberName;

  const AiAgentScreen({
    super.key,
    required this.memberId,
    required this.gymId,
    this.memberName = 'Member',
  });

  @override
  ConsumerState<AiAgentScreen> createState() => _AiAgentScreenState();
}

class _AiAgentScreenState extends ConsumerState<AiAgentScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;
    final generatorState = ref.watch(aiReportGeneratorProvider);
    final plansAsync = ref.watch(
      aiGeneratedPlansProvider(
        (memberId: widget.memberId, gymId: widget.gymId),
      ),
    );

    return Scaffold(
      backgroundColor: t.background,
      appBar: AppBar(
        backgroundColor: t.surface,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'AI Agent Report',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: t.textPrimary,
              ),
            ),
            Text(
              widget.memberName,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: t.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          generatorState.isLoading
              ? Padding(
                  padding: const EdgeInsets.all(12),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: t.brand,
                    ),
                  ),
                )
              : IconButton(
                  onPressed: _generateReport,
                  icon: Icon(Icons.auto_awesome, color: t.brand),
                  tooltip: 'Generate AI Report',
                ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: t.brand,
          unselectedLabelColor: t.textMuted,
          indicatorColor: t.brand,
          labelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'Body', icon: Icon(Icons.accessibility_new, size: 18)),
            Tab(text: 'Workout', icon: Icon(Icons.fitness_center, size: 18)),
            Tab(text: 'Diet', icon: Icon(Icons.restaurant, size: 18)),
            Tab(text: 'Report', icon: Icon(Icons.assessment, size: 18)),
          ],
        ),
      ),
      body: generatorState.when(
        loading: () => _buildLoadingState(),
        error: (error, _) => _buildErrorState(error),
        data: (latestPlan) {
          return plansAsync.when(
            loading: () => _buildLoadingState(),
            error: (error, _) => _buildErrorState(error),
            data: (plans) {
              final plan = latestPlan ?? (plans.isNotEmpty ? plans.first : null);
              if (plan == null) {
                return _buildEmptyState();
              }
              return TabBarView(
                controller: _tabController,
                children: [
                  _BodyAnalysisTab(analysis: plan.bodyAnalysis),
                  _WorkoutPlanTab(workoutPlan: plan.workoutPlan),
                  _DietPlanTab(dietPlan: plan.dietPlan),
                  _MonthlyReportTab(report: plan.monthlyReport, plan: plan),
                ],
              );
            },
          );
        },
      ),
    );
  }

  void _generateReport() {
    ref.read(aiReportGeneratorProvider.notifier).generate(
          memberId: widget.memberId,
          gymId: widget.gymId,
        );
  }

  Widget _buildLoadingState() {
    final t = context.fitTheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: t.brand),
          const SizedBox(height: 24),
          Text(
            'AI Agent is analysing...',
            style: GoogleFonts.inter(
              color: t.textSecondary,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This may take 30-60 seconds',
            style: GoogleFonts.inter(color: t.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    final t = context.fitTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
            const SizedBox(height: 16),
            Text(
              error.toString().replaceAll('Exception: ', ''),
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: t.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => ref.read(aiReportGeneratorProvider.notifier).reset(),
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: t.brand,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final t = context.fitTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome, color: t.brand.withOpacity(0.5), size: 64),
            const SizedBox(height: 24),
            Text(
              'No AI Report Generated Yet',
              style: GoogleFonts.inter(
                color: t.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the ✨ button above to generate a comprehensive\n'
              'body analysis, workout plan, diet plan, and monthly report.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: t.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _generateReport,
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Generate AI Report'),
              style: ElevatedButton.styleFrom(
                backgroundColor: t.brand,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ).animate().fadeIn(duration: 400.ms),
      ),
    );
  }
}

// ─── TAB: BODY ANALYSIS ──────────────────────────────────────────────────────

class _BodyAnalysisTab extends StatelessWidget {
  final Map<String, dynamic>? analysis;
  const _BodyAnalysisTab({this.analysis});

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;
    if (analysis == null) return _emptyTab(context, 'No body analysis available');
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SectionCard(
          title: 'Somatotype',
          icon: Icons.accessibility_new,
          children: [
            _KpiRow(label: 'Body Type', value: analysis!['somatotype'] ?? '—'),
            _KpiRow(label: 'BMI Category', value: analysis!['bmi_category'] ?? '—'),
            _KpiRow(label: 'Recommended Focus', value: analysis!['recommended_focus'] ?? '—'),
            const SizedBox(height: 8),
            Text(
              analysis!['somatotype_explanation'] ?? '',
              style: GoogleFonts.inter(color: t.textMuted, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _SectionCard(
          title: 'Assessment',
          icon: Icons.insights,
          children: [
            Text(
              analysis!['fitness_assessment'] ?? '',
              style: GoogleFonts.inter(color: t.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 12),
            _BulletList(title: 'Key Strengths', items: _toStringList(analysis!['key_strengths']), color: Colors.greenAccent),
            _BulletList(title: 'Areas to Improve', items: _toStringList(analysis!['areas_to_improve']), color: Colors.orangeAccent),
            _BulletList(title: 'Risk Flags', items: _toStringList(analysis!['risk_flags']), color: Colors.redAccent),
          ],
        ),
      ].animate(interval: 100.ms).fadeIn(duration: 300.ms).slideY(begin: 0.05),
    );
  }
}

// ─── TAB: WORKOUT PLAN ───────────────────────────────────────────────────────

class _WorkoutPlanTab extends StatelessWidget {
  final Map<String, dynamic>? workoutPlan;
  const _WorkoutPlanTab({this.workoutPlan});

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;
    if (workoutPlan == null) return _emptyTab(context, 'No workout plan available');
    final weeks = workoutPlan!['weeks'] as List<dynamic>? ?? [];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SectionCard(
          title: workoutPlan!['plan_name'] ?? 'Workout Plan',
          icon: Icons.fitness_center,
          children: [
            _KpiRow(label: 'Structure', value: workoutPlan!['weekly_structure'] ?? '—'),
            _KpiRow(label: 'Progression', value: workoutPlan!['progression_logic'] ?? '—'),
          ],
        ),
        const SizedBox(height: 12),
        ...weeks.map((week) {
          final w = week as Map<String, dynamic>;
          final days = w['days'] as List<dynamic>? ?? [];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _SectionCard(
              title: 'Week ${w['week']} — ${w['theme'] ?? ''}',
              icon: Icons.calendar_view_week,
              children: [
                _KpiRow(label: 'Intensity', value: w['intensity'] ?? '—'),
                ...days.map((day) {
                  final d = day as Map<String, dynamic>;
                  final exercises = d['exercises'] as List<dynamic>? ?? [];
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${d['day']} — ${d['focus'] ?? ''}',
                          style: GoogleFonts.inter(
                            color: t.brand,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        ...exercises.map((ex) {
                          final e = ex as Map<String, dynamic>;
                          return Padding(
                            padding: const EdgeInsets.only(left: 12, top: 4),
                            child: Text(
                              '• ${e['name']}: ${e['sets']}×${e['reps']} (rest ${e['rest_seconds']}s)',
                              style: GoogleFonts.inter(color: t.textMuted, fontSize: 12),
                            ),
                          );
                        }),
                        if (d['cardio'] != null)
                          Padding(
                            padding: const EdgeInsets.only(left: 12, top: 4),
                            child: Text(
                              '🏃 ${d['cardio']}',
                              style: GoogleFonts.inter(color: t.textMuted, fontSize: 11),
                            ),
                          ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          );
        }),
        _SectionCard(
          title: 'Trainer Tips',
          icon: Icons.lightbulb_outline,
          children: [
            _BulletList(items: _toStringList(workoutPlan!['trainer_tips']), color: t.brand),
          ],
        ),
      ].animate(interval: 80.ms).fadeIn(duration: 300.ms).slideY(begin: 0.05),
    );
  }
}

// ─── TAB: DIET PLAN ──────────────────────────────────────────────────────────

class _DietPlanTab extends StatelessWidget {
  final Map<String, dynamic>? dietPlan;
  const _DietPlanTab({this.dietPlan});

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;
    if (dietPlan == null) return _emptyTab(context, 'No diet plan available');
    final template = dietPlan!['daily_template'] as Map<String, dynamic>? ?? {};
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SectionCard(
          title: 'Nutrition Targets',
          icon: Icons.restaurant,
          children: [
            _KpiRow(label: 'Calories', value: '${dietPlan!['calorie_target'] ?? '—'} kcal'),
            _KpiRow(label: 'Protein', value: '${dietPlan!['protein_g'] ?? '—'}g'),
            _KpiRow(label: 'Carbs', value: '${dietPlan!['carbs_g'] ?? '—'}g'),
            _KpiRow(label: 'Fats', value: '${dietPlan!['fats_g'] ?? '—'}g'),
            _KpiRow(label: 'Hydration', value: '${dietPlan!['hydration_target_litres'] ?? '—'}L'),
          ],
        ),
        const SizedBox(height: 12),
        ...template.entries.map((meal) {
          final mealData = meal.value as Map<String, dynamic>? ?? {};
          final items = mealData['items'] as List<dynamic>? ?? [];
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _SectionCard(
              title: '${_formatMealName(meal.key)} — ${mealData['time'] ?? ''}',
              icon: Icons.fastfood,
              children: items.isEmpty
                  ? [Text('No items', style: GoogleFonts.inter(color: t.textMuted, fontSize: 12))]
                  : items.map((item) {
                      final i = item as Map<String, dynamic>;
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '• ${i['food']} — ${i['quantity']} (${i['calories']} cal)',
                          style: GoogleFonts.inter(color: t.textMuted, fontSize: 12),
                        ),
                      );
                    }).toList(),
            ),
          );
        }),
        const SizedBox(height: 12),
        _SectionCard(
          title: 'Nutritionist Tips',
          icon: Icons.lightbulb_outline,
          children: [
            _BulletList(items: _toStringList(dietPlan!['nutritionist_tips']), color: t.brand),
          ],
        ),
      ].animate(interval: 80.ms).fadeIn(duration: 300.ms).slideY(begin: 0.05),
    );
  }

  String _formatMealName(String key) {
    return key.split('_').map((w) => w[0].toUpperCase() + w.substring(1)).join(' ');
  }
}

// ─── TAB: MONTHLY REPORT ─────────────────────────────────────────────────────

class _MonthlyReportTab extends StatelessWidget {
  final Map<String, dynamic>? report;
  final AiGeneratedPlan plan;
  const _MonthlyReportTab({this.report, required this.plan});

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;
    if (report == null) return _emptyTab(context, 'No monthly report available');
    final attendance = report!['attendance_analysis'] as Map<String, dynamic>? ?? {};
    final progress = report!['progress_assessment'] as Map<String, dynamic>? ?? {};
    final focuses = report!['next_month_focus'] as List<dynamic>? ?? [];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SectionCard(
          title: report!['report_month'] ?? 'Monthly Report',
          icon: Icons.assessment,
          children: [
            Text(
              report!['executive_summary'] ?? '',
              style: GoogleFonts.inter(color: t.textSecondary, fontSize: 13),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _SectionCard(
          title: 'Attendance',
          icon: Icons.event_available,
          children: [
            _KpiRow(label: 'Verdict', value: (attendance['verdict'] ?? '—').toString().toUpperCase()),
            Text(
              attendance['comment'] ?? '',
              style: GoogleFonts.inter(color: t.textMuted, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _SectionCard(
          title: 'Progress — ${progress['overall_rating'] ?? '?'}/10',
          icon: Icons.trending_up,
          children: [
            _BulletList(title: 'Positive', items: _toStringList(progress['positive_indicators']), color: Colors.greenAccent),
            _BulletList(title: 'Needs Attention', items: _toStringList(progress['areas_needing_attention']), color: Colors.orangeAccent),
          ],
        ),
        const SizedBox(height: 12),
        _SectionCard(
          title: 'Next Month Priorities',
          icon: Icons.flag,
          children: focuses.map((f) {
            final focus = f as Map<String, dynamic>;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: t.brand,
                    child: Text(
                      '${focus['priority']}',
                      style: GoogleFonts.inter(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(focus['focus'] ?? '', style: GoogleFonts.inter(color: t.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                        Text(focus['action'] ?? '', style: GoogleFonts.inter(color: t.textSecondary, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        GlassmorphicCard(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Icon(Icons.format_quote, color: t.brand, size: 28),
                const SizedBox(height: 8),
                Text(
                  report!['motivational_message'] ?? '',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: t.textSecondary,
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        _MetadataCard(plan: plan),
        const SizedBox(height: 24),
      ].animate(interval: 80.ms).fadeIn(duration: 300.ms).slideY(begin: 0.05),
    );
  }
}

// ─── SHARED WIDGETS ──────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  const _SectionCard({required this.title, required this.icon, required this.children});

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;
    return Container(
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: t.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: t.brand, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    color: t.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _KpiRow extends StatelessWidget {
  final String label;
  final String value;
  const _KpiRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(color: t.textSecondary, fontSize: 12)),
          Flexible(
            child: Text(
              _titleCase(value.replaceAll('_', ' ')),
              style: GoogleFonts.inter(color: t.textPrimary, fontSize: 12, fontWeight: FontWeight.w500),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

class _BulletList extends StatelessWidget {
  final String? title;
  final List<String> items;
  final Color color;
  const _BulletList({this.title, required this.items, this.color = Colors.white});

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          const SizedBox(height: 8),
          Text(title!, style: GoogleFonts.inter(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
        ...items.map((item) => Padding(
              padding: const EdgeInsets.only(top: 4, left: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• ', style: TextStyle(color: color, fontSize: 12)),
                  Expanded(
                    child: Text(item, style: GoogleFonts.inter(color: t.textMuted, fontSize: 12)),
                  ),
                ],
              ),
            )),
      ],
    );
  }
}

class _MetadataCard extends StatelessWidget {
  final AiGeneratedPlan plan;
  const _MetadataCard({required this.plan});

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;
    return Container(
      decoration: BoxDecoration(
        color: t.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: t.border),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Generation Metadata', style: GoogleFonts.inter(color: t.textMuted, fontSize: 10)),
          const SizedBox(height: 6),
          _KpiRow(label: 'Model', value: plan.modelUsed),
          _KpiRow(label: 'Tokens Used', value: '${plan.tokensUsed ?? '—'}'),
          _KpiRow(label: 'Time', value: plan.generationMs != null ? '${(plan.generationMs! / 1000).toStringAsFixed(1)}s' : '—'),
          _KpiRow(label: 'Generated', value: plan.createdAt?.toLocal().toString().split('.').first ?? '—'),
        ],
      ),
    );
  }
}

Widget _emptyTab(BuildContext context, String message) {
  final t = context.fitTheme;
  return Center(
    child: Text(
      message,
      style: GoogleFonts.inter(color: t.textMuted, fontSize: 14),
    ),
  );
}

List<String> _toStringList(dynamic value) {
  if (value is List) return value.map((e) => e.toString()).toList();
  return [];
}

String _titleCase(String text) {
  if (text.isEmpty) return text;
  return text.split(' ').map((word) {
    if (word.isEmpty) return word;
    return word[0].toUpperCase() + word.substring(1).toLowerCase();
  }).join(' ');
}
