import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
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
import 'master_ai_coach_screen.dart';
import 'master_analytics_screen.dart';
import 'master_recovery_screen.dart';
import 'master_challenges_screen.dart';
import 'master_live_sessions_screen.dart';

/// Master Plan Home — 4-layer paywall gate + gold dashboard.
class MasterHomeScreen extends ConsumerWidget {
  const MasterHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(memberHasAccessProvider).when(
      loading: () => const _LoadScaffold(),
      error: (_, __) => const MemberPaywallScreen(),
      data: (ok) => !ok
          ? const MemberPaywallScreen()
          : ref.watch(memberHasProAccessProvider).when(
              loading: () => const _LoadScaffold(),
              error: (_, __) => const ProPaywallScreen(),
              data: (ok) => !ok
                  ? const ProPaywallScreen()
                  : ref.watch(memberHasEliteAccessProvider).when(
                      loading: () => const _LoadScaffold(),
                      error: (_, __) => const ElitePaywallScreen(),
                      data: (ok) => !ok
                          ? const ElitePaywallScreen()
                          : ref.watch(memberHasMasterAccessProvider).when(
                              loading: () => const _LoadScaffold(),
                              error: (_, __) => const MasterPaywallScreen(),
                              data: (ok) => !ok
                                  ? const MasterPaywallScreen()
                                  : const _MasterDashboard(),
                            ),
                    ),
            ),
    );
  }
}

class _LoadScaffold extends StatelessWidget {
  const _LoadScaffold();
  @override
  Widget build(BuildContext context) => const DashboardSkeletonScaffold();
}

// ─── Master Dashboard ─────────────────────────────────────────────────────────

class _MasterDashboard extends ConsumerWidget {
  const _MasterDashboard();

  static const _gold  = Color(0xFFFFD700);
  static const _orange = Color(0xFFFF6F00);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user      = ref.watch(currentUserProvider).value;
    final recoveryAsync = ref.watch(masterRecoveryScoreProvider);
    final membershipAsync = ref.watch(memberMembershipProvider);
    final nutritionAsync  = ref.watch(proTodayNutritionProvider);
    final firstName = user?.fullName.split(' ').first ?? 'Master';
    Future<void> refreshAll() async {
      ref.invalidate(memberMembershipProvider);
      ref.invalidate(masterRecoveryScoreProvider);
      ref.invalidate(proTodayNutritionProvider);
      ref.invalidate(masterAnalyticsProvider);
      await Future.wait([
        ref.read(memberMembershipProvider.future),
        ref.read(masterRecoveryScoreProvider.future),
        ref.read(proTodayNutritionProvider.future),
      ]);
    }

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: refreshAll,
          backgroundColor: AppColors.bgElevated,
          color: AppColors.primary,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
          // ─── AppBar
          SliverAppBar(
            floating: true,
            backgroundColor: AppColors.bgDark,
            toolbarHeight: 90,
            title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text('Welcome back, ', style: GoogleFonts.inter(
                    fontSize: 13, color: AppColors.textSecondary)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [_gold, _orange]),
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [BoxShadow(color: _gold.withValues(alpha:0.5), blurRadius: 10)],
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.workspace_premium_rounded,
                        color: Colors.black, size: 11),
                    const SizedBox(width: 4),
                    Text('MASTER', style: GoogleFonts.inter(
                        fontSize: 9, fontWeight: FontWeight.w900,
                        color: Colors.black, letterSpacing: 1.2)),
                  ]),
                ),
              ]),
              Text(firstName, style: GoogleFonts.inter(
                  fontSize: 24, fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary)),
            ]),
            actions: [
              IconButton(
                icon: const Icon(Icons.analytics_rounded, color: _gold),
                tooltip: 'Analytics',
                onPressed: () => _push(context, const MasterAnalyticsScreen()),
              ),
              const SizedBox(width: 4),
            ],
          ),

          // ─── Membership + calorie strip
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
            sliver: SliverToBoxAdapter(
              child: membershipAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (m) => m == null ? const SizedBox.shrink()
                    : _MasterBanner(membership: m),
              ),
            ),
          ),

          // ─── Recovery ring
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            sliver: SliverToBoxAdapter(
              child: recoveryAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (score) => _RecoveryWidget(score: score),
              ),
            ),
          ),

          // ─── Feature grid
          _sectionLbl('YOUR MASTER FEATURES'),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
            sliver: SliverToBoxAdapter(child: _MasterGrid(context: context)),
          ),

          // ─── Today summary
          _sectionLbl("TODAY'S SUMMARY"),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
            sliver: SliverToBoxAdapter(
              child: nutritionAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (n) => GlassmorphicCard(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(children: [
                      _summaryTile('Calories', '${n.calories.round()}',
                          'kcal', AppColors.primary),
                      _vDivider(),
                      _summaryTile('Protein', '${n.protein.round()}',
                          'g', AppColors.accent),
                      _vDivider(),
                      _summaryTile('Carbs', '${n.carbs.round()}',
                          'g', AppColors.info),
                      _vDivider(),
                      _summaryTile('Fat', '${n.fat.round()}',
                          'g', AppColors.warning),
                    ]),
                  ),
                ).animate().fadeIn(),
              ),
            ),
          ),
            ],
          ),
        ),
      ),
    );
  }

  void _push(BuildContext ctx, Widget w) =>
      Navigator.push(ctx, MaterialPageRoute(builder: (_) => w));

  Widget _sectionLbl(String t) => SliverPadding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        sliver: SliverToBoxAdapter(
          child: Text(t, style: GoogleFonts.inter(
              fontSize: 11, fontWeight: FontWeight.w700,
              color: AppColors.textMuted, letterSpacing: 1.2)),
        ),
      );

  Widget _summaryTile(String label, String val, String unit, Color c) =>
      Expanded(child: Column(children: [
        Text(val, style: GoogleFonts.inter(
            fontSize: 18, fontWeight: FontWeight.w900, color: c)),
        Text(unit, style: GoogleFonts.inter(fontSize: 10, color: c)),
        const SizedBox(height: 2),
        Text(label, style: GoogleFonts.inter(
            fontSize: 10, color: AppColors.textMuted)),
      ]));

  Widget _vDivider() => Container(
      width: 1, height: 40,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: AppColors.divider);
}

