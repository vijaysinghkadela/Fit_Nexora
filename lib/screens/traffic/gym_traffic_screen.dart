import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/chart_buckets.dart';
import '../../core/constants.dart';
import '../../core/extensions.dart';
import '../../core/responsive.dart';
import '../../providers/auth_provider.dart';
import '../../providers/gym_provider.dart';
import '../../providers/traffic_provider.dart';
import '../../widgets/error_widgets.dart';
import '../../widgets/glassmorphic_card.dart';
import '../../widgets/loading_widgets.dart';

class GymTrafficScreen extends ConsumerStatefulWidget {
  const GymTrafficScreen({super.key});

  @override
  ConsumerState<GymTrafficScreen> createState() => _GymTrafficScreenState();
}

class _GymTrafficScreenState extends ConsumerState<GymTrafficScreen> {
  bool _checkInLoading = false;

  @override
  Widget build(BuildContext context) {
    final gym = ref.watch(selectedGymProvider);
    final currentUser = ref.watch(currentUserProvider).value;

    final t = context.fitTheme;

    if (gym == null || currentUser == null) {
      return Scaffold(
        backgroundColor: t.background,
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: const [
              CardSkeleton(height: 160),
              SizedBox(height: 16),
              CardSkeleton(height: 90),
              SizedBox(height: 16),
              ChartSkeleton(height: 120),
            ],
          ),
        ),
      );
    }

    final gymId = gym.id;
    final userId = currentUser.id;

    return Scaffold(
      backgroundColor: t.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(
          onPressed: () => context.canPop() ? context.pop() : context.go('/dashboard'),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            _buildBgGlow(),
            RefreshIndicator(
              onRefresh: () => _refreshTraffic(gymId, userId),
              backgroundColor: t.surfaceAlt,
              color: t.brand,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  _buildAppBar(gym.name, gymId, userId),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _LiveTrafficCard(gymId: gymId),
                        const SizedBox(height: 16),
                        _CheckInCard(
                          gymId: gymId,
                          userId: userId,
                          loading: _checkInLoading,
                          onCheckIn: () => _handleCheckIn(gymId, userId),
                          onCheckOut: (id) => _handleCheckOut(id, gymId, userId),
                        ),
                        const SizedBox(height: 16),
                        _BestTimesCard(gymId: gymId),
                        const SizedBox(height: 16),
                        _HourlyChartCard(gymId: gymId),
                        const SizedBox(height: 16),
                        _TrafficTipsCard(),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _refreshTraffic(String gymId, String userId) async {
    ref.invalidate(gymCheckInsStreamProvider(gymId));
    ref.invalidate(hourlyTrafficProvider(gymId));
    ref.invalidate(bestVisitTimesProvider(gymId));
    ref.invalidate(activeCheckInProvider((gymId, userId)));
    await Future.wait([
      ref.read(hourlyTrafficProvider(gymId).future),
      ref.read(bestVisitTimesProvider(gymId).future),
      ref.read(activeCheckInProvider((gymId, userId)).future),
    ]);
  }

  Widget _buildBgGlow() {
    return Stack(children: [
      Positioned(
        top: -100,
        right: -80,
        child: Container(
          width: 300,
          height: 300,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [
              AppColors.primary.withValues(alpha: 0.08),
              Colors.transparent,
            ]),
          ),
        ),
      ),
      Positioned(
        bottom: -60,
        left: -60,
        child: Container(
          width: 250,
          height: 250,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [
              AppColors.accent.withValues(alpha: 0.07),
              Colors.transparent,
            ]),
          ),
        ),
      ),
    ]);
  }

  SliverAppBar _buildAppBar(String gymName, String gymId, String userId) {
    return SliverAppBar(
      floating: true,
      backgroundColor: AppColors.bgDark,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_rounded,
            color: AppColors.textSecondary, size: 20),
        onPressed: () => context.pop(),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Gym Traffic',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            gymName,
            style:
                GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded,
              color: AppColors.textSecondary, size: 22),
          onPressed: () => _refreshTraffic(gymId, userId),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Future<void> _handleCheckIn(String gymId, String userId) async {
    setState(() => _checkInLoading = true);
    try {
      final db = ref.read(databaseServiceProvider);
      await db.checkInToGym(gymId: gymId, userId: userId);
      ref.invalidate(activeCheckInProvider((gymId, userId)));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Check-in failed: ${_friendlyError(e)}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _checkInLoading = false);
    }
  }

  Future<void> _handleCheckOut(
      String checkInId, String gymId, String userId) async {
    setState(() => _checkInLoading = true);
    try {
      final db = ref.read(databaseServiceProvider);
      await db.checkOutFromGym(checkInId);
      ref.invalidate(activeCheckInProvider((gymId, userId)));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Check-out failed: ${_friendlyError(e)}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _checkInLoading = false);
    }
  }

  String _friendlyError(Object e) {
    final msg = e.toString();
    if (msg.contains('uq_active_checkin') || msg.contains('duplicate')) {
      return 'You are already checked in.';
    }
    return 'Something went wrong. Please try again.';
  }
}


