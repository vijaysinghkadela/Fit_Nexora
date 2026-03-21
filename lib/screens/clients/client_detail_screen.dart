import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../core/extensions.dart';
import '../../models/client_profile_model.dart';
import '../../models/membership_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/client_provider.dart';
import '../../widgets/error_widgets.dart';
import '../../widgets/glassmorphic_card.dart';
import '../../widgets/loading_widgets.dart';
import 'add_client_screen.dart';
import '../memberships/add_membership_screen.dart';

/// Client detail view — shows profile, metrics, and active membership.
class ClientDetailScreen extends ConsumerStatefulWidget {
  final ClientProfile client;

  const ClientDetailScreen({super.key, required this.client});

  @override
  ConsumerState<ClientDetailScreen> createState() => _ClientDetailScreenState();
}

class _ClientDetailScreenState extends ConsumerState<ClientDetailScreen> {
  late ClientProfile _client;

  @override
  void initState() {
    super.initState();
    _client = widget.client;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: CustomScrollView(
        slivers: [
          // App bar
          SliverAppBar(
            backgroundColor: AppColors.bgDark,
            pinned: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded,
                  color: AppColors.textPrimary),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              _client.fullName ?? 'Client',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_rounded,
                    color: AppColors.textSecondary),
                onPressed: _editClient,
                tooltip: 'Edit',
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded,
                    color: AppColors.textSecondary),
                color: AppColors.bgElevated,
                onSelected: _handleMenuAction,
                itemBuilder: (_) => [
                  const PopupMenuItem(
                      value: 'membership', child: Text('Add Membership')),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete Client',
                        style: TextStyle(color: AppColors.error)),
                  ),
                ],
              ),
            ],
          ),

          // Profile Card
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            sliver: SliverToBoxAdapter(child: _buildProfileCard()),
          ),

          // Body Metrics
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverToBoxAdapter(child: _buildMetricsGrid()),
          ),

          // Fitness Profile
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            sliver: SliverToBoxAdapter(child: _buildFitnessProfile()),
          ),

          // Membership Info
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            sliver: SliverToBoxAdapter(child: _buildMembershipCard()),
          ),

          // Health Notes
          if (_client.injuries != null || _client.restrictions != null)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              sliver: SliverToBoxAdapter(child: _buildHealthNotes()),
            ),

          const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
        ],
      ),
    );
  }

  Widget _buildProfileCard() {
    final initial = (_client.fullName?.isNotEmpty == true)
        ? _client.fullName![0].toUpperCase()
        : '?';

    return GlassmorphicCard(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 36,
              backgroundColor: AppColors.primary.withOpacity(0.15),
              child: Text(
                initial,
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _client.fullName ?? 'Unnamed',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (_client.email != null)
                    _buildInfoRow(Icons.email_outlined, _client.email!),
                  if (_client.phone != null)
                    _buildInfoRow(Icons.phone_outlined, _client.phone!),
                  if (_client.age != null)
                    _buildInfoRow(Icons.cake_outlined,
                        '${_client.age} years old • ${_client.sex ?? 'N/A'}'),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.textMuted),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              style: GoogleFonts.inter(
                  fontSize: 13, color: AppColors.textSecondary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid() {
    return Row(
      children: [
        Expanded(
          child: _MetricTile(
            label: 'Weight',
            value: _client.weightKg != null ? '${_client.weightKg}' : '—',
            unit: 'kg',
            icon: Icons.monitor_weight_outlined,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MetricTile(
            label: 'Height',
            value: _client.heightCm != null ? '${_client.heightCm}' : '—',
            unit: 'cm',
            icon: Icons.height_rounded,
            color: AppColors.accent,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MetricTile(
            label: 'BMI',
            value: _calculateBMI(),
            unit: '',
            icon: Icons.speed_rounded,
            color: AppColors.warning,
          ),
        ),
      ],
    ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.05, end: 0);
  }

  String _calculateBMI() {
    if (_client.weightKg == null || _client.heightCm == null) return '—';
    final heightM = _client.heightCm! / 100;
    final bmi = _client.weightKg! / (heightM * heightM);
    return bmi.toStringAsFixed(1);
  }

  Widget _buildFitnessProfile() {
    return GlassmorphicCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCardHeader('Fitness Profile', Icons.fitness_center_rounded),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _buildDetailChip('🎯 ${_client.goal.label}', AppColors.primary),
                _buildDetailChip(
                    '📊 ${_client.trainingLevel.label}', AppColors.accent),
                _buildDetailChip(
                    '📅 ${_client.daysPerWeek} days/week', AppColors.info),
                _buildDetailChip(
                    '🏋️ ${_client.equipment ?? 'Gym'}', AppColors.warning),
                _buildDetailChip(
                    '🍽️ ${_client.dietType.label}', AppColors.success),
              ],
            ),
          ],
        ),
      ),
    ).animate(delay: 300.ms).fadeIn().slideY(begin: 0.05, end: 0);
  }

  Widget _buildMembershipCard() {
    return FutureBuilder<Membership?>(
      future: ref.read(databaseServiceProvider).getActiveMembership(_client.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CardSkeleton(height: 170);
        }
        if (snapshot.hasError) {
          return GlassmorphicCard(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: ErrorStateWidget(
                message: 'Unable to load membership details.',
                onRetry: () => (context as Element).markNeedsBuild(),
              ),
            ),
          );
        }
        final membership = snapshot.data;

        return GlassmorphicCard(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildCardHeader(
                        'Membership', Icons.card_membership_rounded),
                    if (membership == null)
                      TextButton.icon(
                        onPressed: _addMembership,
                        icon: const Icon(Icons.add_rounded, size: 16),
                        label: const Text('Add'),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                if (membership != null) ...[
                  _buildMembershipRow('Plan', membership.planName),
                  _buildMembershipRow('Status', membership.status.label,
                      valueColor: membership.isExpired
                          ? AppColors.error
                          : AppColors.success),
                  _buildMembershipRow('Amount',
                      membership.amount != null ? membership.amount!.inr : '—'),
                  _buildMembershipRow('Ends', membership.endDate.mediumFormatted,
                      valueColor: membership.expiresWithin(7)
                          ? AppColors.warning
                          : null),
                  if (membership.daysRemaining >= 0)
                    _buildMembershipRow(
                        'Days Left', '${membership.daysRemaining} days'),
                ] else ...[
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Column(
                        children: [
                          Icon(Icons.card_membership_outlined,
                              size: 36,
                              color:
                                  AppColors.textMuted.withOpacity(0.4)),
                          const SizedBox(height: 8),
                          Text(
                            'No active membership',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ).animate(delay: 400.ms).fadeIn().slideY(begin: 0.05, end: 0);
      },
    );
  }

  Widget _buildMembershipRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: valueColor ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthNotes() {
    return GlassmorphicCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCardHeader('Health Notes', Icons.health_and_safety_outlined),
            const SizedBox(height: 14),
            if (_client.injuries != null)
              _buildNoteItem('Injuries / Limitations', _client.injuries!,
                  Icons.healing_rounded, AppColors.error),
            if (_client.restrictions != null)
              _buildNoteItem('Allergies / Restrictions', _client.restrictions!,
                  Icons.no_food_rounded, AppColors.warning),
          ],
        ),
      ),
    ).animate(delay: 500.ms).fadeIn().slideY(begin: 0.05, end: 0);
  }

  Widget _buildNoteItem(
      String label, String value, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  void _editClient() async {
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddClientScreen(existingClient: _client),
    );
    if (result == true) {
      // Refresh client data
      if (mounted) {
        Navigator.of(context).pop(); // Go back to list to see refreshed data
      }
    }
  }

  void _addMembership() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddMembershipScreen(client: _client),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'membership':
        _addMembership();
        break;
      case 'delete':
        _confirmDelete();
        break;
    }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete Client',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          'Are you sure you want to delete ${_client.fullName ?? 'this client'}? This action cannot be undone.',
          style: GoogleFonts.inter(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                await ref
                    .read(databaseServiceProvider)
                    .deleteClient(_client.id);
                // Invalidate providers so the client list refreshes
                ref.invalidate(gymClientsProvider);
                ref.invalidate(pagedClientsControllerProvider);
                if (mounted) Navigator.of(context).pop();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: AppColors.error),
                  );
                }
              }
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

/// Metric tile widget.
class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;

  const _MetricTile({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, size: 22, color: color),
          const SizedBox(height: 10),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (unit.isNotEmpty)
                  TextSpan(
                    text: ' $unit',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
