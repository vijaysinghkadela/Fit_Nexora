import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/extensions.dart';
import '../../core/enums.dart';
import '../../models/client_profile_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/member_provider.dart';
import '../../services/claude_service.dart';
import '../../widgets/glassmorphic_card.dart';

/// Pro Plan: AI Workout & Diet suggestion screen using Claude.
class ProAiScreen extends ConsumerStatefulWidget {
  const ProAiScreen({super.key});

  @override
  ConsumerState<ProAiScreen> createState() => _ProAiScreenState();
}

class _ProAiScreenState extends ConsumerState<ProAiScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  String? _workoutResult;
  String? _dietResult;
  bool _workoutLoading = false;
  bool _dietLoading = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;
    return Scaffold(
      backgroundColor: t.background,
      appBar: AppBar(
        backgroundColor: t.background,
        leading: BackButton(color: t.textSecondary),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFFF8C00)]),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'AI',
                style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                    letterSpacing: 1),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'AI Advice',
              style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: t.textPrimary),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: const Color(0xFFFFD700),
          labelColor: const Color(0xFFFFD700),
          unselectedLabelColor: t.textMuted,
          tabs: const [
            Tab(text: '💪 Workout'),
            Tab(text: '🥗 Diet'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _AiTab(
            title: 'AI Workout Recommendation',
            subtitle:
                'Get a personalised workout plan based on your fitness goal, experience level, and available equipment.',
            icon: Icons.fitness_center_rounded,
            color: t.brand,
            result: _workoutResult,
            loading: _workoutLoading,
            onGenerate: _generateWorkout,
            presets: [
              'Give me a 3-day beginner workout plan for fat loss',
              'Recommend a muscle gain routine for intermediate gymers',
              'Design a full-body workout I can do 4 days a week',
            ],
          ),
          _AiTab(
            title: 'AI Diet Suggestion',
            subtitle:
                'Get personalised Indian meal ideas and macro targets based on your fitness goal.',
            icon: Icons.restaurant_rounded,
            color: t.accent,
            result: _dietResult,
            loading: _dietLoading,
            onGenerate: _generateDiet,
            presets: [
              'Suggest a high-protein Indian vegetarian meal plan',
              'What should I eat today to hit 2000 kcal with 150g protein?',
              'Give me a simple weekly diet for fat loss as an Indian',
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _generateWorkout([String? customPrompt]) async {
    setState(() {
      _workoutLoading = true;
      _workoutResult = null;
    });
    try {
      final result = await _callAI(customPrompt ??
          'Recommend a personalised workout plan for my fitness goal. Keep it practical and actionable.');
      setState(() => _workoutResult = result);
    } catch (e) {
      setState(() => _workoutResult = '⚠️ Error: $e');
    } finally {
      setState(() => _workoutLoading = false);
    }
  }

  Future<void> _generateDiet([String? customPrompt]) async {
    setState(() {
      _dietLoading = true;
      _dietResult = null;
    });
    try {
      final result = await _callAI(customPrompt ??
          'Suggest a basic Indian diet plan with breakfast, lunch, snack and dinner for my fitness goal. Include approximate calories and macros.');
      setState(() => _dietResult = result);
    } catch (e) {
      setState(() => _dietResult = '⚠️ Error: $e');
    } finally {
      setState(() => _dietLoading = false);
    }
  }

  Future<String> _callAI(String message) async {
    final user = ref.read(currentUserProvider).value;
    final membership = await ref.read(memberMembershipProvider.future);

    final now = DateTime.now();
    final profile = ClientProfile(
      id: user?.id ?? 'unknown',
      userId: user?.id,
      gymId: membership?.gymId ?? 'unknown',
      fullName: user?.fullName,
      goal: FitnessGoal.generalFitness,
      trainingLevel: TrainingLevel.beginner,
      daysPerWeek: 3,
      equipmentType: EquipmentType.fullGym,
      trainingTime: TrainingTime.morning,
      dietType: DietType.nonVegetarian,
      languagePreference: LanguagePreference.english,
      gymPlan: 'pro',
      aiQuotaRemaining: 100,
      createdAt: now,
      updatedAt: now,
    );

    return gymOSAI(
      client: profile,
      userRole: 'Member',
      userMessage: message,
    );
  }
}

// ─── AI Tab Widget ────────────────────────────────────────────────────────────

class _AiTab extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String? result;
  final bool loading;
  final Future<void> Function([String?]) onGenerate;
  final List<String> presets;

  const _AiTab({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.result,
    required this.loading,
    required this.onGenerate,
    required this.presets,
  });

  @override
  State<_AiTab> createState() => _AiTabState();
}

class _AiTabState extends State<_AiTab> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                widget.color.withOpacity(0.12),
                widget.color.withOpacity(0.04),
              ]),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: widget.color.withOpacity(0.25)),
            ),
            child: Row(
              children: [
                Icon(widget.icon, color: widget.color, size: 28),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.title,
                          style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: t.textPrimary)),
                      const SizedBox(height: 4),
                      Text(widget.subtitle,
                          style: GoogleFonts.inter(
                              fontSize: 12,
                              color: t.textSecondary,
                              height: 1.4)),
                    ],
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(),

          const SizedBox(height: 20),

          // Quick presets
          Text('QUICK PROMPTS',
              style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: t.textMuted,
                  letterSpacing: 1.2)),
          const SizedBox(height: 10),
          ...widget.presets.asMap().entries.map((entry) {
            final i = entry.key;
            final p = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () => widget.onGenerate(p),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: t.surfaceAlt,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: t.border),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.bolt_rounded,
                          color: t.brand, size: 16),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(p,
                            style: GoogleFonts.inter(
                                fontSize: 13,
                                color: t.textSecondary)),
                      ),
                      Icon(Icons.play_arrow_rounded,
                          color: t.textMuted, size: 18),
                    ],
                  ),
                ).animate(delay: (i * 60).ms).fadeIn(),
              ),
            );
          }),

          const SizedBox(height: 16),

          // Custom prompt field
          Text('CUSTOM PROMPT',
              style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: t.textMuted,
                  letterSpacing: 1.2)),
          const SizedBox(height: 10),
          TextFormField(
            controller: _ctrl,
            maxLines: 3,
            style: GoogleFonts.inter(
                color: t.textPrimary, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Ask anything about your workout or diet...',
              hintStyle:
                  GoogleFonts.inter(color: t.textMuted, fontSize: 13),
              filled: true,
              fillColor: t.surfaceAlt,
              contentPadding: const EdgeInsets.all(14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: t.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: widget.color, width: 2),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: t.border),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              onPressed: widget.loading
                  ? null
                  : () => widget.onGenerate(
                      _ctrl.text.trim().isNotEmpty ? _ctrl.text : null),
              style: FilledButton.styleFrom(
                backgroundColor: widget.color,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              icon: widget.loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.smart_toy_rounded, size: 20),
              label: Text(
                  widget.loading ? 'Generating...' : 'Ask AI',
                  style: GoogleFonts.inter(
                      fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),

          // Result
          if (widget.result != null) ...[
            const SizedBox(height: 20),
            GlassmorphicCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                                colors: [Color(0xFFFFD700), Color(0xFFFF8C00)]),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.smart_toy_rounded,
                              color: Colors.black, size: 14),
                        ),
                        const SizedBox(width: 10),
                        Text('AI Response',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: t.textPrimary,
                            )),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Divider(color: t.divider),
                    const SizedBox(height: 12),
                    Text(
                      widget.result!,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: t.textSecondary,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn().slideY(begin: 0.04),
          ],

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
