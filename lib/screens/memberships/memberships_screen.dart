import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';


import '../../core/extensions.dart';
import '../../core/pagination.dart';
import '../../models/client_profile_model.dart';
import '../../models/membership_counts.dart';
import '../../models/membership_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/gym_provider.dart';
import '../../providers/membership_provider.dart';
import '../../widgets/error_widgets.dart';
import '../../widgets/loading_widgets.dart';
import 'add_membership_screen.dart';

class MembershipsScreen extends ConsumerStatefulWidget {
  const MembershipsScreen({super.key});

  @override
  ConsumerState<MembershipsScreen> createState() => _MembershipsScreenState();
}

class _MembershipsScreenState extends ConsumerState<MembershipsScreen> {
  Future<void> _handleRefresh() async {
    ref.invalidate(membershipCountsProvider);
    await ref.read(pagedMembershipsControllerProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;
    final gym = ref.watch(selectedGymProvider);
    final membershipsState = ref.watch(pagedMembershipsControllerProvider);
    final countsAsync = ref.watch(membershipCountsProvider);

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      backgroundColor: t.surface,
      color: t.brand,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverAppBar(
            floating: true,
            leading: BackButton(
              onPressed: () => context.canPop() ? context.pop() : context.go('/'),
            ),
            backgroundColor: t.background,
            toolbarHeight: 72,
            title: Text(
              'Memberships',
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: t.textPrimary,
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: FilledButton.icon(
                  onPressed: () => _showClientPickerSheet(context),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: Text(
                    'Add',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: t.accent,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            sliver: SliverToBoxAdapter(
              child: _buildFilterChips(),
            ),
          ),
          if (gym != null)
            _buildMembershipList(membershipsState, countsAsync)
          else
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Text(
                  'No gym selected',
                  style: GoogleFonts.inter(color: t.textMuted),
                ),
              ),
            ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final t = context.fitTheme;
    final filters = {
      'all': 'All',
      'active': 'Active',
      'expiring': 'Expiring Soon',
      'expired': 'Expired',
    };
    final currentFilter = ref.watch(membershipFilterProvider);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.entries.map((entry) {
          final isSelected = currentFilter == entry.key;
          final color = _filterColor(entry.key);
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: isSelected,
              label: Text(entry.value),
              labelStyle: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? color : t.textSecondary,
              ),
              backgroundColor: t.surfaceAlt,
              selectedColor: color.withOpacity(0.15),
              side: BorderSide(
                color: isSelected ? color : t.border,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              showCheckmark: false,
              onSelected: (_) =>
                  ref.read(membershipFilterProvider.notifier).state = entry.key,
            ),
          );
        }).toList(),
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Color _filterColor(String filter) {
    final t = context.fitTheme;
    switch (filter) {
      case 'active':
        return t.success;
      case 'expiring':
        return t.warning;
      case 'expired':
        return t.danger;
      default:
        return t.brand;
    }
  }

  Widget _buildMembershipList(
    PagedListState<Membership> membershipsState,
    AsyncValue<MembershipCounts> countsAsync,
  ) {
    final t = context.fitTheme;
    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: countsAsync.when(
              loading: () => const Row(
                children: [
                  Expanded(child: SkeletonBox(height: 34)),
                  SizedBox(width: 10),
                  Expanded(child: SkeletonBox(height: 34)),
                  SizedBox(width: 10),
                  Expanded(child: SkeletonBox(height: 34)),
                ],
              ),
              error: (_, __) => const SizedBox.shrink(),
              data: (counts) => _buildCountChips(
                counts.total,
                counts.active,
                counts.expiring,
              ).animate().fadeIn(duration: 300.ms),
            ),
          ),
        ),
        if (membershipsState.isInitialLoading)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, __) => const CardSkeleton(height: 110),
                childCount: 6,
              ),
            ),
          )
        else if (membershipsState.items.isEmpty && membershipsState.hasError)
          SliverFillRemaining(
            hasScrollBody: false,
            child: ErrorStateWidget(
              message: 'Unable to load memberships right now.',
              onRetry: () =>
                  ref.read(pagedMembershipsControllerProvider.notifier).loadInitial(),
            ),
          )
        else if (membershipsState.items.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.card_membership_outlined,
                    size: 56,
                    color: t.textMuted.withOpacity(0.4),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No memberships found',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: t.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add a membership from a client profile.',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: t.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  if (index == membershipsState.items.length) {
                    return LoadingFooter(
                      isLoading: membershipsState.isLoadingMore,
                      hasMore: membershipsState.hasMore,
                      error: membershipsState.items.isNotEmpty
                          ? membershipsState.error
                          : null,
                      onPressed: () => ref
                          .read(pagedMembershipsControllerProvider.notifier)
                          .loadMore(),
                    );
                  }

                  return _MembershipCard(
                    membership: membershipsState.items[index],
                    delay: index * 50,
                  );
                },
                childCount: membershipsState.items.length + 1,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCountChips(int total, int active, int expiring) {
    final t = context.fitTheme;
    return Row(
      children: [
        _CountChip(label: 'Total', count: total, color: t.brand),
        const SizedBox(width: 10),
        _CountChip(label: 'Active', count: active, color: t.success),
        const SizedBox(width: 10),
        _CountChip(label: 'Expiring', count: expiring, color: t.warning),
      ],
    );
  }

  void _showClientPickerSheet(BuildContext context) {
    final gym = ref.read(selectedGymProvider);
    if (gym == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ClientPickerSheet(
        gymId: gym.id,
        onClientSelected: (client) {
          Navigator.of(context).pop();
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => AddMembershipScreen(client: client),
          );
        },
      ),
    );
  }
}

