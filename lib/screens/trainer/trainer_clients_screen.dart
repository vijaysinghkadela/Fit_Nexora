import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/theme.dart';
import '../../core/extensions.dart';
import '../../models/client_profile_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/client_provider.dart';
import '../../widgets/fit_management_scaffold.dart';
import '../../widgets/glassmorphic_card.dart';
import '../clients/add_client_screen.dart';
import '../clients/client_detail_screen.dart';
import 'trainer_dashboard_screen.dart';

/// Trainer-specific clients screen — shows only THIS trainer's assigned clients.
class TrainerClientsScreen extends ConsumerStatefulWidget {
  const TrainerClientsScreen({super.key});

  @override
  ConsumerState<TrainerClientsScreen> createState() =>
      _TrainerClientsScreenState();
}

class _TrainerClientsScreenState extends ConsumerState<TrainerClientsScreen> {
  String _filterMode = 'All';

  static const _filters = [
    'All',
    'In Gym Today',
    'Active Plan',
    'Low Adherence',
    'No Plan Assigned',
  ];

  List<ClientProfile> _applyFilter(
      List<ClientProfile> clients, String filter) {
    final today = DateTime.now();
    switch (filter) {
      case 'In Gym Today':
        return clients.where((c) {
          final last = c.lastGymVisit;
          return last != null &&
              last.year == today.year &&
              last.month == today.month &&
              last.day == today.day;
        }).toList();
      case 'Active Plan':
        return clients
            .where((c) =>
                c.currentPlanName != null && c.currentPlanName!.isNotEmpty)
            .toList();
      case 'Low Adherence':
        return clients
            .where((c) => (c.adherencePercent ?? 100) < 75)
            .toList();
      case 'No Plan Assigned':
        return clients
            .where((c) =>
                c.currentPlanName == null || c.currentPlanName!.isEmpty)
            .toList();
      default:
        return clients;
    }
  }

  bool _isInGymToday(ClientProfile client) {
    final last = client.lastGymVisit;
    if (last == null) return false;
    final today = DateTime.now();
    return last.year == today.year &&
        last.month == today.month &&
        last.day == today.day;
  }

  void _showAddClientSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddClientScreen(),
    );
  }

  void _navigateToDetail(BuildContext context, ClientProfile client) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ClientDetailScreen(client: client),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;
    final currentUser = ref.watch(currentUserProvider).value;
    final userName = (currentUser?.fullName ?? '').trim().isEmpty
        ? 'Coach Alex'
        : currentUser!.fullName;
    final userEmail = currentUser?.email ?? '';

    final clientsAsync = ref.watch(trainerClientsProvider);
    final todayCountAsync = ref.watch(trainerTodayActiveClientsProvider);

    return FitManagementScaffold(
      currentRoute: '/trainer/clients',
      destinations: trainerDestinations,
      mobileDestinations: trainerDestinations,
      userName: userName,
      userEmail: userEmail,
      onSignOut: () {
        ref.read(currentUserProvider.notifier).signOut().then((_) {
          if (context.mounted) context.go('/login');
        }).catchError((_) {
          if (context.mounted) context.go('/login');
        });
      },
      child: clientsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline_rounded,
                  size: 48, color: t.danger.withOpacity(0.7)),
              const SizedBox(height: 16),
              Text(
                'Unable to load clients',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: t.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                err.toString(),
                style: GoogleFonts.inter(fontSize: 13, color: t.textMuted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => ref.invalidate(trainerClientsProvider),
                style: FilledButton.styleFrom(backgroundColor: t.brand),
                child: Text(
                  'Retry',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        data: (allClients) {
          final filtered = _applyFilter(allClients, _filterMode);
          final todayCount = todayCountAsync.value ?? 0;
          final lowAdherenceCount =
              allClients.where((c) => (c.adherencePercent ?? 100) < 75).length;

          return CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // ── App Bar ──────────────────────────────────────────────────
              SliverAppBar(
                pinned: true,
                automaticallyImplyLeading: false,
                backgroundColor: t.background,
                toolbarHeight: 72,
                title: Text(
                  'My Clients',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: t.textPrimary,
                  ),
                ),
                actions: [
                  // "In Gym Today" badge
                  if (todayCount > 0)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: t.success.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: t.success.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: t.success,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'In Gym: $todayCount',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: t.success,
                            ),
                          ),
                        ],
                      ),
                    ),
                  // Add Client button
                  Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: FilledButton.icon(
                      onPressed: () => _showAddClientSheet(context),
                      icon: const Icon(Icons.person_add_rounded, size: 18),
                      label: Text(
                        'Add Client',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: t.brand,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // ── Summary Strip ─────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: _SummaryStrip(
                    total: allClients.length,
                    inGymToday: todayCount,
                    lowAdherence: lowAdherenceCount,
                  ),
                ).animate().fadeIn(duration: 350.ms).slideY(begin: -0.04, end: 0),
              ),

              // ── Filter Chips ──────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 0, 16),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: _filters.map((filter) {
                        final isSelected = _filterMode == filter;
                        return Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: FilterChip(
                            selected: isSelected,
                            label: Text(filter),
                            labelStyle: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isSelected
                                  ? t.brand
                                  : t.textSecondary,
                            ),
                            backgroundColor: t.surfaceAlt,
                            selectedColor: t.brand.withOpacity(0.14),
                            side: BorderSide(
                              color: isSelected
                                  ? t.brand.withOpacity(0.5)
                                  : t.border,
                              width: isSelected ? 1.5 : 1.0,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            showCheckmark: false,
                            onSelected: (_) =>
                                setState(() => _filterMode = filter),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ).animate(delay: 80.ms).fadeIn(duration: 350.ms),
              ),

              // ── Client List ───────────────────────────────────────────────
              if (filtered.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyState(
                    filterMode: _filterMode,
                    onAddClient: () => _showAddClientSheet(context),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final client = filtered[index];
                        return _TrainerClientCard(
                          client: client,
                          isInGymToday: _isInGymToday(client),
                          delay: index * 40,
                          onTap: () =>
                              _navigateToDetail(context, client),
                        );
                      },
                      childCount: filtered.length,
                    ),
                  ),
                ),

              // Bottom padding to clear the nav bar
              const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
            ],
          );
        },
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Summary Strip
// ────────────────────────────────────────────────────────────────────────────

