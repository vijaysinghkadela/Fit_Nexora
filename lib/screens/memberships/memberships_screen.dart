import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../core/extensions.dart';
import '../../models/client_profile_model.dart';
import '../../models/membership_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/gym_provider.dart';
import 'add_membership_screen.dart';

/// All memberships list with status filtering.
class MembershipsScreen extends ConsumerStatefulWidget {
  const MembershipsScreen({super.key});

  @override
  ConsumerState<MembershipsScreen> createState() => _MembershipsScreenState();
}

class _MembershipsScreenState extends ConsumerState<MembershipsScreen> {
  String _filter = 'all'; // all, active, expired, expiring

  @override
  Widget build(BuildContext context) {
    final gym = ref.watch(selectedGymProvider);

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          floating: true,
          backgroundColor: AppColors.bgDark,
          toolbarHeight: 72,
          title: Text(
            'Memberships',
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
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
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),

        // Filter chips
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          sliver: SliverToBoxAdapter(
            child: _buildFilterChips(),
          ),
        ),

        // Membership list
        if (gym != null)
          _buildMembershipList(gym.id)
        else
          SliverFillRemaining(
            child: Center(
              child: Text(
                'No gym selected',
                style: GoogleFonts.inter(color: AppColors.textMuted),
              ),
            ),
          ),

        const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
      ],
    );
  }

  Widget _buildFilterChips() {
    final filters = {
      'all': 'All',
      'active': 'Active',
      'expiring': 'Expiring Soon',
      'expired': 'Expired',
    };

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.entries.map((entry) {
          final isSelected = _filter == entry.key;
          final color = _filterColor(entry.key);
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: isSelected,
              label: Text(entry.value),
              labelStyle: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? color : AppColors.textSecondary,
              ),
              backgroundColor: AppColors.bgCard,
              selectedColor: color.withValues(alpha: 0.15),
              side: BorderSide(
                color: isSelected ? color : AppColors.border,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              showCheckmark: false,
              onSelected: (_) => setState(() => _filter = entry.key),
            ),
          );
        }).toList(),
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Color _filterColor(String filter) {
    switch (filter) {
      case 'active':
        return AppColors.success;
      case 'expiring':
        return AppColors.warning;
      case 'expired':
        return AppColors.error;
      default:
        return AppColors.primary;
    }
  }

  Widget _buildMembershipList(String gymId) {
    return FutureBuilder<List<Membership>>(
      future: ref.read(databaseServiceProvider).getMembershipsForGym(gymId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverFillRemaining(
            child: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        final allMemberships = snapshot.data ?? [];
        final filtered = _applyFilter(allMemberships);

        // Count summary
        final activeCount = allMemberships
            .where((m) => !m.isExpired && m.status.value == 'active')
            .length;
        final expiringCount =
            allMemberships.where((m) => m.expiresWithin(7)).length;

        return SliverMainAxisGroup(
          slivers: [
            // Count chips
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: _buildCountChips(
                  allMemberships.length,
                  activeCount,
                  expiringCount,
                ).animate().fadeIn(duration: 300.ms),
              ),
            ),

            if (filtered.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.card_membership_outlined,
                          size: 56,
                          color: AppColors.textMuted.withValues(alpha: 0.4)),
                      const SizedBox(height: 16),
                      Text(
                        'No memberships found',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add a membership from a client\'s profile',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.textMuted,
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
                    (context, index) => _MembershipCard(
                      membership: filtered[index],
                      delay: index * 50,
                    ),
                    childCount: filtered.length,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildCountChips(int total, int active, int expiring) {
    return Row(
      children: [
        _CountChip(label: 'Total', count: total, color: AppColors.primary),
        const SizedBox(width: 10),
        _CountChip(label: 'Active', count: active, color: AppColors.success),
        const SizedBox(width: 10),
        _CountChip(
            label: 'Expiring', count: expiring, color: AppColors.warning),
      ],
    );
  }

  List<Membership> _applyFilter(List<Membership> memberships) {
    switch (_filter) {
      case 'active':
        return memberships
            .where((m) => m.status.value == 'active' && !m.isExpired)
            .toList();
      case 'expired':
        return memberships
            .where((m) => m.isExpired || m.status.value == 'expired')
            .toList();
      case 'expiring':
        return memberships.where((m) => m.expiresWithin(7)).toList();
      default:
        return memberships;
    }
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

/// Count chip widget.
class _CountChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _CountChip(
      {required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
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
              color: color.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}

/// Membership card with status indicator and progress bar.
class _MembershipCard extends StatelessWidget {
  final Membership membership;
  final int delay;

  const _MembershipCard({required this.membership, required this.delay});

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();
    final progress = _getProgress();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Status dot
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: statusColor,
                  boxShadow: [
                    BoxShadow(
                      color: statusColor.withValues(alpha: 0.4),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      membership.planName,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${membership.startDate.shortFormatted} → ${membership.endDate.shortFormatted}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),

              // Amount & status
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (membership.amount != null)
                    Text(
                      membership.amount!.inr,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
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

          // Progress bar
          if (!membership.isExpired && progress != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 5,
                backgroundColor: AppColors.bgElevated,
                valueColor: AlwaysStoppedAnimation<Color>(
                  progress < 0.3 ? AppColors.warning : AppColors.success,
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
                color: AppColors.textMuted,
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

  Color _getStatusColor() {
    if (membership.isExpired) return AppColors.error;
    if (membership.expiresWithin(7)) return AppColors.warning;
    return AppColors.success;
  }

  String _getStatusLabel() {
    if (membership.isExpired) return 'Expired';
    if (membership.expiresWithin(3)) return 'Expiring!';
    if (membership.expiresWithin(7)) return '${membership.daysRemaining}d left';
    return 'Active';
  }
}

/// Client picker sheet for selecting a client to add membership.
class _ClientPickerSheet extends ConsumerWidget {
  final String gymId;
  final ValueChanged<ClientProfile> onClientSelected;

  const _ClientPickerSheet({
    required this.gymId,
    required this.onClientSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: const BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: AppColors.glassBorder, width: 1),
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
                color: AppColors.textMuted.withValues(alpha: 0.3),
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
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const Divider(color: AppColors.divider, height: 1),
          Expanded(
            child: FutureBuilder<List<ClientProfile>>(
              future: ref.read(databaseServiceProvider).getClientsForGym(gymId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }
                final clients = snapshot.data ?? [];
                if (clients.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'No clients found. Add a client first.',
                        style: GoogleFonts.inter(color: AppColors.textMuted),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  itemCount: clients.length,
                  itemBuilder: (context, index) {
                    final client = clients[index];
                    final initial = (client.fullName?.isNotEmpty == true)
                        ? client.fullName![0].toUpperCase()
                        : '?';
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            AppColors.primary.withValues(alpha: 0.15),
                        child: Text(
                          initial,
                          style: GoogleFonts.inter(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      title: Text(
                        client.fullName ?? 'Unnamed',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      subtitle: client.email != null
                          ? Text(
                              client.email!,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.textMuted,
                              ),
                            )
                          : null,
                      trailing: const Icon(Icons.chevron_right_rounded,
                          color: AppColors.textMuted),
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