class _CountChip extends StatelessWidget {
  const _CountChip({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$count',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}

class _MembershipCard extends StatelessWidget {
  const _MembershipCard({
    required this.membership,
    required this.delay,
  });

  final Membership membership;
  final int delay;

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;
    final statusColor = _getStatusColor(t);
    final progress = _getProgress();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: t.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: t.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: statusColor,
                  boxShadow: [
                    BoxShadow(
                      color: statusColor.withOpacity(0.4),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      membership.planName,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: t.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${membership.startDate.dayMonth} -> ${membership.endDate.dayMonth}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: t.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (membership.amount != null)
                    Text(
                      membership.amount!.inr,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: t.textPrimary,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _getStatusLabel(),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (!membership.isExpired && progress != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 5,
                backgroundColor: t.surface,
                valueColor: AlwaysStoppedAnimation<Color>(
                  progress < 0.3 ? t.warning : t.success,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              membership.daysRemaining >= 0
                  ? '${membership.daysRemaining} days remaining'
                  : 'Expired',
              style: GoogleFonts.inter(
                fontSize: 10,
                color: t.textMuted,
              ),
            ),
          ],
        ],
      ),
    )
        .animate(delay: Duration(milliseconds: delay))
        .fadeIn(duration: 300.ms)
        .slideX(begin: 0.03, end: 0);
  }

  double? _getProgress() {
    final total = membership.endDate.difference(membership.startDate).inDays;
    if (total <= 0) return null;
    final remaining = membership.daysRemaining;
    if (remaining < 0) return 0;
    return remaining / total;
  }

  Color _getStatusColor(dynamic t) {
    if (membership.isExpired) return t.danger;
    if (membership.expiresWithin(7)) return t.warning;
    return t.success;
  }

  String _getStatusLabel() {
    if (membership.isExpired) return 'Expired';
    if (membership.expiresWithin(3)) return 'Expiring!';
    if (membership.expiresWithin(7)) return '${membership.daysRemaining}d left';
    return 'Active';
  }
}

class _ClientPickerSheet extends ConsumerWidget {
  const _ClientPickerSheet({
    required this.gymId,
    required this.onClientSelected,
  });

  final String gymId;
  final ValueChanged<ClientProfile> onClientSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.fitTheme;
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: BoxDecoration(
        color: t.surfaceAlt,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: t.glassBorder, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: t.textMuted.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
            child: Text(
              'Select a Client',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: t.textPrimary,
              ),
            ),
          ),
          Divider(color: t.divider, height: 1),
          Expanded(
            child: FutureBuilder<List<ClientProfile>>(
              future: ref.read(databaseServiceProvider).getClientsForGym(gymId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 16,
                    ),
                    itemCount: 5,
                    itemBuilder: (_, __) => const ListTileSkeleton(),
                  );
                }
                if (snapshot.hasError) {
                  return ErrorStateWidget(
                    message: 'Unable to load clients.',
                    onRetry: () => (context as Element).markNeedsBuild(),
                  );
                }
                final clients = snapshot.data ?? [];
                if (clients.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'No clients found. Add a client first.',
                        style: GoogleFonts.inter(color: t.textMuted),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  itemCount: clients.length,
                  itemBuilder: (context, index) {
                    final client = clients[index];
                    final initial = (client.fullName?.isNotEmpty == true)
                        ? client.fullName![0].toUpperCase()
                        : '?';
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: t.brand.withOpacity(0.15),
                        child: Text(
                          initial,
                          style: GoogleFonts.inter(
                            color: t.brand,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      title: Text(
                        client.fullName ?? 'Unnamed',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: t.textPrimary,
                        ),
                      ),
                      subtitle: client.email != null
                          ? Text(
                              client.email!,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: t.textMuted,
                              ),
                            )
                          : null,
                      trailing: Icon(
                        Icons.chevron_right_rounded,
                        color: t.textMuted,
                      ),
                      onTap: () => onClientSelected(client),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    ).animate().slideY(begin: 0.05, end: 0, duration: 300.ms).fadeIn();
  }
}