// ─── Live Traffic Card ────────────────────────────────────────────────────────

class _LiveTrafficCard extends ConsumerWidget {
  final String gymId;
  const _LiveTrafficCard({required this.gymId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final traffic = ref.watch(currentTrafficCountProvider(gymId));
    final rs = ResponsiveSize.of(context);

    return GlassmorphicCard(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.accent,
                  ),
                )
                    .animate(onPlay: (c) => c.repeat())
                    .scale(
                        begin: const Offset(1, 1),
                        end: const Offset(1.6, 1.6),
                        duration: 900.ms,
                        curve: Curves.easeInOut)
                    .then()
                    .scale(
                        begin: const Offset(1.6, 1.6),
                        end: const Offset(1, 1),
                        duration: 900.ms),
                const SizedBox(width: 8),
                Text(
                  'Live Traffic',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accent,
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                traffic.when(
                  data: (count) => _TrafficLevelPill(count: count),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ],
            ),
            const SizedBox(height: 20),
            traffic.when(
              data: (count) => Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$count',
                    style: GoogleFonts.inter(
                      fontSize: rs.sp(72),
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                      height: 1,
                    ),
                  ).animate().fadeIn(duration: 400.ms).scale(
                      begin: const Offset(0.7, 0.7),
                      end: const Offset(1, 1),
                      curve: Curves.elasticOut),
                  const SizedBox(width: 12),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      count == 1 ? 'person\ncurrently' : 'people\ncurrently',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
              loading: () => Column(
                children: const [
                  SkeletonBox(height: 62, width: 120, radius: 18),
                  SizedBox(height: 10),
                  SkeletonBox(height: 16, width: 110, radius: 8),
                ],
              ),
              error: (_, __) => ErrorStateWidget(
                compact: true,
                message: 'Live traffic unavailable.',
                onRetry: () => ref.invalidate(gymCheckInsStreamProvider(gymId)),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Updates in real time',
              style: GoogleFonts.inter(
                  fontSize: 12, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    ).animate(delay: 100.ms).fadeIn().slideY(begin: 0.1, end: 0);
  }
}

class _TrafficLevelPill extends StatelessWidget {
  final int count;
  const _TrafficLevelPill({required this.count});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (count) {
      <= 5 => ('Quiet', AppColors.accent),
      <= 15 => ('Moderate', AppColors.warning),
      _ => ('Busy', AppColors.error),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

// ─── Check-In Card ────────────────────────────────────────────────────────────

class _CheckInCard extends ConsumerWidget {
  final String gymId;
  final String userId;
  final bool loading;
  final VoidCallback onCheckIn;
  final void Function(String checkInId) onCheckOut;

  const _CheckInCard({
    required this.gymId,
    required this.userId,
    required this.loading,
    required this.onCheckIn,
    required this.onCheckOut,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeCheckIn =
        ref.watch(activeCheckInProvider((gymId, userId)));

    return GlassmorphicCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: activeCheckIn.when(
          data: (checkin) => checkin != null
              ? _CheckedInView(
                  checkin: checkin,
                  loading: loading,
                  onCheckOut: onCheckOut,
                )
              : _CheckedOutView(loading: loading, onCheckIn: onCheckIn),
          loading: () => const _CheckInCardSkeleton(),
          error: (_, __) => ErrorStateWidget(
            compact: true,
            message: 'Unable to load check-in status.',
            onRetry: () => ref.invalidate(activeCheckInProvider((gymId, userId))),
          ),
        ),
      ),
    ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.1, end: 0);
  }
}

class _CheckInCardSkeleton extends StatelessWidget {
  const _CheckInCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        SkeletonBox(height: 48, width: 48, radius: 14),
        SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonBox(height: 16, width: 150, radius: 8),
              SizedBox(height: 8),
              SkeletonBox(height: 12, width: 180, radius: 8),
            ],
          ),
        ),
        SizedBox(width: 12),
        SkeletonBox(height: 38, width: 96, radius: 10),
      ],
    );
  }
}

class _CheckedInView extends StatelessWidget {
  final Map<String, dynamic> checkin;
  final bool loading;
  final void Function(String) onCheckOut;

  const _CheckedInView(
      {required this.checkin,
      required this.loading,
      required this.onCheckOut});

