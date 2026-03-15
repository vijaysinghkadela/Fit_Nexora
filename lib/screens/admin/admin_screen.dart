import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../core/enums.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/glassmorphic_card.dart';

/// Super Admin dashboard — only accessible to users with role = superAdmin.
///
/// Access is enforced at two levels:
///   1. GoRouter redirect in routes.dart blocks the /admin route for non-superAdmins.
///   2. This screen shows an access-denied UI if somehow reached without the role.
class AdminScreen extends ConsumerWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider).value;
    final isSuperAdmin = currentUser?.globalRole == UserRole.superAdmin;

    // Double-check — should never be shown to non-admins thanks to route guard.
    if (!isSuperAdmin) {
      return _AccessDeniedPage(user: currentUser);
    }

    return _AdminDashboard(user: currentUser!);
  }
}

// ─── Access Denied ────────────────────────────────────────────────────────────

class _AccessDeniedPage extends StatelessWidget {
  final AppUser? user;
  const _AccessDeniedPage({this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.bgDark,
        leading: BackButton(color: AppColors.textSecondary),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.gpp_bad_rounded,
                  size: 56, color: AppColors.error),
            ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
            const SizedBox(height: 24),
            Text(
              'Access Denied',
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This page requires Super Admin privileges.\nYour current role: ${user?.globalRole.label ?? 'Unknown'}',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Admin Dashboard ─────────────────────────────────────────────────────────

class _AdminDashboard extends ConsumerStatefulWidget {
  final AppUser user;
  const _AdminDashboard({required this.user});

  @override
  ConsumerState<_AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends ConsumerState<_AdminDashboard> {
  bool _loadingStats = true;
  Map<String, dynamic> _platformStats = {};
  List<Map<String, dynamic>> _recentUsers = [];

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _loadingStats = true);
    try {
      final supabase = ref.read(supabaseClientProvider);

      // Fetch platform-wide stats
      final gymCount = await supabase.from('gyms').select().count();
      final userCount = await supabase.from('profiles').select().count();
      final clientCount = await supabase.from('clients').select().count();
      final subCount = await supabase
          .from('subscriptions')
          .select()
          .eq('status', 'active')
          .count();

      // Fetch recent sign-ups (last 5)
      final recent = await supabase
          .from('profiles')
          .select()
          .order('created_at', ascending: false)
          .limit(5);

      if (mounted) {
        setState(() {
          _platformStats = {
            'total_gyms': gymCount.count,
            'total_users': userCount.count,
            'total_clients': clientCount.count,
            'active_subscriptions': subCount.count,
          };
          _recentUsers = List<Map<String, dynamic>>.from(recent);
          _loadingStats = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingStats = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: CustomScrollView(
        slivers: [
          // ─── App Bar ────────────────────────────────────────────────────
          SliverAppBar(
            floating: true,
            backgroundColor: AppColors.bgDark,
            leading: BackButton(color: AppColors.textSecondary),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.accent],
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'SUPER ADMIN',
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  'Admin Panel',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded,
                    color: AppColors.textSecondary),
                onPressed: _loadStats,
                tooltip: 'Refresh',
              ),
              const SizedBox(width: 8),
            ],
          ),

          // ─── Admin Identity Card ─────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            sliver: SliverToBoxAdapter(
              child: _buildAdminCard(),
            ),
          ),

          // ─── Platform Stats ──────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            sliver: SliverToBoxAdapter(
              child: Text(
                'PLATFORM OVERVIEW',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            sliver: SliverToBoxAdapter(
              child: _loadingStats
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(
                            color: AppColors.primary),
                      ),
                    )
                  : _buildStatsGrid(),
            ),
          ),

          // ─── Recent Users ────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
            sliver: SliverToBoxAdapter(
              child: Text(
                'RECENT SIGN-UPS',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),

          _loadingStats
              ? const SliverToBoxAdapter(child: SizedBox.shrink())
              : SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverToBoxAdapter(
                    child: _buildRecentUsers(),
                  ),
                ),

          // ─── Danger Zone ──────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
            sliver: SliverToBoxAdapter(
              child: Text(
                'ADMIN ACTIONS',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
            sliver: SliverToBoxAdapter(
              child: _buildAdminActions(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminCard() {
    return GlassmorphicCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.accent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  widget.user.fullName.isNotEmpty
                      ? widget.user.fullName[0].toUpperCase()
                      : 'A',
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.user.fullName,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.user.email,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.accent]),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Super Admin',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0);
  }

  Widget _buildStatsGrid() {
    final items = [
      _StatItem(
        label: 'Total Gyms',
        value: '${_platformStats['total_gyms'] ?? 0}',
        icon: Icons.store_rounded,
        color: AppColors.primary,
      ),
      _StatItem(
        label: 'Registered Users',
        value: '${_platformStats['total_users'] ?? 0}',
        icon: Icons.people_rounded,
        color: AppColors.accent,
      ),
      _StatItem(
        label: 'Total Clients',
        value: '${_platformStats['total_clients'] ?? 0}',
        icon: Icons.fitness_center_rounded,
        color: AppColors.info,
      ),
      _StatItem(
        label: 'Active Subscriptions',
        value: '${_platformStats['active_subscriptions'] ?? 0}',
        icon: Icons.workspace_premium_rounded,
        color: AppColors.warning,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;
        final itemWidth =
            (constraints.maxWidth - 16 * (crossAxisCount - 1)) / crossAxisCount;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: items.asMap().entries.map((entry) {
            final i = entry.key;
            final item = entry.value;
            return SizedBox(
              width: itemWidth,
              child: _buildStatCard(item, delay: i * 80),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildStatCard(_StatItem item, {int delay = 0}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: item.color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(item.icon, color: item.color, size: 20),
          ),
          const SizedBox(height: 14),
          Text(
            item.value,
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            item.label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    )
        .animate(delay: Duration(milliseconds: delay))
        .fadeIn(duration: 350.ms)
        .slideY(begin: 0.05, end: 0);
  }

  Widget _buildRecentUsers() {
    if (_recentUsers.isEmpty) {
      return GlassmorphicCard(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: Text(
              'No users yet',
              style: GoogleFonts.inter(color: AppColors.textMuted),
            ),
          ),
        ),
      );
    }

    return GlassmorphicCard(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: _recentUsers.asMap().entries.map((entry) {
            final i = entry.key;
            final user = entry.value;
            final name = user['full_name'] as String? ?? 'Unknown';
            final email = user['email'] as String? ?? '';
            final role = user['global_role'] as String? ?? 'client';
            final createdAt = user['created_at'] as String?;
            final date = createdAt != null
                ? DateTime.tryParse(createdAt)?.toLocal()
                : null;

            return Column(
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 4),
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  title: Text(
                    name,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Text(
                    email,
                    style: GoogleFonts.inter(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _RoleBadge(role: role),
                      if (date != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          '${date.day}/${date.month}/${date.year}',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ).animate(delay: (i * 60).ms).fadeIn().slideX(begin: 0.05),
                if (i < _recentUsers.length - 1)
                  const Divider(color: AppColors.divider, height: 1),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildAdminActions() {
    return GlassmorphicCard(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            _buildActionTile(
              icon: Icons.manage_accounts_rounded,
              label: 'Manage User Roles',
              subtitle: 'Promote users to gym owner, trainer, admin',
              color: AppColors.primary,
              onTap: () => _showRoleManagementInfo(context),
            ),
            const Divider(color: AppColors.divider, height: 1),
            _buildActionTile(
              icon: Icons.analytics_rounded,
              label: 'Platform Analytics',
              subtitle: 'Revenue, growth, churn — coming soon',
              color: AppColors.accent,
              onTap: null,
            ),
            const Divider(color: AppColors.divider, height: 1),
            _buildActionTile(
              icon: Icons.support_agent_rounded,
              label: 'User Impersonation',
              subtitle: 'Debug as a specific user — coming soon',
              color: AppColors.info,
              onTap: null,
            ),
          ],
        ),
      ),
    ).animate(delay: 400.ms).fadeIn();
  }

  Widget _buildActionTile({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback? onTap,
  }) {
    final isComingSoon = onTap == null;
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      splashColor: color.withValues(alpha: 0.08),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        label,
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
          color: isComingSoon ? AppColors.textMuted : AppColors.textPrimary,
          fontSize: 14,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.inter(
          color: AppColors.textMuted,
          fontSize: 12,
        ),
      ),
      trailing: isComingSoon
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.bgElevated,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Soon',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          : Icon(Icons.chevron_right_rounded,
              color: AppColors.textMuted, size: 20),
    );
  }

  void _showRoleManagementInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Manage User Roles',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          'To promote or demote a user, update the global_role column in the '
          'profiles table via your Supabase dashboard.\n\n'
          'Available roles:\n'
          '• super_admin — Full platform access\n'
          '• gym_owner — Manage their gym\n'
          '• trainer — Access assigned clients\n'
          '• client — End-user access',
          style: GoogleFonts.inter(
            color: AppColors.textSecondary,
            fontSize: 13,
            height: 1.6,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Got it',
              style: GoogleFonts.inter(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Helper widgets & data classes ───────────────────────────────────────────

class _StatItem {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatItem(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});
}

class _RoleBadge extends StatelessWidget {
  final String role;
  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    final color = switch (role) {
      'super_admin' => AppColors.primary,
      'gym_owner' => AppColors.accent,
      'trainer' => AppColors.info,
      _ => AppColors.textMuted,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        role.replaceAll('_', ' '),
        style: GoogleFonts.inter(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
