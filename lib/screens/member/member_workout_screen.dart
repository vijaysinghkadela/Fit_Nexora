import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../providers/member_provider.dart';

/// Full workout plan detail screen for members.
class MemberWorkoutScreen extends ConsumerWidget {
  const MemberWorkoutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planAsync = ref.watch(memberWorkoutPlanProvider);

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.bgDark,
        leading: BackButton(color: AppColors.textSecondary),
        title: Text(
          'My Workout Plan',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: planAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(
          child: Text('Error: $e',
              style: GoogleFonts.inter(color: AppColors.error)),
        ),
        data: (plan) {
          if (plan == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.fitness_center_rounded,
                      size: 56, color: AppColors.textMuted),
                  const SizedBox(height: 16),
                  Text(
                    'No workout plan assigned yet',
                    style: GoogleFonts.inter(
                        color: AppColors.textSecondary, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ask your trainer to assign a workout plan',
                    style: GoogleFonts.inter(
                        color: AppColors.textMuted, fontSize: 13),
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
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${days.length} training days · ${plan.durationWeeks} weeks',
                        style: GoogleFonts.inter(
                            color: AppColors.textSecondary, fontSize: 14),
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
              const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
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
    final exercises = day.exercises as List;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Container(
        decoration: BoxDecoration(
          color: isToday
              ? AppColors.primary.withValues(alpha: 0.08)
              : AppColors.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isToday
                ? AppColors.primary.withValues(alpha: 0.4)
                : AppColors.border,
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
                    ? const LinearGradient(
                        colors: [AppColors.primary, AppColors.accent])
                    : null,
                color: isToday ? null : AppColors.bgElevated,
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
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
            title: Row(
              children: [
                Text(
                  day.name as String,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (isToday) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'TODAY',
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
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
                  fontSize: 12, color: AppColors.textSecondary),
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
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: Text(
                          '${idx + 1}',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
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
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      '${ex.sets} × ${ex.reps}',
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textSecondary,
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
