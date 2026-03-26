import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/extensions.dart';
import '../../widgets/glassmorphic_card.dart';

/// Master: Exclusive Fitness Challenges + Gym Leaderboard.
class MasterChallengesScreen extends ConsumerWidget {
  const MasterChallengesScreen({super.key});

  static const _masterPrimary = Color(0xFFE84F00);
  static const _masterSecondary = Color(0xFFFF7A2E);
  static const _silver = Color(0xFFC0C0C0);
  static const _bronze = Color(0xFFCD7F32);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.fitTheme;

    // Static leaderboard entries for demo (will be populated by Supabase)
    final leaderboard = [
      ('Rohit S.', '🔥 28 day streak', 120, _masterPrimary),
      ('Priya M.', '⚡ 25 days', 105, _silver),
      ('Arjun K.', '💪 22 days', 98, _bronze),
      ('Neha P.', '🏃 19 days', 87, t.textMuted),
      ('Vikram D.', '🌟 17 days', 75, t.textMuted),
      ('Sneha R.', '💎 15 days', 63, t.textMuted),
    ];

    final challenges = [
      (
        '🔥',
        '30-Day Fat Burn Challenge',
        '30 min cardio every day for 30 days',
        '12 days left',
        62.0,
        t.danger
      ),
      (
        '💪',
        'Push Up Power',
        '100 push-ups a day for 2 weeks',
        '5 days left',
        80.0,
        t.brand
      ),
      (
        '🥗',
        'Clean Eating Week',
        'Log 3 clean meals daily for 7 days',
        '3 days left',
        43.0,
        t.success
      ),
      (
        '🏆',
        'Top Attendance',
        'Visit the gym 20+ times this month',
        '8 days left',
        55.0,
        t.warning
      ),
    ];

    return Scaffold(
      backgroundColor: t.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: t.background,
            leading: BackButton(color: t.textSecondary),
            title: Text('Challenges & Leaderboard',
                style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: t.textPrimary)),
            expandedHeight: 180,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      _masterPrimary.withOpacity(0.15),
                      t.background,
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 60, 20, 0),
                    child: Row(children: [
                      _statPill(context, '🔥', 'Challenges', '4 active',
                          _masterSecondary),
                      const SizedBox(width: 10),
                      _statPill(context, '🏆', 'Leaderboard', 'Top 6',
                          _masterPrimary),
                      const SizedBox(width: 10),
                      _statPill(context, '🎯', 'Your Rank', '#3', t.brand),
                    ]),
                  ),
                ),
              ),
            ),
          ),

          // ─── Leaderboard
          _hdr(context, '🏆 GYM LEADERBOARD — THIS MONTH'),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverToBoxAdapter(
              child: GlassmorphicCard(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    children: leaderboard.asMap().entries.map((entry) {
                      final i = entry.key;
                      final (name, sub, pts, color) = entry.value;
                      return Column(children: [
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          leading: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.15),
                              shape: BoxShape.circle,
                              border: Border.all(color: color.withOpacity(0.4)),
                            ),
                            child: Center(
                                child: Text(
                              i == 0
                                  ? '🥇'
                                  : i == 1
                                      ? '🥈'
                                      : i == 2
                                          ? '🥉'
                                          : '${i + 1}',
                              style: const TextStyle(fontSize: 18),
                            )),
                          ),
                          title: Text(name,
                              style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: t.textPrimary)),
                          subtitle: Text(sub,
                              style: GoogleFonts.inter(
                                  fontSize: 12, color: t.textSecondary)),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text('$pts pts',
                                style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: color)),
                          ),
                        ),
                        if (i < leaderboard.length - 1)
                          Divider(color: t.divider, height: 1),
                      ]);
                    }).toList(),
                  ),
                ),
              ).animate().fadeIn(),
            ),
          ),

          // ─── Active Challenges
          _hdr(context, '⚡ ACTIVE CHALLENGES'),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((ctx, i) {
                final (emoji, title, desc, remaining, progress, color) =
                    challenges[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GlassmorphicCard(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Text(emoji, style: const TextStyle(fontSize: 28)),
                              const SizedBox(width: 12),
                              Expanded(
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                    Text(title,
                                        style: GoogleFonts.inter(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w800,
                                            color: t.textPrimary)),
                                    Text(desc,
                                        style: GoogleFonts.inter(
                                            fontSize: 12,
                                            color: t.textSecondary)),
                                  ])),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: t.warning.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(remaining,
                                    style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: t.warning)),
                              ),
                            ]),
                            const SizedBox(height: 12),
                            Row(children: [
                              Expanded(
                                  child: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: progress / 100,
                                  backgroundColor: color.withOpacity(0.12),
                                  valueColor: AlwaysStoppedAnimation(color),
                                  minHeight: 8,
                                ),
                              )),
                              const SizedBox(width: 10),
                              Text('${progress.round()}%',
                                  style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: color)),
                            ]),
                          ]),
                    ),
                  ).animate(delay: (i * 80).ms).fadeIn(),
                );
              }, childCount: challenges.length),
            ),
          ),
        ],
      ),
    );
  }

  Widget _hdr(BuildContext context, String label) => SliverPadding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
        sliver: SliverToBoxAdapter(
          child: Text(label,
              style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: context.fitTheme.textMuted,
                  letterSpacing: 1.1)),
        ),
      );

  Widget _statPill(
      BuildContext context, String emoji, String label, String val, Color c) {
    final t = context.fitTheme;
    return Expanded(
        child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: c.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.withOpacity(0.25)),
      ),
      child: Column(children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 4),
        Text(val,
            style: GoogleFonts.inter(
                fontSize: 13, fontWeight: FontWeight.w900, color: c)),
        Text(label, style: GoogleFonts.inter(fontSize: 9, color: t.textMuted)),
      ]),
    ));
  }
}
