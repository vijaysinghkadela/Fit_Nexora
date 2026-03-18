import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/database_values.dart';
import '../../core/extensions.dart';
import '../../providers/auth_provider.dart';
import '../../providers/elite_member_provider.dart';
import '../../providers/member_provider.dart';
import '../../providers/pro_member_provider.dart';
import '../../widgets/glassmorphic_card.dart';
import '../../widgets/loading_widgets.dart';
import '../member/member_paywall_screen.dart';
import '../pro/pro_paywall_screen.dart';
import 'elite_paywall_screen.dart';
import 'elite_ai_trainer_screen.dart';
import 'elite_supplement_screen.dart';
import 'elite_muscle_progress_screen.dart';
import 'elite_transformation_screen.dart';
import 'elite_chat_screen.dart';

/// Elite Plan Home — gates on Basic → Pro → Elite membership tiers.
class EliteHomeScreen extends ConsumerWidget {
  const EliteHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(memberHasAccessProvider).when(
      loading: () => const _LoadingScaffold(),
      error: (_, __) => const MemberPaywallScreen(),
      data: (hasBasic) {
        if (!hasBasic) return const MemberPaywallScreen();
        return ref.watch(memberHasProAccessProvider).when(
          loading: () => const _LoadingScaffold(),
          error: (_, __) => const ProPaywallScreen(),
          data: (hasPro) {
            if (!hasPro) return const ProPaywallScreen();
            return ref.watch(memberHasEliteAccessProvider).when(
              loading: () => const _LoadingScaffold(),
              error: (_, __) => const ElitePaywallScreen(),
              data: (hasElite) {
                if (!hasElite) return const ElitePaywallScreen();
                return const _EliteDashboard();
              },
            );
          },
        );
      },
    );
  }
}

class _LoadingScaffold extends StatelessWidget {
  const _LoadingScaffold();
  @override
  Widget build(BuildContext context) => const DashboardSkeletonScaffold();
}

// ─── Elite Dashboard ──────────────────────────────────────────────────────────

class _EliteDashboard extends ConsumerWidget {
  const _EliteDashboard();

  static const _purple = Color(0xFF9C27B0);
  static const _indigo = Color(0xFF3F51B5);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.fitTheme;
    final user = ref.watch(currentUserProvider).value;
    final membershipAsync = ref.watch(memberMembershipProvider);
    final supplementsAsync = ref.watch(eliteSupplementsProvider);
    final chatAsync = ref.watch(eliteTrainerChatProvider);
    final firstName = user?.fullName.split(' ').first ?? 'Member';
    Future<void> refreshAll() async {
      ref.invalidate(memberMembershipProvider);
      ref.invalidate(eliteSupplementsProvider);
      ref.invalidate(eliteTrainerChatProvider);
      await Future.wait([
        ref.read(memberMembershipProvider.future),
        ref.read(eliteSupplementsProvider.future),
      ]);
    }