// ─── Feature Grid ─────────────────────────────────────────────────────────────

class _MasterGrid extends StatelessWidget {
  final BuildContext context;
  const _MasterGrid({required this.context});

  static const _gold   = Color(0xFFFFD700);
  static const _orange = Color(0xFFFF6F00);

  void _push(Widget w) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => w));

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.smart_toy_rounded,          'AI Coach',     _gold,             () => _push(const MasterAiCoachScreen())),
      (Icons.analytics_rounded,          'Analytics',    AppColors.primary, () => _push(const MasterAnalyticsScreen())),
      (Icons.battery_charging_full_rounded,'Recovery',   AppColors.success, () => _push(const MasterRecoveryScreen())),
      (Icons.emoji_events_rounded,        'Challenges',  _orange,           () => _push(const MasterChallengesScreen())),
      (Icons.video_call_rounded,          'Live Sessions',AppColors.info,   () => _push(const MasterLiveSessionsScreen())),
      (Icons.support_agent_rounded,       'Priority Chat',AppColors.accent, () => _push(const MasterLiveSessionsScreen())),
    ];

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.1,
      children: items.asMap().entries.map((e) {
        final i = e.key;
        final (icon, label, color, onTap) = e.value;
        return GestureDetector(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color.withValues(alpha: 0.25)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 26),
                const SizedBox(height: 6),
                Text(label, textAlign: TextAlign.center,
                    style: GoogleFonts.inter(fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
              ],
            ),
          ).animate(delay: (i * 50).ms).fadeIn().scale(begin: const Offset(0.9, 0.9)),
        );
      }).toList(),
    );
  }
}

// ─── Recovery Widget ──────────────────────────────────────────────────────────

class _RecoveryWidget extends StatelessWidget {
  final int score;
  const _RecoveryWidget({required this.score});

  @override
  Widget build(BuildContext context) {
    final color = score >= 80
        ? AppColors.success
        : score >= 50
            ? AppColors.warning
            : AppColors.error;
    final label = score >= 80 ? 'Fully Recovered' : score >= 50 ? 'Moderate' : 'Need Rest';

    return GestureDetectorTip(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const MasterRecoveryScreen())),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [
            color.withValues(alpha: 0.12),
            color.withValues(alpha: 0.04),
          ]),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(children: [
          SizedBox(
            width: 60, height: 60,
            child: Stack(alignment: Alignment.center, children: [
              CircularProgressIndicator(
                value: score / 100,
                strokeWidth: 6,
                backgroundColor: AppColors.bgElevated,
                valueColor: AlwaysStoppedAnimation(color),
              ),
              Text('$score', style: GoogleFonts.inter(
                  fontSize: 15, fontWeight: FontWeight.w900, color: color)),
            ]),
          ),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Recovery Score', style: GoogleFonts.inter(
                fontSize: 13, color: AppColors.textSecondary)),
            Text(label, style: GoogleFonts.inter(
                fontSize: 18, fontWeight: FontWeight.w800, color: color)),
            Text('Tap for personalised recovery plan', style: GoogleFonts.inter(
                fontSize: 11, color: AppColors.textMuted)),
          ])),
          Icon(Icons.chevron_right_rounded, color: color),
        ]),
      ).animate().fadeIn(),
    );
  }
}

/// Wrapper so GestureDetector works cleanly inside a Container.
class GestureDetectorTip extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  const GestureDetectorTip({required this.child, required this.onTap, super.key});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(onTap: onTap, child: child);
  }
}

// ─── Membership Banner ────────────────────────────────────────────────────────

class _MasterBanner extends StatelessWidget {
  final dynamic membership;
  const _MasterBanner({required this.membership});

  static const _gold  = Color(0xFFFFD700);
  static const _orange = Color(0xFFFF6F00);

  @override
  Widget build(BuildContext context) {
    final days = membership.daysRemaining as int;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [_gold.withValues(alpha:0.12), _orange.withValues(alpha:0.06)]),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _gold.withValues(alpha:0.4)),
      ),
      child: Row(children: [
        const Icon(Icons.workspace_premium_rounded, color: _gold, size: 22),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(membership.planName as String,
              style: GoogleFonts.inter(fontSize: 14,
                  fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          Text('$days days remaining · Master Access',
              style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha:0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.success.withValues(alpha:0.3)),
          ),
          child: Text('ACTIVE', style: GoogleFonts.inter(
              fontSize: 10, fontWeight: FontWeight.w800,
              color: AppColors.success, letterSpacing: 1)),
        ),
      ]),
    );
  }
}
