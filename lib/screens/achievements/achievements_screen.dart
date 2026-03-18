// lib/screens/achievements/achievements_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/extensions.dart';
import '../../models/achievement_model.dart';
import '../../providers/achievement_provider.dart';
import '../../widgets/glassmorphic_card.dart';

class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.fitTheme;
    final achievements = ref.watch(achievementProvider);
    final xp = ref.watch(totalXpProvider);
    final level = ref.watch(levelProvider);
    final notifier = ref.read(achievementProvider.notifier);
    final levelProgress = notifier.levelProgress;
    final unlocked = achievements.where((a) => a.isUnlocked).toList();
    final locked = achievements.where((a) => !a.isUnlocked).toList();

    return Scaffold(
      backgroundColor: t.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            backgroundColor: t.surface,
            title: Text(
              'Achievements',
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: t.textPrimary,
              ),
            ),
            leading: IconButton(
              icon: Icon(Icons.arrow_back_rounded, color: t.textPrimary),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ),

          // XP / Level banner
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
            sliver: SliverToBoxAdapter(
              child: GlassmorphicCard(
                borderRadius: 24,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              gradient: t.brandGradient,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '⚡',
                                style: const TextStyle(fontSize: 28),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Level $level',
                                  style: GoogleFonts.inter(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                    color: t.textPrimary,
                                  ),
                                ),
                                Text(
                                  '$xp XP total  ·  ${unlocked.length} unlocked',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: t.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: levelProgress,
                          minHeight: 10,
                          backgroundColor: t.ringTrack,
                          valueColor: AlwaysStoppedAnimation<Color>(t.brand),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${(levelProgress * 500).toInt()} / 500 XP',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: t.textMuted,
                            ),
                          ),
                          Text(
                            'Next: Level ${level + 1}',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: t.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.05),
            ),
          ),

          // Unlocked section
          if (unlocked.isNotEmpty) ...[
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
              sliver: SliverToBoxAdapter(
                child: Text(
                  'UNLOCKED (${unlocked.length})',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: t.textMuted,
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              sliver: SliverGrid.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.15,
                ),
                itemCount: unlocked.length,
                itemBuilder: (context, i) => _AchievementCard(
                  achievement: unlocked[i],
                ).animate(delay: (i * 50).ms).fadeIn(duration: 250.ms).scale(
                    begin: const Offset(0.92, 0.92)),
              ),
            ),
          ],

          // Locked section
          if (locked.isNotEmpty) ...[
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
              sliver: SliverToBoxAdapter(
                child: Text(
                  'LOCKED (${locked.length})',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: t.textMuted,
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 40),
              sliver: SliverGrid.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.15,
                ),
                itemCount: locked.length,
                itemBuilder: (context, i) => _AchievementCard(
                  achievement: locked[i],
                ).animate(delay: (i * 50).ms).fadeIn(duration: 250.ms),
              ),
            ),
          ],

          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  const _AchievementCard({required this.achievement});
  final Achievement achievement;

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;
    final unlocked = achievement.isUnlocked;

    return GlassmorphicCard(
      borderRadius: 20,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  unlocked ? achievement.emoji : '🔒',
                  style: TextStyle(
                    fontSize: 28,
                    color: unlocked ? null : Colors.transparent,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: achievement.categoryColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    achievement.categoryLabel,
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: achievement.categoryColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              achievement.title,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: unlocked ? t.textPrimary : t.textMuted,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Expanded(
              child: Text(
                achievement.description,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: unlocked ? t.textSecondary : t.textMuted,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  unlocked ? Icons.check_circle_rounded : Icons.bolt_rounded,
                  size: 14,
                  color: unlocked ? t.success : t.textMuted,
                ),
                const SizedBox(width: 4),
                Text(
                  '+${achievement.xpReward} XP',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: unlocked ? t.success : t.textMuted,
                  ),
                ),
                if (!unlocked && achievement.progress > 0) ...[
                  const Spacer(),
                  SizedBox(
                    width: 60,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: achievement.progress,
                        minHeight: 4,
                        backgroundColor: t.ringTrack,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          achievement.categoryColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
