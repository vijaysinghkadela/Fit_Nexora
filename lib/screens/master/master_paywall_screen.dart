import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants.dart';
import '../../providers/gym_provider.dart';

/// Master Paywall — shown when the user doesn't have Master tier.
class MasterPaywallScreen extends ConsumerWidget {
  const MasterPaywallScreen({super.key});

  static const _gold = Color(0xFFFFD700);
  static const _orange = Color(0xFFFF6F00);
  static const _deep = Color(0xFFB71C1C);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gym = ref.watch(selectedGymProvider);

    final features = [
      (Icons.smart_toy_rounded,      'Full AI Fitness Coach',         'personalised daily coaching powered by Claude Opus'),
      (Icons.bolt_rounded,           'Daily Adaptive Workout Plan',   'AI regenerates your plan every day based on fatigue & goal'),
      (Icons.restaurant_menu_rounded,'AI Nutrition Coach',            'Conversational AI that plans meals and adjusts macros in real time'),
      (Icons.document_scanner_rounded,'AI Food Scanner Analysis',     'Point camera at your food — AI estimates calories & macros'),
      (Icons.battery_charging_full_rounded,'Smart Recovery Suggestions','Personalised rest, sleep, and deload advice based on your data'),
      (Icons.analytics_rounded,      'Advanced Analytics Dashboard',  'Deep performance graphs, PRs, trends, and AI insights'),
      (Icons.video_call_rounded,     'Live Trainer Sessions',         'Scheduled 1-on-1 video calls with your assigned trainer'),
      (Icons.support_agent_rounded,  'Priority Trainer Support',      'Skip the queue — your messages are flagged as priority'),
      (Icons.emoji_events_rounded,   'Exclusive Fitness Challenges',  'Members-only leaderboards, fat-loss tournaments, and streak battles'),
    ];

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: AppColors.bgDark,
            expandedHeight: 260,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _deep.withValues(alpha: 0.3),
                      _orange.withValues(alpha: 0.15),
                      AppColors.bgDark,
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Crown badge
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 80, height: 80,
                            decoration: BoxDecoration(
                              gradient: const RadialGradient(
                                colors: [_gold, _orange, _deep],
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [BoxShadow(
                                color: _gold.withValues(alpha: 0.6),
                                blurRadius: 30, spreadRadius: 4)],
                            ),
                          ),
                          const Icon(Icons.workspace_premium_rounded,
                              color: Colors.white, size: 40),
                        ],
                      ).animate().scale(
                          duration: 700.ms, curve: Curves.elasticOut),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                              colors: [_gold, _orange]),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [BoxShadow(
                              color: _gold.withValues(alpha: 0.5),
                              blurRadius: 20)],
                        ),
                        child: Text('MASTER PLAN',
                            style: GoogleFonts.inter(
                                fontSize: 16, fontWeight: FontWeight.w900,
                                color: Colors.black, letterSpacing: 2)),
                      ).animate(delay: 150.ms).fadeIn(),
                      const SizedBox(height: 12),
                      Text('₹2499 / month',
                          style: GoogleFonts.inter(
                              fontSize: 30, fontWeight: FontWeight.w900,
                              color: AppColors.textPrimary))
                          .animate(delay: 200.ms).fadeIn(),
                      const SizedBox(height: 4),
                      Text('All Elite + Full AI Coach + Live Sessions',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                              fontSize: 12, color: AppColors.textSecondary))
                          .animate(delay: 300.ms).fadeIn(),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
            sliver: SliverToBoxAdapter(
              child: Text('EXCLUSIVE MASTER FEATURES',
                  style: GoogleFonts.inter(fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMuted, letterSpacing: 1.2)),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverToBoxAdapter(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.bgCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _gold.withValues(alpha: 0.3)),
                  boxShadow: [BoxShadow(
                      color: _gold.withValues(alpha: 0.08),
                      blurRadius: 20, spreadRadius: 2)],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    children: features.asMap().entries.map((entry) {
                      final i = entry.key;
                      final (icon, title, subtitle) = entry.value;
                      final isAI = title.contains('AI') ||
                          title.contains('Coach') || title.contains('Live');
                      return Column(children: [
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: isAI
                                  ? const LinearGradient(
                                      colors: [_gold, _orange])
                                  : LinearGradient(colors: [
                                      AppColors.primary,
                                      AppColors.accent,
                                    ]),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(icon, color: Colors.white, size: 18),
                          ),
                          title: Text(title,
                              style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w700, fontSize: 14,
                                  color: AppColors.textPrimary)),
                          subtitle: Text(subtitle,
                              style: GoogleFonts.inter(
                                  fontSize: 12, color: AppColors.textSecondary,
                                  height: 1.4)),
                        ),
                        if (i < features.length - 1)
                          const Divider(color: AppColors.divider, height: 1),
                      ]);
                    }).toList(),
                  ),
                ),
              ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.04),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
            sliver: SliverToBoxAdapter(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    _gold.withValues(alpha: 0.1),
                    _orange.withValues(alpha: 0.06),
                  ]),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _gold.withValues(alpha: 0.4)),
                ),
                child: Column(children: [
                  const Icon(Icons.workspace_premium_rounded,
                      color: _gold, size: 32),
                  const SizedBox(height: 12),
                  Text(gym?.name ?? 'Your Gym',
                      style: GoogleFonts.inter(fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary)),
                  if (gym?.phone != null) ...[
                    const SizedBox(height: 6),
                    Text('📞 ${gym!.phone}',
                        style: GoogleFonts.inter(fontSize: 14,
                            color: AppColors.textSecondary)),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    'Upgrade to Master at your gym for the ultimate AI-powered fitness experience',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                        fontSize: 13, color: AppColors.textMuted),
                  ),
                ]),
              ).animate(delay: 400.ms).fadeIn(),
            ),
          ),
        ],
      ),
    );
  }
}