class _SummaryStrip extends StatelessWidget {
  const _SummaryStrip({
    required this.total,
    required this.inGymToday,
    required this.lowAdherence,
  });

  final int total;
  final int inGymToday;
  final int lowAdherence;

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;
    return Row(
      children: [
        _StatChip(label: 'Total', value: total, color: t.brand),
        const SizedBox(width: 10),
        _StatChip(label: 'In Gym', value: inGymToday, color: t.success),
        const SizedBox(width: 10),
        _StatChip(
            label: 'Low Adherence',
            value: lowAdherence,
            color: lowAdherence > 0 ? t.warning : t.textMuted),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$value',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: t.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Trainer Client Card
// ────────────────────────────────────────────────────────────────────────────

class _TrainerClientCard extends StatefulWidget {
  const _TrainerClientCard({
    required this.client,
    required this.isInGymToday,
    required this.delay,
    required this.onTap,
  });

  final ClientProfile client;
  final bool isInGymToday;
  final int delay;
  final VoidCallback onTap;

  @override
  State<_TrainerClientCard> createState() => _TrainerClientCardState();
}

class _TrainerClientCardState extends State<_TrainerClientCard> {
  bool _isPressed = false;

  Color _adherenceColor(FitNexoraThemeTokens t, int? pct) {
    if (pct == null) return t.textMuted;
    if (pct >= 85) return t.success;
    if (pct >= 70) return t.warning;
    return t.danger;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;
    final client = widget.client;
    final initial = (client.fullName?.isNotEmpty == true)
        ? client.fullName![0].toUpperCase()
        : '?';
    final adherencePct = client.adherencePercent;
    final adherenceColor = _adherenceColor(t, adherencePct);
    final hasPlan = client.currentPlanName != null &&
        client.currentPlanName!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: 150.ms,
        curve: Curves.easeOutCubic,
        child: GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) {
            setState(() => _isPressed = false);
            widget.onTap();
          },
          onTapCancel: () => setState(() => _isPressed = false),
          child: GlassmorphicCard(
            borderRadius: 16,
            applyBlur: false,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Avatar with optional "IN GYM" badge
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              t.brand.withOpacity(0.22),
                              t.accent.withOpacity(0.12),
                            ],
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: t.brand.withOpacity(0.15)),
                        ),
                        child: Center(
                          child: Text(
                            initial,
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: t.brand,
                            ),
                          ),
                        ),
                      ),
                      if (widget.isInGymToday)
                        Positioned(
                          bottom: -4,
                          right: -4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: t.success,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                  color: t.background, width: 1.5),
                            ),
                            child: Text(
                              'IN GYM',
                              style: GoogleFonts.inter(
                                fontSize: 8,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 14),

                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name
                        Text(
                          client.fullName ?? 'Unnamed Client',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: t.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),

                        // Plan name
                        Text(
                          hasPlan
                              ? client.currentPlanName!
                              : 'No plan assigned',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: hasPlan
                                ? t.textSecondary
                                : t.textMuted,
                            fontStyle: hasPlan
                                ? FontStyle.normal
                                : FontStyle.italic,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),

                        // Adherence + Goal row
                        Row(
                          children: [
                            // Adherence %
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color:
                                    adherenceColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: adherenceColor
                                        .withOpacity(0.25)),
                              ),
                              child: Text(
                                adherencePct != null
                                    ? '$adherencePct% adherence'
                                    : 'No data',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: adherenceColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Goal chip
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: t.brand.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color:
                                        t.brand.withOpacity(0.2)),
                              ),
                              child: Text(
                                client.goal.label,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: t.brand,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Chevron
                  AnimatedContainer(
                    duration: 200.ms,
                    transform: Matrix4.translationValues(
                        _isPressed ? 4.0 : 0.0, 0, 0),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      color: _isPressed ? t.brand : t.textMuted,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: widget.delay))
        .fadeIn(duration: 350.ms)
        .slideX(begin: 0.04, end: 0);
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Empty State
// ────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.filterMode,
    required this.onAddClient,
  });

  final String filterMode;
  final VoidCallback onAddClient;

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;
    final isFiltered = filterMode != 'All';

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  t.brand.withOpacity(0.15),
                  t.accent.withOpacity(0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              isFiltered
                  ? Icons.filter_list_off_rounded
                  : Icons.people_outline_rounded,
              size: 40,
              color: t.brand.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            isFiltered ? 'No clients match "$filterMode"' : 'No clients assigned yet',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: t.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            isFiltered
                ? 'Try a different filter to see more clients.'
                : 'Add your first client to get started.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: t.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          if (!isFiltered) ...[
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: onAddClient,
              icon: const Icon(Icons.person_add_rounded, size: 18),
              label: Text(
                'Add Client',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: t.brand,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }
}