  @override
  Widget build(BuildContext context) {
    final checkInTime = DateTime.tryParse(checkin['checked_in_at'] as String)
        ?.toLocal();
    final timeStr = checkInTime != null
        ? '${checkInTime.hour.toString().padLeft(2, '0')}:${checkInTime.minute.toString().padLeft(2, '0')}'
        : '--:--';
    final duration = checkInTime != null
        ? DateTime.now().difference(checkInTime)
        : Duration.zero;
    final durationStr = duration.inMinutes < 60
        ? '${duration.inMinutes} min'
        : '${duration.inHours}h ${duration.inMinutes % 60}m';

    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.fitness_center_rounded,
              color: AppColors.accent, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Currently at the gym',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Checked in at $timeStr · $durationStr',
                style: GoogleFonts.inter(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          height: 38,
          child: ElevatedButton(
            onPressed: loading
                ? null
                : () => onCheckOut(checkin['id'] as String),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error.withValues(alpha: 0.2),
              foregroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(
                      color: AppColors.error.withValues(alpha: 0.4))),
              elevation: 0,
            ),
            child: loading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.error))
                : Text('Check Out',
                    style: GoogleFonts.inter(
                        fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }
}

class _CheckedOutView extends StatelessWidget {
  final bool loading;
  final VoidCallback onCheckIn;
  const _CheckedOutView({required this.loading, required this.onCheckIn});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.login_rounded,
              color: AppColors.primary, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Not checked in',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Tap to mark your gym visit',
                style: GoogleFonts.inter(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          height: 38,
          child: ElevatedButton(
            onPressed: loading ? null : onCheckIn,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: loading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.black))
                : Text('Check In',
                    style: GoogleFonts.inter(
                        fontSize: 13, fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }
}

// ─── Best Times Card ──────────────────────────────────────────────────────────

class _BestTimesCard extends ConsumerWidget {
  final String gymId;
  const _BestTimesCard({required this.gymId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bestTimes = ref.watch(bestVisitTimesProvider(gymId));

    return GlassmorphicCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.star_rounded,
                    color: AppColors.warning, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Best Times to Visit',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Quietest hours based on historical visits',
              style: GoogleFonts.inter(
                  fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            bestTimes.when(
              data: (hours) => hours.isEmpty
                  ? _defaultBestTimes()
                  : Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: hours
                          .map((h) => _TimeSlotChip(hour: h))
                          .toList(),
                    ),
              loading: () => const _ShimmerRow(),
              error: (_, __) => _defaultBestTimes(),
            ),
          ],
        ),
      ),
    ).animate(delay: 300.ms).fadeIn().slideY(begin: 0.1, end: 0);
  }

  // Shown when no historical data is available yet
  Widget _defaultBestTimes() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [6, 11, 14]
          .map((h) => _TimeSlotChip(hour: h, isDefault: true))
          .toList(),
    );
  }
}

class _TimeSlotChip extends StatelessWidget {
  final int hour;
  final bool isDefault;
  const _TimeSlotChip({required this.hour, this.isDefault = false});

  @override
  Widget build(BuildContext context) {
    final label = _hourLabel(hour);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: AppColors.accent.withValues(alpha: isDefault ? 0.2 : 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.access_time_rounded,
              color: AppColors.accent.withValues(alpha: isDefault ? 0.5 : 1),
              size: 15),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.accent
                  .withValues(alpha: isDefault ? 0.5 : 1),
            ),
          ),
        ],
      ),
    );
  }

  String _hourLabel(int h) {
    final start = h == 0
        ? '12 AM'
        : h < 12
            ? '$h AM'
            : h == 12
                ? '12 PM'
                : '${h - 12} PM';
    final endH = h + 1;
    final end = endH == 0
        ? '12 AM'
        : endH < 12
            ? '$endH AM'
            : endH == 12
                ? '12 PM'
                : '${endH - 12} PM';
    return '$start – $end';
  }
}

// ─── Hourly Chart Card ────────────────────────────────────────────────────────

class _HourlyChartCard extends ConsumerWidget {
  final String gymId;
  const _HourlyChartCard({required this.gymId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hourlyData = ref.watch(hourlyTrafficProvider(gymId));

    return GlassmorphicCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.bar_chart_rounded,
                    color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Weekly Traffic Pattern',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Average visitors per hour (last 4 weeks)',
              style: GoogleFonts.inter(
                  fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            hourlyData.when(
              data: (averages) => _TrafficBarChart(averages: averages),
              loading: () => const ChartSkeleton(height: 120),
              error: (_, __) => ErrorStateWidget(
                message: 'Unable to load traffic history.',
                onRetry: () => ref.invalidate(hourlyTrafficProvider(gymId)),
              ),
            ),
          ],
        ),
      ),
    ).animate(delay: 400.ms).fadeIn().slideY(begin: 0.1, end: 0);
  }
}

