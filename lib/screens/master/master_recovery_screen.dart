import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../core/enums.dart';
import '../../models/client_profile_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/master_member_provider.dart';
import '../../providers/member_provider.dart';
import '../../services/claude_service.dart';
import '../../widgets/glassmorphic_card.dart';

/// Master: Smart Recovery Suggestions — AI-driven rest and recovery advice.
class MasterRecoveryScreen extends ConsumerStatefulWidget {
  const MasterRecoveryScreen({super.key});
  @override
  ConsumerState<MasterRecoveryScreen> createState() => _RecoveryState();
}

class _RecoveryState extends ConsumerState<MasterRecoveryScreen> {
  String? _advice;
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final scoreAsync = ref.watch(masterRecoveryScoreProvider);

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.bgDark,
        leading: BackButton(color: AppColors.textSecondary),
        title: Text('Smart Recovery', style: GoogleFonts.inter(
            fontSize: 19, fontWeight: FontWeight.w800,
            color: AppColors.textPrimary)),
      ),
      body: CustomScrollView(
        slivers: [
          // Recovery score hero
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            sliver: SliverToBoxAdapter(
              child: scoreAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (score) => _ScoreHero(score: score),
              ),
            ),
          ),

          // Recovery pillars
          _hdr('RECOVERY PILLARS'),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverToBoxAdapter(
              child: Column(children: [
                _pillar('😴', 'Sleep Optimisation',
                    'Aim for 7–9 hours of sleep in a cool, dark room. Sleep is when muscles rebuild.',
                    AppColors.info),
                const SizedBox(height: 10),
                _pillar('💧', 'Hydration',
                    'Drink 35ml per kg of bodyweight daily. Add electrolytes on heavy training days.',
                    AppColors.primary),
                const SizedBox(height: 10),
                _pillar('🥩', 'Protein Timing',
                    '20–40g protein within 2 hours of training to maximise muscle protein synthesis.',
                    AppColors.accent),
                const SizedBox(height: 10),
                _pillar('🧘', 'Active Recovery',
                    'Light walks, yoga, or stretching on rest days speed up recovery without damage.',
                    AppColors.success),
              ]).animate().fadeIn(),
            ),
          ),

          // AI advice
          _hdr('AI RECOVERY PLAN'),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
            sliver: SliverToBoxAdapter(
              child: Column(children: [
                if (_advice == null && !_loading)
                  SizedBox(
                    width: double.infinity, height: 52,
                    child: FilledButton.icon(
                      onPressed: _generateAdvice,
                      style: FilledButton.styleFrom(
                          backgroundColor: AppColors.success,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14))),
                      icon: const Icon(Icons.battery_charging_full_rounded, size: 20),
                      label: Text('Get My Recovery Plan',
                          style: GoogleFonts.inter(
                              fontSize: 15, fontWeight: FontWeight.w700)),
                    ).animate().fadeIn(),
                  ),
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(color: AppColors.success),
                  ),
                if (_advice != null)
                  GlassmorphicCard(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          const Icon(Icons.battery_charging_full_rounded,
                              color: AppColors.success, size: 20),
                          const SizedBox(width: 8),
                          Text('Your Recovery Plan', style: GoogleFonts.inter(
                              fontSize: 14, fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary)),
                          const Spacer(),
                          TextButton(
                            onPressed: () => setState(() => _advice = null),
                            child: Text('Refresh', style: GoogleFonts.inter(
                                fontSize: 12, color: AppColors.success)),
                          ),
                        ]),
                        const Divider(color: AppColors.divider),
                        Text(_advice!, style: GoogleFonts.inter(
                            fontSize: 14, color: AppColors.textSecondary, height: 1.6)),
                      ]),
                    ),
                  ).animate().fadeIn().slideY(begin: 0.04),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _hdr(String t) => SliverPadding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        sliver: SliverToBoxAdapter(
          child: Text(t, style: GoogleFonts.inter(fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textMuted, letterSpacing: 1.2)),
        ),
      );

  Widget _pillar(String emoji, String title, String body, Color c) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.withValues(alpha: 0.25)),
      ),
      child: Row(children: [
        Text(emoji, style: const TextStyle(fontSize: 26)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: GoogleFonts.inter(fontSize: 14,
              fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 3),
          Text(body, style: GoogleFonts.inter(fontSize: 12,
              color: AppColors.textSecondary, height: 1.4)),
        ])),
      ]),
    );
  }

  Future<void> _generateAdvice() async {
    setState(() => _loading = true);
    try {
      final user = ref.read(currentUserProvider).value;
      final membership = await ref.read(memberMembershipProvider.future);
      final score = await ref.read(masterRecoveryScoreProvider.future);
      final now = DateTime.now();
      final profile = ClientProfile(
        id: user?.id ?? 'unknown',
        userId: user?.id,
        gymId: membership?.gymId ?? 'unknown',
        fullName: user?.fullName,
        goal: FitnessGoal.generalFitness,
        trainingLevel: TrainingLevel.intermediate,
        daysPerWeek: 4,
        equipmentType: EquipmentType.fullGym,
        trainingTime: TrainingTime.morning,
        dietType: DietType.nonVegetarian,
        languagePreference: LanguagePreference.english,
        gymPlan: 'master',
        aiQuotaRemaining: 100,
        createdAt: now,
        updatedAt: now,
      );
      final advice = await gymOSAI(
        client: profile,
        userRole: 'Master Member',
        userMessage:
            'My current recovery score is $score/100. Give me a personalised '
            'recovery plan for today including sleep tips, nutrition adjustments, '
            'active recovery activities, and supplement timing. Be specific and practical.',
      );
      setState(() => _advice = advice);
    } catch (e) {
      setState(() => _advice = '⚠️ $e');
    } finally {
      setState(() => _loading = false);
    }
  }
}

// ─── Score Hero ───────────────────────────────────────────────────────────────

class _ScoreHero extends StatelessWidget {
  final int score;
  const _ScoreHero({required this.score});

  @override
  Widget build(BuildContext context) {
    final color = score >= 80 ? AppColors.success
        : score >= 50 ? AppColors.warning : AppColors.error;
    final label = score >= 80 ? '🟢 Fully Recovered — Ready to train hard'
        : score >= 65 ? '🟡 Moderate — Train at 80% intensity'
        : score >= 50 ? '🟠 Tired — Reduce volume today'
        : '🔴 Exhausted — Rest day recommended';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          color.withValues(alpha: 0.12),
          color.withValues(alpha: 0.04),
        ]),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        SizedBox(
          width: 80, height: 80,
          child: Stack(alignment: Alignment.center, children: [
            CircularProgressIndicator(
              value: score / 100,
              strokeWidth: 8,
              backgroundColor: AppColors.bgElevated,
              valueColor: AlwaysStoppedAnimation(color),
            ),
            Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('$score', style: GoogleFonts.inter(
                  fontSize: 22, fontWeight: FontWeight.w900, color: color)),
              Text('/100', style: GoogleFonts.inter(
                  fontSize: 10, color: AppColors.textMuted)),
            ]),
          ]),
        ),
        const SizedBox(width: 20),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Recovery Score', style: GoogleFonts.inter(
              fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          Text(label, style: GoogleFonts.inter(
              fontSize: 13, color: AppColors.textPrimary,
              fontWeight: FontWeight.w600, height: 1.4)),
        ])),
      ]),
    ).animate().fadeIn().slideY(begin: 0.04);
  }
}