    return Scaffold(
      backgroundColor: t.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: refreshAll,
          backgroundColor: t.surface,
          color: t.brand,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
          // ─── AppBar ────────────────────────────────────────────────
          SliverAppBar(
            floating: true,
            backgroundColor: t.background,
            toolbarHeight: 86,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text('Welcome, ',
                      style: GoogleFonts.inter(
                          fontSize: 13, color: t.textSecondary)),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [_purple, _indigo]),
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                            color: _purple.withOpacity(0.4),
                            blurRadius: 10)
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.diamond_rounded,
                            color: Colors.white, size: 11),
                        const SizedBox(width: 4),
                        Text('ELITE',
                            style: GoogleFonts.inter(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 1.2)),
                      ],
                    ),
                  ),
                ]),
                Text(firstName,
                    style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: t.textPrimary)),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.psychology_rounded, color: _purple),
                tooltip: 'AI Trainer',
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(
                        builder: (_) => const EliteAiTrainerScreen())),
              ),
              IconButton(
                icon: chatAsync.when(
                  data: (msgs) {
                    final unread = msgs
                        .where((m) =>
                            m['sender_role'] ==
                                DatabaseValues.trainerChatTrainerRole &&
                            m['is_read'] == false)
                        .length;
                    return Badge(
                      isLabelVisible: unread > 0,
                      label: Text('$unread'),
                      child: Icon(Icons.chat_rounded,
                          color: t.accent),
                    );
                  },
                  loading: () => Icon(Icons.chat_rounded,
                      color: t.accent),
                  error: (_, __) => Icon(Icons.chat_rounded,
                      color: t.accent),
                ),
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(
                        builder: (_) => const EliteChatScreen())),
              ),
              const SizedBox(width: 8),
            ],
          ),

          // ─── Membership banner ─────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            sliver: SliverToBoxAdapter(
              child: membershipAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (m) => m == null
                    ? const SizedBox.shrink()
                    : _MembershipBanner(membership: m),
              ),
            ),
          ),

          // ─── Quick Action Grid ─────────────────────────────────────
          _sectionHeader('YOUR ELITE FEATURES'),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
            sliver: SliverToBoxAdapter(
              child: _EliteFeatureGrid(context: context),
            ),
          ),

          // ─── Supplements Today ─────────────────────────────────────
          _sectionHeader("TODAY'S SUPPLEMENTS"),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
            sliver: SliverToBoxAdapter(
              child: supplementsAsync.when(
                loading: () => _shimmer(80),
                error: (_, __) => const SizedBox.shrink(),
                data: (logs) => GlassmorphicCard(
                  child: logs.isEmpty
                      ? ListTile(
                          leading: Icon(Icons.medication_rounded,
                              color: t.accent),
                          title: Text('No supplements logged today',
                              style: GoogleFonts.inter(
                                  color: t.textSecondary,
                                  fontSize: 14)),
                          trailing: TextButton(
                            onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const EliteSupplementScreen())),
                            child: const Text('Log'),
                          ),
                        )
                      : Column(
                          children: logs.take(3).map((s) {
                            return ListTile(
                              leading: Icon(Icons.medication_rounded,
                                  color: t.accent, size: 20),
                              title: Text(
                                s['supplement_name'] as String? ?? '',
                                style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: t.textPrimary),
                              ),
                              subtitle: Text(
                                '${s['dose_mg'] ?? ''} mg · ${s['timing'] ?? ''}',
                                style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: t.textSecondary),
                              ),
                              trailing: Icon(Icons.check_circle_rounded,
                                  color: t.success, size: 20),
                            );
                          }).toList(),
                        ),
                ).animate(delay: 100.ms).fadeIn(),
              ),
            ),
          ),

          // ─── Trainer Chat Preview ──────────────────────────────────
          _sectionHeader('TRAINER CHAT'),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
            sliver: SliverToBoxAdapter(
              child: GestureDetector(
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(
                        builder: (_) => const EliteChatScreen())),
                child: chatAsync.when(
                  loading: () => _shimmer(80),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (msgs) => GlassmorphicCard(
                    child: msgs.isEmpty
                        ? ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                    colors: [_purple, _indigo]),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.chat_rounded,
                                  color: Colors.white, size: 18),
                            ),
                            title: Text('Start chatting with your trainer',
                                style: GoogleFonts.inter(
                                    color: t.textPrimary,
                                    fontSize: 14)),
                            subtitle: Text('Real-time messaging → 24/7',
                                style: GoogleFonts.inter(
                                    color: t.textSecondary,
                                    fontSize: 12)),
                            trailing: Icon(Icons.chevron_right_rounded,
                                color: t.textMuted),
                          )
                        : _ChatPreviewTile(
                            last: msgs.last, total: msgs.length),
                  ),
                ).animate(delay: 150.ms).fadeIn(),
              ),
            ),
          ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    // NOTE: these helper methods are called from build() which has `t` in scope,
    // but since these are non-static methods on ConsumerWidget they don't receive context.
    // We use a Builder approach here — keeping the label style minimal without t.
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      sliver: SliverToBoxAdapter(
        child: Builder(builder: (ctx) {
          final tt = ctx.fitTheme;
          return Text(title,
              style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: tt.textMuted,
                  letterSpacing: 1.2));
        }),
      ),
    );
  }

  Widget _shimmer(double h) {
    return Builder(builder: (ctx) {
      final tt = ctx.fitTheme;
      return Container(
        height: h,
        decoration: BoxDecoration(
          color: tt.surfaceAlt,
          borderRadius: BorderRadius.circular(16),
        ),
      ).animate(onPlay: (c) => c.repeat()).shimmer(
          duration: 1200.ms, color: tt.surface.withOpacity(0.5));
    });
  }
}

