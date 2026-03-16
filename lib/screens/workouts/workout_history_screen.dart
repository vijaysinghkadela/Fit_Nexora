import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/extensions.dart';
import '../../widgets/glassmorphic_card.dart';

/// Workout history screen with date strip, at-a-glance stats, and session list.
/// Route: `/workout/history`
class WorkoutHistoryScreen extends ConsumerStatefulWidget {
  const WorkoutHistoryScreen({super.key});

  @override
  ConsumerState<WorkoutHistoryScreen> createState() =>
      _WorkoutHistoryScreenState();
}

class _WorkoutHistoryScreenState extends ConsumerState<WorkoutHistoryScreen> {
  int _selectedDayIndex = 6; // Default: today (last in strip)

  final List<_WorkoutSession> _sessions = [
    _WorkoutSession(
      name: 'Push Day A',
      date: DateTime(2026, 3, 15),
      durationMinutes: 42,
      exerciseCount: 6,
      volumeKg: 9450,
      accentColor: const Color(0xFF895AF6),
    ),
    _WorkoutSession(
      name: 'Pull Day B',
      date: DateTime(2026, 3, 13),
      durationMinutes: 55,
      exerciseCount: 7,
      volumeKg: 11200,
      accentColor: const Color(0xFF10D88A),
    ),
    _WorkoutSession(
      name: 'Leg Day',
      date: DateTime(2026, 3, 11),
      durationMinutes: 65,
      exerciseCount: 8,
      volumeKg: 14800,
      accentColor: const Color(0xFFF6B546),
    ),
    _WorkoutSession(
      name: 'Push Day A',
      date: DateTime(2026, 3, 9),
      durationMinutes: 40,
      exerciseCount: 6,
      volumeKg: 8900,
      accentColor: const Color(0xFF895AF6),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;

    final now = DateTime.now();
    final days = List.generate(7, (i) => now.subtract(Duration(days: 6 - i)));

    return Scaffold(
      backgroundColor: t.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: t.surface,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_rounded, color: t.textPrimary),
              onPressed: () => Navigator.maybePop(context),
            ),
            title: Text(
              'Workout History',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: t.textPrimary,
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.calendar_month_rounded, color: t.textSecondary),
                onPressed: () {},
              ),
            ],
          ),

          SliverToBoxAdapter(
            child: Column(
              children: [
                // ── Date Strip ─────────────────────────────────────────
                Container(
                  color: t.surface,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Row(
                    children: days.asMap().entries.map((e) {
                      final idx = e.key;
                      final day = e.value;
                      final isSelected = idx == _selectedDayIndex;
                      final isToday = idx == 6;

                      return Expanded(
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _selectedDayIndex = idx),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeInOut,
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? t.brand
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              border: isToday && !isSelected
                                  ? Border.all(
                                      color: t.brand.withValues(alpha: 0.4))
                                  : null,
                            ),
                            child: Column(
                              children: [
                                Text(
                                  day.weekdayInitial,
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected
                                        ? Colors.white
                                        : t.textMuted,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${day.day}',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: isSelected
                                        ? Colors.white
                                        : t.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                // Activity dot
                                Container(
                                  width: 5,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: [0, 2, 4, 6].contains(idx)
                                        ? (isSelected
                                            ? Colors.white
                                            : t.accent)
                                        : Colors.transparent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                Divider(height: 1, color: t.divider),
              ],
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── At a Glance Grid ────────────────────────────────────
                Text(
                  'At a Glance',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: t.textPrimary,
                  ),
                ).animate().fadeIn(duration: 400.ms),
                const SizedBox(height: 10),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.8,
                  children: [
                    _GlanceCard(
                      icon: Icons.fitness_center_rounded,
                      value: '12',
                      label: 'Total Workouts',
                      color: t.brand,
                    ),
                    _GlanceCard(
                      icon: Icons.timer_outlined,
                      value: '52 min',
                      label: 'Avg Duration',
                      color: t.info,
                    ),
                    _GlanceCard(
                      icon: Icons.bar_chart_rounded,
                      value: '11,200 kg',
                      label: 'Total Volume',
                      color: t.accent,
                    ),
                    _GlanceCard(
                      icon: Icons.local_fire_department_rounded,
                      value: '7 days',
                      label: 'Streak',
                      color: t.warning,
                    ),
                  ],
                ).animate(delay: 100.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1),

                const SizedBox(height: 20),

                // ── Personal Best Card ───────────────────────────────────
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFFFFD700).withValues(alpha: 0.25),
                        const Color(0xFFFFA500).withValues(alpha: 0.15),
                      ],
                    ),
                    border: Border.all(
                        color: const Color(0xFFFFD700)
                            .withValues(alpha: 0.4)),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFD700).withValues(alpha: 0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.emoji_events_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Personal Best',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFFFFA500),
                                  letterSpacing: 0.3,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Barbell Bench Press — 82.5 kg',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: t.textPrimary,
                                ),
                              ),
                              Text(
                                'Set on March 15, 2026',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: t.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ).animate(delay: 200.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1),

                const SizedBox(height: 20),

                // ── Session List ─────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Sessions',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: t.textPrimary,
                      ),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: Text(
                        'View All',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: t.brand,
                        ),
                      ),
                    ),
                  ],
                ).animate(delay: 250.ms).fadeIn(duration: 400.ms),

                ..._sessions
                    .asMap()
                    .entries
                    .map((e) => _SessionCard(session: e.value)
                        .animate(delay: (280 + e.key * 70).ms)
                        .fadeIn(duration: 350.ms)
                        .slideX(begin: 0.05)),

                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlanceCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _GlanceCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: t.textPrimary,
                  ),
                ),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: t.textMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  final _WorkoutSession session;

  const _SessionCard({required this.session});

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassmorphicCard(
        onTap: () {},
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Colored left border accent
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: session.accentColor,
                  borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(20)),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            session.name,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: t.textPrimary,
                            ),
                          ),
                          Text(
                            session.date.dayMonth,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: t.textMuted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _SessionChip(
                            icon: Icons.timer_outlined,
                            label: '${session.durationMinutes} min',
                            color: t.textSecondary,
                          ),
                          const SizedBox(width: 12),
                          _SessionChip(
                            icon: Icons.layers_rounded,
                            label: '${session.exerciseCount} exercises',
                            color: t.textSecondary,
                          ),
                          const SizedBox(width: 12),
                          _SessionChip(
                            icon: Icons.fitness_center_rounded,
                            label: '${(session.volumeKg / 1000).toStringAsFixed(1)}t',
                            color: session.accentColor,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Icon(Icons.chevron_right_rounded, color: t.textMuted, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SessionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _SessionChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _WorkoutSession {
  final String name;
  final DateTime date;
  final int durationMinutes;
  final int exerciseCount;
  final double volumeKg;
  final Color accentColor;

  const _WorkoutSession({
    required this.name,
    required this.date,
    required this.durationMinutes,
    required this.exerciseCount,
    required this.volumeKg,
    required this.accentColor,
  });
}
