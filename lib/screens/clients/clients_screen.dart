import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../core/enums.dart';
import '../../core/extensions.dart';
import '../../models/client_profile_model.dart';
import '../../models/membership_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/gym_provider.dart';
import 'add_client_screen.dart';
import 'client_detail_screen.dart';

/// Provider for search query.
final clientSearchQueryProvider = StateProvider<String>((ref) => '');

/// Provider for sort order.
final clientSortProvider = StateProvider<String>((ref) => 'name_asc');

/// Provider for goal filter.
final clientGoalFilterProvider = StateProvider<FitnessGoal?>((ref) => null);

final filteredClientsProvider =
    FutureProvider<List<ClientProfile>>((ref) async {
  final gym = ref.watch(selectedGymProvider);
  if (gym == null) return [];

  final db = ref.read(databaseServiceProvider);
  final clients = await db.getClientsForGym(gym.id);
  final query = ref.watch(clientSearchQueryProvider).toLowerCase();
  final sort = ref.watch(clientSortProvider);
  final goalFilter = ref.watch(clientGoalFilterProvider);

  var result = clients.where((c) {
    // Goal filter
    if (goalFilter != null && c.goal != goalFilter) return false;
    // Search filter
    if (query.isEmpty) return true;
    final name = (c.fullName ?? '').toLowerCase();
    final email = (c.email ?? '').toLowerCase();
    final phone = (c.phone ?? '').toLowerCase();
    return name.contains(query) ||
        email.contains(query) ||
        phone.contains(query);
  }).toList();

  // Sort
  switch (sort) {
    case 'name_asc':
      result.sort((a, b) => (a.fullName ?? '').compareTo(b.fullName ?? ''));
      break;
    case 'name_desc':
      result.sort((a, b) => (b.fullName ?? '').compareTo(a.fullName ?? ''));
      break;
    case 'recent':
      result.sort((a, b) => b.id.compareTo(a.id));
      break;
  }

  return result;
});

/// Client list screen with search, filters, and CRUD.
class ClientsScreen extends ConsumerStatefulWidget {
  const ClientsScreen({super.key});

  @override
  ConsumerState<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends ConsumerState<ClientsScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clientsAsync = ref.watch(filteredClientsProvider);
    final goalFilter = ref.watch(clientGoalFilterProvider);

    return CustomScrollView(
      slivers: [
        // Header
        SliverAppBar(
          floating: true,
          backgroundColor: AppColors.bgDark,
          toolbarHeight: 72,
          title: Text(
            'Clients',
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          actions: [
            // Client count badge
            if (clientsAsync.hasValue)
              Container(
                margin: const EdgeInsets.only(right: 4),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${clientsAsync.value!.length} clients',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            // Sort button
            IconButton(
              icon: const Icon(Icons.sort_rounded,
                  color: AppColors.textSecondary, size: 22),
              onPressed: () => _showSortSheet(context),
              tooltip: 'Sort',
            ),
            // Add client button
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: FilledButton.icon(
                onPressed: () => _showAddClientSheet(context),
                icon: const Icon(Icons.person_add_rounded, size: 18),
                label: Text(
                  context.isMobile ? 'Add' : 'Add Client',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),

        // Search bar
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          sliver: SliverToBoxAdapter(
            child: _buildSearchBar(),
          ),
        ),

        // Goal filter chips
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          sliver: SliverToBoxAdapter(
            child: _buildGoalFilterChips(goalFilter),
          ),
        ),

        // Client list
        clientsAsync.when(
          loading: () => const SliverFillRemaining(
            child: Center(
                child: CircularProgressIndicator(color: AppColors.primary)),
          ),
          error: (error, _) => SliverFillRemaining(
            child: Center(
              child: Text(
                'Error loading clients: $error',
                style: GoogleFonts.inter(color: AppColors.error),
              ),
            ),
          ),
          data: (clients) {
            if (clients.isEmpty) {
              return SliverFillRemaining(child: _buildEmptyState());
            }

            return SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final client = clients[index];
                    return FutureBuilder<Membership?>(
                      future: ref
                          .read(databaseServiceProvider)
                          .getActiveMembership(client.id),
                      builder: (context, snapshot) {
                        return _ClientCard(
                          client: client,
                          activeMembership: snapshot.data,
                          delay: index * 50,
                          onTap: () => _navigateToDetail(client),
                        );
                      },
                    );
                  },
                  childCount: clients.length,
                ),
              ),
            );
          },
        ),

        // Bottom padding
        const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgInput,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.bgDark.withValues(alpha: 0.5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 15),
        decoration: InputDecoration(
          hintText: 'Search by name, email, or phone…',
          hintStyle:
              GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 14),
          prefixIcon: const Icon(Icons.search_rounded,
              color: AppColors.textMuted, size: 20),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded,
                      color: AppColors.textSecondary, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    ref.read(clientSearchQueryProvider.notifier).state = '';
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        onChanged: (value) {
          ref.read(clientSearchQueryProvider.notifier).state = value;
        },
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.05, end: 0);
  }

  Widget _buildGoalFilterChips(FitnessGoal? currentFilter) {
    final goals = <FitnessGoal?>[
      null, // All
      FitnessGoal.fatLoss,
      FitnessGoal.muscleGain,
      FitnessGoal.generalFitness,
      FitnessGoal.athleticPerformance,
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: goals.map((goal) {
          final isSelected = currentFilter == goal;
          final label = goal == null ? 'All Clients' : goal.label;
          final color = goal == null ? AppColors.primary : _goalColor(goal);

          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: AnimatedContainer(
              duration: 250.ms,
              curve: AppConstants.smoothCurve,
              child: FilterChip(
                selected: isSelected,
                label: Text(label),
                labelStyle: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? color : AppColors.textSecondary,
                ),
                backgroundColor: AppColors.bgElevated,
                selectedColor: color.withValues(alpha: 0.15),
                side: BorderSide(
                  color: isSelected
                      ? color.withValues(alpha: 0.5)
                      : AppColors.border,
                  width: isSelected ? 1.5 : 1.0,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                showCheckmark: false,
                onSelected: (_) {
                  ref.read(clientGoalFilterProvider.notifier).state = goal;
                },
              ),
            ),
          );
        }).toList(),
      ),
    )
        .animate(delay: 100.ms)
        .fadeIn(duration: 400.ms)
        .slideX(begin: 0.05, end: 0);
  }

  Color _goalColor(FitnessGoal goal) {
    switch (goal) {
      case FitnessGoal.fatLoss:
        return AppColors.error;
      case FitnessGoal.muscleGain:
        return AppColors.primary;
      case FitnessGoal.generalFitness:
        return AppColors.success;
      case FitnessGoal.athleticPerformance:
        return AppColors.warning;
      default:
        return AppColors.info;
    }
  }

  Widget _buildEmptyState() {
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
                  AppColors.primary.withValues(alpha: 0.15),
                  AppColors.accent.withValues(alpha: 0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(Icons.people_outline_rounded,
                size: 40, color: AppColors.primary.withValues(alpha: 0.6)),
          ),
          const SizedBox(height: 24),
          Text(
            'No clients yet',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first client to get started',
            style: GoogleFonts.inter(
              fontSize: 15,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 28),
          FilledButton.icon(
            onPressed: () => _showAddClientSheet(context),
            icon: const Icon(Icons.person_add_rounded, size: 18),
            label: Text(
              'Add Client',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  void _showSortSheet(BuildContext context) {
    final currentSort = ref.read(clientSortProvider);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textMuted.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Sort Clients',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            _buildSortOption('Name A → Z', 'name_asc', currentSort),
            _buildSortOption('Name Z → A', 'name_desc', currentSort),
            _buildSortOption('Recently Added', 'recent', currentSort),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildSortOption(String label, String value, String current) {
    final isSelected = current == value;
    return ListTile(
      title: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          color: isSelected ? AppColors.primary : AppColors.textPrimary,
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check_rounded, color: AppColors.primary, size: 20)
          : null,
      contentPadding: EdgeInsets.zero,
      onTap: () {
        ref.read(clientSortProvider.notifier).state = value;
        Navigator.of(context).pop();
      },
    );
  }

  void _showAddClientSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddClientScreen(),
    );
  }

  void _navigateToDetail(ClientProfile client) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ClientDetailScreen(client: client),
      ),
    );
  }
}

