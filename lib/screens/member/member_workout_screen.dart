import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/extensions.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/member_provider.dart';

/// Full workout plan detail screen for members.
class MemberWorkoutScreen extends ConsumerWidget {
  const MemberWorkoutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.fitTheme;
    final l = AppLocalizations.of(context)!;
    final planAsync = ref.watch(memberWorkoutPlanProvider);

    return Scaffold(
      backgroundColor: t.background,
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
          l.myWorkoutPlan,
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: t.textPrimary,
          ),
        ),
      ),
      floatingActionButton: planAsync.whenOrNull(
        data: (plan) {
          if (plan == null || plan.days.isEmpty) return null;
          return FloatingActionButton.extended(
            onPressed: () => context.push('/workout/active'),
            backgroundColor: t.accent,
            icon: const Icon(Icons.play_arrow_rounded, color: Colors.white),
            label: Text(
              l.startWorkout.toUpperCase(),
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          );
        },
      ),
      body: planAsync.when(
        loading: () => Center(
            child: CircularProgressIndicator(color: t.brand)),
        error: (e, _) => Center(
          child: Text('Error: $e',
              style: GoogleFonts.inter(color: t.danger)),
        ),
        data: (plan) {
          if (plan == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.fitness_center_rounded,
                      size: 56, color: t.textMuted),
                  const SizedBox(height: 16),
                  Text(
                    l.noWorkoutPlan,
                    style: GoogleFonts.inter(
                        color: t.textSecondary, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ask your trainer to assign a workout plan',
                    style: GoogleFonts.inter(
                        color: t.textMuted, fontSize: 13),
                  ),
                ],
              ),
            );
          }

          final days = plan.days;
          final today = DateTime.now().weekday;

          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plan.name,
                        style: GoogleFonts.inter(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: t.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${days.length} training days · ${plan.durationWeeks} weeks',
                        style: GoogleFonts.inter(
                            color: t.textSecondary, fontSize: 14),
                      ),
                    ],
                  ).animate().fadeIn(),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final day = days[i];
                    final isToday = (i + 1) == ((today - 1) % days.length) + 1;
                    return _DayCard(
                      day: day,
                      dayNumber: i + 1,
                      isToday: isToday,
                      delay: i * 60,
                    );
                  },
                  childCount: days.length,
                ),
              ),
              const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
            ],
          );
        },
      ),
    );
  }
}

class _DayCard extends StatelessWidget {
  final dynamic day;
  final int dayNumber;
  final bool isToday;
  final int delay;

  const _DayCard({
    required this.day,
    required this.dayNumber,
    required this.isToday,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;
    final exercises = day.exercises as List;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Container(
        decoration: BoxDecoration(
          color: isToday
              ? t.brand.withOpacity(0.08)
              : t.surfaceAlt,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isToday
                ? t.brand.withOpacity(0.4)
                : t.border,
            width: isToday ? 1.5 : 1,
          ),
        ),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            childrenPadding:
                const EdgeInsets.fromLTRB(16, 0, 16, 16),
            leading: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: isToday
                    ? LinearGradient(
                        colors: [t.brand, t.accent])
                    : null,
                color: isToday ? null : t.surface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  'D$dayNumber',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: isToday
                        ? Colors.white
                        : t.textSecondary,
                  ),
                ),
              ),
            ),
            title: Row(
              children: [
                Flexible(
                  child: Text(
                    day.dayName as String,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: t.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isToday) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: t.brand.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'TODAY',
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        color: t.brand,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            subtitle: Text(
              '${exercises.length} exercises',
              style: GoogleFonts.inter(
                  fontSize: 12, color: t.textSecondary),
            ),
            children: exercises.asMap().entries.map((entry) {
              final idx = entry.key;
              final ex = entry.value;
              return Padding(
                padding:
                    const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: t.brand.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: Text(
                          '${idx + 1}',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: t.brand,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        ex.name as String,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: t.textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      '${ex.sets} × ${ex.reps}',
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          color: t.textSecondary,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ).animate(delay: Duration(milliseconds: delay)).fadeIn().slideY(begin: 0.04),
    );
  }
}