class _TrafficBarChart extends StatelessWidget {
  final List<double> averages;
  const _TrafficBarChart({required this.averages});

  @override
  Widget build(BuildContext context) {
    // Only show gym hours 5 AM – 10 PM (indices 5–22)
    const startHour = 5;
    const endHour = 22;
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 360;
        final buckets = bucketHourlyValues(
          values: averages,
          startHour: startHour,
          endHour: endHour,
          groupSize: isNarrow ? 2 : 1,
          currentHour: DateTime.now().hour,
        );
        final values = buckets.map((bucket) => bucket.value).toList();
        final maxVal = values.isEmpty
            ? 1.0
            : values.reduce((a, b) => a > b ? a : b).clamp(1.0, double.infinity);
        final quietestValue = values.where((value) => value > 0).fold<double?>(
          null,
          (current, value) =>
              current == null || value < current ? value : current,
        );
        final chartHeight = isNarrow ? 96.0 : 120.0;

        if (buckets.every((bucket) => bucket.value == 0)) {
          return SizedBox(
            height: chartHeight,
            child: Center(
              child: Text(
                'Not enough traffic history yet.',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
        SizedBox(
          height: chartHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: buckets.asMap().entries.map((entry) {
              final bucket = entry.value;
              final frac = bucket.value / maxVal;
              final isQuietest =
                  quietestValue != null && bucket.value == quietestValue;
              final color = bucket.containsCurrentHour
                  ? AppColors.warning
                  : isQuietest
                      ? AppColors.accent
                      : AppColors.primary.withValues(alpha: 0.45 + frac * 0.45);
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: isNarrow ? 2 : 1.5),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (bucket.containsCurrentHour)
                        Container(
                          width: 4,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 4),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.warning,
                          ),
                        ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeOutExpo,
                        height: bucket.value == 0
                            ? 3
                            : (frac * (chartHeight - 20))
                                .clamp(3, chartHeight - 20),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4)),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),
        // X-axis labels — show every 3 hours
        Row(
          children: buckets.asMap().entries.map((entry) {
            final index = entry.key;
            final bucket = entry.value;
            final showLabel = isNarrow || index == 0 || index.isEven;
            return Expanded(
              child: Text(
                showLabel ? _bucketLabel(bucket) : '',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                    fontSize: isNarrow ? 8 : 9, color: AppColors.textMuted),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        // Legend
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: [
            _LegendItem(color: AppColors.accent, label: 'Quietest'),
            _LegendItem(color: AppColors.warning, label: 'Right now'),
            _LegendItem(
                color: AppColors.primary.withValues(alpha: 0.9),
                label: isNarrow ? 'Busiest windows' : 'Busy hours'),
          ],
        ),
          ],
        );
      },
    );
  }

  String _bucketLabel(HourlyChartBucket bucket) {
    if (bucket.startHour == bucket.endHour) {
      return _shortHour(bucket.startHour);
    }
    return '${_shortHour(bucket.startHour)}-${_shortHour(bucket.endHour)}';
  }

  String _shortHour(int h) {
    if (h == 0) return '12A';
    if (h < 12) return '${h}A';
    if (h == 12) return '12P';
    return '${h - 12}P';
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 5),
        Text(label,
            style: GoogleFonts.inter(
                fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }
}

// ─── Tips Card ────────────────────────────────────────────────────────────────

class _TrafficTipsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const tips = [
      (
        Icons.wb_twilight_rounded,
        'Early mornings (6–8 AM)',
        'Typically the quietest window — equipment is always free.'
      ),
      (
        Icons.lunch_dining_rounded,
        'Late lunch (1–3 PM)',
        'Post-lunch hours see a dip before the evening rush.'
      ),
      (
        Icons.nights_stay_rounded,
        'Evening peak (5–7 PM)',
        'Most crowded time — plan ahead or arrive before 5 PM.'
      ),
    ];

    return GlassmorphicCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.lightbulb_rounded,
                    color: AppColors.warning, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Gym Traffic Tips',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...tips.map((t) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.bgElevated,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(t.$1,
                            color: AppColors.textSecondary, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t.$2,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              t.$3,
                              style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    ).animate(delay: 500.ms).fadeIn().slideY(begin: 0.1, end: 0);
  }
}

// ─── Shimmer placeholder ─────────────────────────────────────────────────────

class _ShimmerRow extends StatelessWidget {
  const _ShimmerRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(
        3,
        (i) => Padding(
          padding: const EdgeInsets.only(right: 10),
          child: Container(
            width: 90,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.bgElevated,
              borderRadius: BorderRadius.circular(12),
            ),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .fade(begin: 0.4, end: 0.8, duration: 800.ms),
        ),
      ),
    );
  }
}