/// Client list card with avatar, info, membership status dot.
class _ClientCard extends StatefulWidget {
  final ClientProfile client;
  final Membership? activeMembership;
  final int delay;
  final VoidCallback onTap;

  const _ClientCard({
    required this.client,
    required this.delay,
    required this.onTap,
    this.activeMembership,
  });

  @override
  State<_ClientCard> createState() => _ClientCardState();
}

class _ClientCardState extends State<_ClientCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
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
          child: AnimatedContainer(
            duration: 250.ms,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _isPressed
                  ? AppColors.bgElevated.withValues(alpha: 0.8)
                  : AppColors.bgCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isPressed
                    ? AppColors.primary.withValues(alpha: 0.3)
                    : AppColors.border,
              ),
              boxShadow: _isPressed
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        blurRadius: 15,
                        spreadRadius: 1,
                      )
                    ]
                  : [],
            ),
            child: Row(
              children: [
                // Avatar with membership status dot
                _buildAvatar(),
                const SizedBox(width: 16),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.client.fullName ?? 'Unnamed Client',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (widget.client.email != null) ...[
                            Icon(Icons.email_rounded,
                                size: 14, color: AppColors.textMuted),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                widget.client.email!,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Tags
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildTag(
                              widget.client.goal.label, AppColors.primary),
                          _buildTag(widget.client.trainingLevel.label,
                              AppColors.accent),
                          if (widget.client.dietType.label != 'Other')
                            _buildTag(widget.client.dietType.label,
                                AppColors.warning),
                        ],
                      ),
                    ],
                  ),
                ),

                // Arrow
                AnimatedContainer(
                  duration: 200.ms,
                  transform:
                      Matrix4.translationValues(_isPressed ? 4.0 : 0.0, 0, 0),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: _isPressed ? AppColors.primary : AppColors.textMuted,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: widget.delay))
        .fadeIn(duration: 350.ms)
        .slideX(begin: 0.04, end: 0, curve: AppConstants.smoothCurve);
  }

  Widget _buildAvatar() {
    final initial = (widget.client.fullName?.isNotEmpty == true)
        ? widget.client.fullName![0].toUpperCase()
        : '?';

    final membershipColor = _getMembershipStatusColor();

    return Stack(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary.withValues(alpha: 0.2),
                AppColors.accent.withValues(alpha: 0.1),
              ],
            ),
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.1),
            ),
          ),
          child: Center(
            child: Text(
              initial,
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
        if (membershipColor != null)
          Positioned(
            bottom: 2,
            right: 2,
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: membershipColor,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.bgCard, width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: membershipColor.withValues(alpha: 0.4),
                    blurRadius: 6,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Color? _getMembershipStatusColor() {
    if (widget.activeMembership == null) return null;
    if (widget.activeMembership!.isExpired) return AppColors.error;
    if (widget.activeMembership!.expiresWithin(7)) return AppColors.warning;
    return AppColors.success;
  }

  Widget _buildTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
        ),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
