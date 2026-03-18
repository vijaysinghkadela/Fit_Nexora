import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/extensions.dart';
import '../../providers/auth_provider.dart';
import '../../providers/elite_member_provider.dart';
import '../../providers/master_member_provider.dart';
import '../../providers/member_provider.dart';
import '../../providers/pro_member_provider.dart';
import '../../widgets/glassmorphic_card.dart';
import '../../widgets/loading_widgets.dart';
import '../elite/elite_paywall_screen.dart';
import '../member/member_paywall_screen.dart';
import '../pro/pro_paywall_screen.dart';
import 'master_paywall_screen.dart';

/// Master tier home rebuilt around the stitched premium dashboard layout.
class MasterHomeScreen extends ConsumerWidget {
  const MasterHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(memberHasAccessProvider).when(
          loading: () => const DashboardSkeletonScaffold(),
          error: (_, __) => const MemberPaywallScreen(),
          data: (ok) => !ok
              ? const MemberPaywallScreen()
              : ref.watch(memberHasProAccessProvider).when(
                    loading: () => const DashboardSkeletonScaffold(),
                    error: (_, __) => const ProPaywallScreen(),
                    data: (ok) => !ok
                        ? const ProPaywallScreen()
                        : ref.watch(memberHasEliteAccessProvider).when(
                              loading: () => const DashboardSkeletonScaffold(),
                              error: (_, __) => const ElitePaywallScreen(),
                              data: (ok) => !ok
                                  ? const ElitePaywallScreen()
                                  : ref.watch(memberHasMasterAccessProvider).when(
                                        loading: () =>
                                            const DashboardSkeletonScaffold(),
                                        error: (_, __) =>
                                            const MasterPaywallScreen(),
                                        data: (ok) => !ok
                                            ? const MasterPaywallScreen()
                                            : const _MasterDashboard(),
                                      ),
                            ),
                  ),
        );
  }
}

class _MasterDashboard extends ConsumerWidget {
  const _MasterDashboard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.fitTheme;
    final user = ref.watch(currentUserProvider).value;
    final recoveryAsync = ref.watch(masterRecoveryScoreProvider);
    final nutritionAsync = ref.watch(proTodayNutritionProvider);
    final firstName = ((user?.fullName ?? '').trim().isEmpty)
        ? 'Alex'
        : user!.fullName.split(' ').first;
    final recoveryScore = recoveryAsync.maybeWhen(
      data: (value) => value,
      orElse: () => 0,
    );

    Future<void> refreshAll() async {
      ref.invalidate(masterRecoveryScoreProvider);
      ref.invalidate(proTodayNutritionProvider);
      await Future.wait([
        ref.read(masterRecoveryScoreProvider.future),
        ref.read(proTodayNutritionProvider.future),
      ]);
    }