// ─── Feature Grid ─────────────────────────────────────────────────────────────

class _EliteFeatureGrid extends StatelessWidget {
  final BuildContext context;
  const _EliteFeatureGrid({required this.context});

  static const _purple = Color(0xFF9C27B0);

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;
    final items = [
      (Icons.psychology_rounded, 'AI Trainer', _purple,
          () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => const EliteAiTrainerScreen()))),
      (Icons.medication_rounded, 'Supplements', t.accent,
          () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => const EliteSupplementScreen()))),
      (Icons.fitness_center_rounded, 'Muscle Progress', t.brand,
          () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => const EliteMuscleProgressScreen()))),
      (Icons.compare_rounded, 'Transformation', t.warning,
          () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => const EliteTransformationScreen()))),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 2.1,
      children: items.asMap().entries.map((entry) {
        final i = entry.key;
        final (icon, label, color, onTap) = entry.value;
        return GestureDetector(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color.withOpacity(0.25)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(width: 10),
                Text(label,
                    style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: t.textPrimary)),
              ],
            ),
          ).animate(delay: (i * 60).ms).fadeIn().slideY(begin: 0.04),
        );
      }).toList(),
    );
  }
}

// ─── Membership Banner ────────────────────────────────────────────────────────

class _MembershipBanner extends StatelessWidget {
  final dynamic membership;
  const _MembershipBanner({required this.membership});

  static const _purple = Color(0xFF9C27B0);
  static const _indigo = Color(0xFF3F51B5);

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;
    final daysLeft = membership.daysRemaining as int;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [_purple.withOpacity(0.15),
                _indigo.withOpacity(0.08)]),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _purple.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.diamond_rounded, color: _purple, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(membership.planName as String,
                    style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: t.textPrimary)),
                Text('$daysLeft days remaining · Elite Access',
                    style: GoogleFonts.inter(
                        fontSize: 11, color: t.textSecondary)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: t.success.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: t.success.withOpacity(0.3)),
            ),
            child: Text('ACTIVE',
                style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: t.success,
                    letterSpacing: 1)),
          ),
        ],
      ),
    );
  }
}

// ─── Chat Preview ─────────────────────────────────────────────────────────────

class _ChatPreviewTile extends StatelessWidget {
  final Map<String, dynamic> last;
  final int total;
  const _ChatPreviewTile({required this.last, required this.total});

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;
    final isTrainer =
        last['sender_role'] == DatabaseValues.trainerChatTrainerRole;
    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: CircleAvatar(
        backgroundColor: isTrainer
            ? const Color(0xFF9C27B0).withOpacity(0.2)
            : t.brand.withOpacity(0.2),
        child: Icon(
          isTrainer ? Icons.person_rounded : Icons.face_rounded,
          color: isTrainer ? const Color(0xFF9C27B0) : t.brand,
          size: 20,
        ),
      ),
      title: Text(
        isTrainer ? 'Trainer' : 'You',
        style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: t.textPrimary),
      ),
      subtitle: Text(
        last['message'] as String? ?? '',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.inter(
            fontSize: 12, color: t.textSecondary),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('$total msgs',
              style: GoogleFonts.inter(
                  fontSize: 10, color: t.textMuted)),
          Icon(Icons.chevron_right_rounded,
              color: t.textMuted, size: 18),
        ],
      ),
    );
  }
}
