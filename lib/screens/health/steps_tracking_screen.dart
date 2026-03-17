import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/extensions.dart';
import '../../providers/health_provider.dart';
import '../../widgets/circular_gauge.dart';
import '../../widgets/glassmorphic_card.dart';

class StepsTrackingScreen extends ConsumerStatefulWidget {
  const StepsTrackingScreen({super.key});

  @override
  ConsumerState<StepsTrackingScreen> createState() => _StepsTrackingScreenState();
}

class _StepsTrackingScreenState extends ConsumerState<StepsTrackingScreen> {
  final _stepsController = TextEditingController();

  @override
  void dispose() {
    _stepsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;
    final state = ref.watch(stepsProvider);
    final progress = (state.stepsToday / state.dailyGoal).clamp(0.0, 1.0);
    final calories = (state.stepsToday * 0.04).round();
    final distanceKm = (state.stepsToday * 0.0008).toStringAsFixed(1);
    final activeMin = (state.stepsToday / 100).round();

    return Scaffold(
      backgroundColor: t.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showLogSheet(context),
        backgroundColor: t.brand,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text('Log Steps', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            backgroundColor: t.surface,
            title: Text(
              'Steps',
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: t.textPrimary,
              ),
            ),
            leading: IconButton(
              icon: Icon(Icons.arrow_back_rounded, color: t.textPrimary),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),

          // Hero ring gauge
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
            sliver: SliverToBoxAdapter(
              child: Center(
                child: RepaintBoundary(
                  child: CircularGauge(
                    value: progress,
                    size: 200,
                    centerText: state.stepsToday.toString(),
                    label: '/ ${state.dailyGoal} goal',
                    gradientColors: [t.brand, t.accent],
                  ),
                ),
              ),
            ),
          ),

          // Quick stats row
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  Expanded(
                    child: _MiniStatCard(
                      label: 'Calories',
                      value: '$calories',
                      unit: 'kcal',
                      icon: Icons.local_fire_department_rounded,
                      color: t.warning,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MiniStatCard(
                      label: 'Distance',
                      value: distanceKm,
                      unit: 'km',
                      icon: Icons.route_rounded,
                      color: t.info,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MiniStatCard(
                      label: 'Active',
                      value: '$activeMin',
                      unit: 'min',
                      icon: Icons.timer_rounded,
                      color: t.success,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Weekly bar chart
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            sliver: SliverToBoxAdapter(
              child: GlassmorphicCard(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Weekly Overview',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: t.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 100,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: List.generate(7, (i) {
                            final steps = state.weeklySteps[i];
                            final ratio = (steps / state.dailyGoal).clamp(0.0, 1.2);
                            final barColor = steps < state.dailyGoal * 0.6
                                ? t.danger
                                : steps < state.dailyGoal * 0.9
                                    ? t.warning
                                    : t.success;
                            const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                            final isToday = i == DateTime.now().weekday - 1;
                            return Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 3),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    AnimatedContainer(
                                      duration: Duration(milliseconds: 400 + i * 60),
                                      curve: Curves.easeOutQuart,
                                      height: 70 * ratio.clamp(0.05, 1.0),
                                      decoration: BoxDecoration(
                                        color: isToday
                                            ? barColor
                                            : barColor.withValues(alpha: 0.55),
                                        borderRadius: BorderRadius.circular(5),
                                        border: isToday
                                            ? Border.all(color: barColor, width: 1.5)
                                            : null,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      days[i],
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: isToday
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        color: isToday ? t.textPrimary : t.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Monthly goal
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            sliver: SliverToBoxAdapter(
              child: GlassmorphicCard(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.flag_rounded, color: t.brand, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Monthly Goal',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: t.textPrimary,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${state.weeklySteps.reduce((a, b) => a + b)} / ${state.monthlyGoal}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: t.textMuted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: (state.weeklySteps.reduce((a, b) => a + b) /
                                  state.monthlyGoal)
                              .clamp(0.0, 1.0),
                          minHeight: 10,
                          backgroundColor: t.ringTrack,
                          valueColor: AlwaysStoppedAnimation(t.brand),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${((state.weeklySteps.reduce((a, b) => a + b) / state.monthlyGoal) * 100).toStringAsFixed(0)}% of monthly target',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: t.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  void _showLogSheet(BuildContext context) {
    final t = context.fitTheme;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: t.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
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
              Text(
                'Log Steps',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: t.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _stepsController,
                keyboardType: TextInputType.number,
                autofocus: true,
                style: GoogleFonts.inter(color: t.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Steps count',
                  hintText: 'e.g. 2500',
                  prefixIcon: Icon(Icons.directions_walk_rounded, color: t.brand),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    final steps = int.tryParse(_stepsController.text) ?? 0;
                    if (steps > 0) {
                      ref.read(stepsProvider.notifier).logSteps(steps);
                      _stepsController.clear();
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: t.brand,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Save Steps',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;

  const _MiniStatCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;
    return GlassmorphicCard(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: t.textPrimary,
              ),
            ),
            Text(
              unit,
              style: GoogleFonts.inter(fontSize: 10, color: t.textMuted),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.inter(fontSize: 11, color: t.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