    return Scaffold(
      backgroundColor: colors.background,
      body: RefreshIndicator(
        onRefresh: refreshAll,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              floating: true,
              backgroundColor: colors.background.withOpacity(0.96),
              title: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      gradient: colors.brandGradient,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'F',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'FitNexora',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: colors.textPrimary,
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  onPressed: () => context.go('/master/analytics'),
                  icon: const Icon(Icons.analytics_outlined),
                ),
                IconButton(
                  onPressed: () => context.go('/settings'),
                  icon: const Icon(Icons.settings_outlined),
                ),
                const SizedBox(width: 8),
              ],
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        gradient: colors.brandGradient,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        firstName[0].toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ELITE MEMBER',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: colors.textMuted,
                              letterSpacing: 1.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Welcome, $firstName',
                            style: GoogleFonts.inter(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: colors.textPrimary,
                              letterSpacing: -0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: colors.border),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'RANK',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: colors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '#12',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: colors.accent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              sliver: SliverToBoxAdapter(
                child: recoveryAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (score) {
                    final readiness = score.round().clamp(0, 100);
                    final progress = readiness / 100;
                    final loadLabel = readiness >= 80
                        ? 'Peak performance'
                        : readiness >= 60
                            ? 'Ready to push'
                            : 'Recovery focus';
                    return GlassmorphicCard(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            SizedBox(
                              width: 176,
                              height: 176,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  SizedBox(
                                    width: 176,
                                    height: 176,
                                    child: CircularProgressIndicator(
                                      value: progress.toDouble(),
                                      strokeWidth: 10,
                                      color: colors.brand,
                                      backgroundColor: colors.ringTrack,
                                    ),
                                  ),
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '$readiness',
                                        style: GoogleFonts.inter(
                                          fontSize: 48,
                                          fontWeight: FontWeight.w800,
                                          color: colors.textPrimary,
                                        ),
                                      ),
                                      Text(
                                        'READINESS',
                                        style: GoogleFonts.inter(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          color: colors.textMuted,
                                          letterSpacing: 1.1,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 18),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: colors.accent.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                loadLabel.toUpperCase(),
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: colors.accent,
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'Your CNS is ready for high-intensity training',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: colors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'AI detected optimal recovery levels across your vital metrics.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: colors.textSecondary,
                                height: 1.45,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
              sliver: SliverToBoxAdapter(
                child: nutritionAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (nutrition) => Row(
                    children: [
                      Expanded(
                        child: _MiniMetric(
                          label: 'Heart rate',
                          value: '72',
                          unit: 'bpm',
                          icon: Icons.favorite_rounded,
                          color: colors.danger,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _MiniMetric(
                          label: 'Kcal burned',
                          value: '${nutrition.calories.round()}',
                          unit: '',
                          icon: Icons.local_fire_department_rounded,
                          color: colors.accent,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _MiniMetric(
                          label: 'Load',
                          value: recoveryScore >= 80
                              ? 'High'
                              : 'Mod',
                          unit: '',
                          icon: Icons.bolt_rounded,
                          color: colors.brand,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
              sliver: SliverToBoxAdapter(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'MASTER FEATURES',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: colors.textMuted,
                        letterSpacing: 1.2,
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.go('/master/analytics'),
                      child: const Text('See All'),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverToBoxAdapter(
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _FeatureChip(
                      icon: Icons.videocam_outlined,
                      label: 'Live',
                      onTap: () => context.go('/master/live'),
                    ),
                    _FeatureChip(
                      icon: Icons.smart_toy_outlined,
                      label: 'Coach',
                      selected: true,
                      onTap: () => context.go('/master/ai'),
                    ),
                    _FeatureChip(
                      icon: Icons.bar_chart_rounded,
                      label: 'Stats',
                      onTap: () => context.go('/master/analytics'),
                    ),
                    _FeatureChip(
                      icon: Icons.emoji_events_outlined,
                      label: 'Rank',
                      onTap: () => context.go('/master/challenges'),
                    ),
                    _FeatureChip(
                      icon: Icons.health_and_safety_outlined,
                      label: 'Recovery',
                      onTap: () => context.go('/master/recovery'),
                    ),
                    _FeatureChip(
                      icon: Icons.star_rounded,
                      label: 'Perks',
                      onTap: () => context.go('/master/perks'),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
              sliver: SliverToBoxAdapter(
                child: Text(
                  'RECOMMENDED TODAY',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: colors.textMuted,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
              sliver: SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colors.surface,
                        colors.surfaceAlt,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: colors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: colors.brand.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'MASTER TIER',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: colors.brand,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Hypertrophy V4: Elite Force',
                        style: GoogleFonts.inter(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: colors.textPrimary,
                          letterSpacing: -0.9,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Advanced strength and conditioning block tailored to your current readiness.',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: colors.textSecondary,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 18),
                      FilledButton.icon(
                        onPressed: () => context.go('/master/ai'),
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: const Text('Start Session'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;

  const _MiniMetric({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.fitTheme;
    return GlassmorphicCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Flexible(
                  child: Text(
                    value,
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: colors.textPrimary,
                    ),
                  ),
                ),
                if (unit.isNotEmpty) ...[
                  const SizedBox(width: 4),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Text(
                      unit,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: colors.textMuted,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 6),
            Text(
              label.toUpperCase(),
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: colors.textMuted,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FeatureChip({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.fitTheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? colors.brand.withOpacity(0.12) : colors.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? colors.brand : colors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: selected ? colors.brand : colors.textSecondary),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: selected ? colors.brand : colors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
