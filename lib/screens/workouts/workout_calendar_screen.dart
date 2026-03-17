import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/extensions.dart';
import '../../providers/workout_calendar_provider.dart';
import '../../widgets/glassmorphic_card.dart';

String _dateKey(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

class WorkoutCalendarScreen extends ConsumerStatefulWidget {
  const WorkoutCalendarScreen({super.key});

  @override
  ConsumerState<WorkoutCalendarScreen> createState() =>
      _WorkoutCalendarScreenState();
}

class _WorkoutCalendarScreenState extends ConsumerState<WorkoutCalendarScreen> {
  late DateTime _viewMonth;
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _viewMonth = DateTime(DateTime.now().year, DateTime.now().month);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;
    final calendarMap = ref.watch(workoutCalendarProvider);

    final daysInMonth =
        DateUtils.getDaysInMonth(_viewMonth.year, _viewMonth.month);
    final firstWeekday = DateTime(_viewMonth.year, _viewMonth.month, 1).weekday;
    final leadingBlanks = firstWeekday - 1; // Mon=1 → 0 blanks

    final monthWorkouts = calendarMap.values
        .where((w) =>
            w.date.year == _viewMonth.year &&
            w.date.month == _viewMonth.month)
        .map((w) => w.date.day)
        .toSet();

    final selectedWorkout = _selectedDay != null
        ? calendarMap[_dateKey(_selectedDay!)]
        : null;

    return Scaffold(
      backgroundColor: t.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            backgroundColor: t.surface,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_rounded, color: t.textPrimary),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              'Workout Calendar',
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: t.textPrimary,
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.chevron_left_rounded, color: t.textPrimary),
                onPressed: () => setState(() {
                  _viewMonth =
                      DateTime(_viewMonth.year, _viewMonth.month - 1);
                  _selectedDay = null;
                }),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 18),
                child: Text(
                  '${_monthName(_viewMonth.month)} ${_viewMonth.year}',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: t.textPrimary,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.chevron_right_rounded, color: t.textPrimary),
                onPressed: () => setState(() {
                  _viewMonth =
                      DateTime(_viewMonth.year, _viewMonth.month + 1);
                  _selectedDay = null;
                }),
              ),
            ],
          ),

          // Day-of-week header
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: ['M', 'T', 'W', 'T', 'F', 'S', 'S'].map((d) {
                  return Expanded(
                    child: Center(
                      child: Text(
                        d,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: t.textMuted,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Month grid
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverToBoxAdapter(
              child: GridView.count(
                crossAxisCount: 7,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 6,
                crossAxisSpacing: 4,
                childAspectRatio: 0.9,
                children: [
                  ...List.generate(leadingBlanks, (_) => const SizedBox()),
                  ...List.generate(daysInMonth, (i) {
                    final day = i + 1;
                    final date = DateTime(_viewMonth.year, _viewMonth.month, day);
                    final now = DateTime.now();
                    final isToday = now.year == date.year &&
                        now.month == date.month &&
                        now.day == date.day;
                    final isSelected = _selectedDay != null &&
                        _selectedDay!.day == day &&
                        _selectedDay!.month == _viewMonth.month &&
                        _selectedDay!.year == _viewMonth.year;
                    final hasWorkout = monthWorkouts.contains(day);

                    return GestureDetector(
                      onTap: () =>
                          setState(() => _selectedDay = isSelected ? null : date),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? t.brand
                              : isToday
                                  ? t.brand.withValues(alpha: 0.1)
                                  : t.surfaceAlt,
                          borderRadius: BorderRadius.circular(8),
                          border: isToday && !isSelected
                              ? Border.all(color: t.brand, width: 1.5)
                              : null,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '$day',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? Colors.white
                                    : isToday
                                        ? t.brand
                                        : t.textSecondary,
                              ),
                            ),
                            if (hasWorkout)
                              Container(
                                width: 5,
                                height: 5,
                                margin: const EdgeInsets.only(top: 2),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Colors.white
                                      : t.accent,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ).animate().fadeIn(duration: 400.ms),
            ),
          ),

          // Selected day detail panel
          if (_selectedDay != null)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              sliver: SliverToBoxAdapter(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutQuart,
                  child: GlassmorphicCard(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                _formatDay(_selectedDay!),
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: t.textPrimary,
                                ),
                              ),
                              const Spacer(),
                              TextButton.icon(
                                onPressed: () => _showAddExerciseSheet(
                                    context, _selectedDay!),
                                icon: Icon(Icons.add_rounded, size: 16, color: t.brand),
                                label: Text('Add Exercise',
                                    style: GoogleFonts.inter(
                                        fontSize: 13,
                                        color: t.brand,
                                        fontWeight: FontWeight.w600)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (selectedWorkout == null ||
                              selectedWorkout.exercises.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Center(
                                child: Text(
                                  'No exercises scheduled. Tap Add to plan.',
                                  style: GoogleFonts.inter(
                                      fontSize: 13, color: t.textMuted),
                                ),
                              ),
                            )
                          else ...[
                            ...selectedWorkout.exercises
                                .asMap()
                                .entries
                                .map((e) => _ExerciseTile(
                                      exercise: e.value,
                                      onDelete: () =>
                                          ref
                                              .read(workoutCalendarProvider.notifier)
                                              .removeExercise(
                                                  _selectedDay!, e.value.name),
                                    )),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () =>
                                    context.push('/workout/active'),
                                icon: const Icon(Icons.play_arrow_rounded),
                                label: Text(
                                  'Start Workout',
                                  style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w700),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: t.brand,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ).animate().fadeIn().slideY(begin: 0.06, end: 0),
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  void _showAddExerciseSheet(BuildContext context, DateTime date) {
    final t = context.fitTheme;
    final nameCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: t.surface,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: t.textMuted.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text('Add Exercise',
                  style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: t.textPrimary)),
              const SizedBox(height: 16),
              TextField(
                controller: nameCtrl,
                autofocus: true,
                style: GoogleFonts.inter(color: t.textPrimary),
                decoration:
                    const InputDecoration(labelText: 'Exercise name'),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    final name = nameCtrl.text.trim();
                    if (name.isNotEmpty) {
                      ref
                          .read(workoutCalendarProvider.notifier)
                          .addExercise(date, name);
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: t.brand,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text('Add',
                      style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  String _monthName(int m) => const [
        '',
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December'
      ][m];

  String _formatDay(DateTime d) =>
      '${_weekdayName(d.weekday)}, ${d.day} ${_monthName(d.month)}';

  String _weekdayName(int w) => const [
        '',
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday'
      ][w];
}

class _ExerciseTile extends StatelessWidget {
  final ScheduledExercise exercise;
  final VoidCallback onDelete;

  const _ExerciseTile({required this.exercise, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: t.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: t.border),
      ),
      child: Row(
        children: [
          Icon(Icons.drag_handle_rounded, color: t.textMuted, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              exercise.name,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: t.textPrimary,
              ),
            ),
          ),
          _ChipLabel('${exercise.sets}×${exercise.reps}', t.brand),
          const SizedBox(width: 6),
          if (exercise.weightKg > 0)
            _ChipLabel('${exercise.weightKg.toInt()}kg', t.accent),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onDelete,
            child: Icon(Icons.close_rounded, color: t.textMuted, size: 18),
          ),
        ],
      ),
    );
  }
}

class _ChipLabel extends StatelessWidget {
  final String text;
  final Color color;
  const _ChipLabel(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
