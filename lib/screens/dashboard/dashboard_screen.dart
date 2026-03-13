import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../core/extensions.dart';
import '../../providers/auth_provider.dart';
import '../../providers/gym_provider.dart';
import '../../widgets/ai_usage_meter.dart';
import '../../widgets/glassmorphic_card.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/sidebar_nav.dart';
import '../../widgets/subscription_banner.dart';
import '../clients/clients_screen.dart';
import '../memberships/memberships_screen.dart';
import '../subscription/pricing_screen.dart';
import '../workouts/workouts_screen.dart';
import '../diet/diet_plans_screen.dart';
import '../settings/settings_screen.dart';

/// Main dashboard screen with responsive layout.
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _selectedNavIndex = 0;

  final _navItems = const [
    _NavItem(icon: Icons.dashboard_rounded, label: 'Dashboard'),
    _NavItem(icon: Icons.people_rounded, label: 'Clients'),
    _NavItem(icon: Icons.card_membership_rounded, label: 'Memberships'),
    _NavItem(icon: Icons.fitness_center_rounded, label: 'Workouts'),
    _NavItem(icon: Icons.restaurant_menu_rounded, label: 'Diet Plans'),
    _NavItem(icon: Icons.settings_rounded, label: 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final isDesktop = context.isDesktop;
    final isTablet = context.isTablet;
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      // Mobile bottom nav
      bottomNavigationBar: (!isDesktop && !isTablet) ? _buildBottomNav() : null,
      body: Row(
        children: [
          // Desktop sidebar
          if (isDesktop || isTablet)
            SidebarNav(
              items: _navItems
                  .map((n) => SidebarItem(
                        icon: n.icon,
                        label: n.label,
                      ))
                  .toList(),
              selectedIndex: _selectedNavIndex,
              onItemTap: (i) => setState(() => _selectedNavIndex = i),
              isCollapsed: isTablet,
              userName: currentUser.value?.fullName ?? 'User',
              userEmail: currentUser.value?.email ?? '',
              onSignOut: () async {
                final router = GoRouter.of(context);
                await ref.read(currentUserProvider.notifier).signOut();
                if (mounted) router.go('/login');
              },
            ),

          // Main content
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    switch (_selectedNavIndex) {
      case 0:
        return _buildDashboardContent();
      case 1:
        return const ClientsScreen();
      case 2:
        return const MembershipsScreen();
      case 3:
        return const WorkoutsScreen();
      case 4:
        return const DietPlansScreen();
      case 5:
        return const SettingsScreen();
      default:
        return _buildDashboardContent();
    }
  }

  Widget _buildDashboardContent() {
    final gym = ref.watch(selectedGymProvider);
    final stats = ref.watch(dashboardStatsProvider);

    return CustomScrollView(
      slivers: [
        // App bar
        SliverAppBar(
          floating: true,
          backgroundColor: AppColors.bgDark,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                gym?.name ?? 'Your Gym',
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                'Dashboard Overview',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined,
                  color: AppColors.textSecondary),
              onPressed: () {},
            ),
            const SizedBox(width: 8),
          ],
        ),

        // Subscription banner
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          sliver: SliverToBoxAdapter(
            child: SubscriptionBanner(
              onUpgrade: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const PricingScreen(),
                  ),
                );
              },
            ),
          ),
        ),

        // Stats grid
        SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: SliverToBoxAdapter(
            child: _buildStatsGrid(stats),
          ),
        ),

        // Quick Actions
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverToBoxAdapter(
            child: _buildQuickActions(),
          ),
        ),

        // Expiring soon alert
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          sliver: SliverToBoxAdapter(
            child: _buildExpiringAlert(stats),
          ),
        ),

        // AI Usage meter
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          sliver: SliverToBoxAdapter(
            child: AiUsageMeter(
              usage: const {
                'has_ai_access': false,
                'has_opus_access': false,
              },
            ),
          ),
        ),

        // Revenue card
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          sliver: SliverToBoxAdapter(
            child: const RevenueCard(),
          ),
        ),

        // Recent activity
        SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: SliverToBoxAdapter(
            child: _buildRecentActivity(),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid(AsyncValue<Map<String, dynamic>> stats) {
    final statsData = stats.value ?? {};

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 800
            ? 4
            : constraints.maxWidth > 500
                ? 2
                : 2;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            SizedBox(
              width: (constraints.maxWidth - 16 * (crossAxisCount - 1)) /
                  crossAxisCount,
              child: StatCard(
                title: 'Total Clients',
                value: '${statsData['total_clients'] ?? 0}',
                icon: Icons.people_rounded,
                color: AppColors.primary,
                delay: 0,
              ),
            ),
            SizedBox(
              width: (constraints.maxWidth - 16 * (crossAxisCount - 1)) /
                  crossAxisCount,
              child: StatCard(
                title: 'Active Members',
                value: '${statsData['active_members'] ?? 0}',
                icon: Icons.check_circle_rounded,
                color: AppColors.success,
                delay: 100,
              ),
            ),
            SizedBox(
              width: (constraints.maxWidth - 16 * (crossAxisCount - 1)) /
                  crossAxisCount,
              child: StatCard(
                title: 'Expired',
                value: '${statsData['expired_members'] ?? 0}',
                icon: Icons.cancel_rounded,
                color: AppColors.error,
                delay: 200,
              ),
            ),
            SizedBox(
              width: (constraints.maxWidth - 16 * (crossAxisCount - 1)) /
                  crossAxisCount,
              child: StatCard(
                title: 'Expiring Soon',
                value: '${statsData['expiring_soon'] ?? 0}',
                icon: Icons.warning_rounded,
                color: AppColors.warning,
                delay: 300,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ).animate().fadeIn(),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 500;
            return GridView.count(
              crossAxisCount: isNarrow ? 2 : 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: isNarrow ? 1.4 : 1.6,
              children: [
                _QuickActionCard(
                  icon: Icons.person_add_rounded,
                  label: 'Add Client',
                  description: 'Register a new gym member',
                  color: AppColors.primary,
                  onTap: () => setState(() => _selectedNavIndex = 1),
                  delay: 50,
                ),
                _QuickActionCard(
                  icon: Icons.card_membership_rounded,
                  label: 'New Membership',
                  description: 'Assign a membership plan',
                  color: AppColors.accent,
                  onTap: () => setState(() => _selectedNavIndex = 2),
                  delay: 100,
                ),
                _QuickActionCard(
                  icon: Icons.auto_awesome,
                  label: 'AI Plan',
                  description: 'Generate AI workout & diet',
                  color: AppColors.warning,
                  onTap: () => setState(() => _selectedNavIndex = 3),
                  delay: 150,
                ),
                _QuickActionCard(
                  icon: Icons.workspace_premium_rounded,
                  label: 'Upgrade',
                  description: 'View plans & pricing',
                  color: AppColors.info,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const PricingScreen(),
                      ),
                    );
                  },
                  delay: 200,
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildExpiringAlert(AsyncValue<Map<String, dynamic>> stats) {
    final statsData = stats.value ?? {};
    final expiringSoon = statsData['expiring_soon'] as int? ?? 0;

    if (expiringSoon == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.warning.withValues(alpha: 0.12),
            AppColors.error.withValues(alpha: 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.warning_amber_rounded,
                color: AppColors.warning, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$expiringSoon membership${expiringSoon == 1 ? '' : 's'} expiring soon',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Review and remind clients to renew',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => setState(() => _selectedNavIndex = 2),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.warning,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            child: Text(
              'View →',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    ).animate(delay: 350.ms).fadeIn().slideY(begin: 0.05, end: 0);
  }

  Widget _buildRecentActivity() {
    return GlassmorphicCard(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Activity',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text('View all'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.bgElevated,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.history_rounded,
                      size: 36,
                      color: AppColors.textMuted.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No activity yet',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Start by adding your first client',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: () => setState(() => _selectedNavIndex = 1),
                    icon: const Icon(Icons.person_add_rounded, size: 16),
                    label: Text(
                      'Add First Client',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate(delay: 400.ms).fadeIn().slideY(begin: 0.05, end: 0);
  }

  Widget _buildBottomNav() {
    // Show 5 items: Dashboard, Clients, Memberships, Workouts, Settings
    final mobileNavItems = [
      _navItems[0], // Dashboard
      _navItems[1], // Clients
      _navItems[2], // Memberships
      _navItems[3], // Workouts
      _navItems[5], // Settings
    ];

    // Map from mobile nav indices to actual nav indices
    final mobileIndexMap = [0, 1, 2, 3, 5];
    final currentMobileIndex = mobileIndexMap.contains(_selectedNavIndex)
        ? mobileIndexMap.indexOf(_selectedNavIndex)
        : 0;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bgCard,
        border: Border(
          top: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: currentMobileIndex,
        onTap: (i) => setState(() => _selectedNavIndex = mobileIndexMap[i]),
        items: mobileNavItems.map((item) {
          return BottomNavigationBarItem(
            icon: Icon(item.icon),
            label: item.label,
          );
        }).toList(),
      ),
    );
  }
}

/// Enhanced quick action card with icon, title, and description.
class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final Color color;
  final VoidCallback onTap;
  final int delay;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.description,
    required this.color,
    required this.onTap,
    this.delay = 0,
  });

  @override
  Widget build(BuildContext context) {
    final glowColor = color.withValues(alpha: 0.15);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        highlightColor: color.withValues(alpha: 0.05),
        splashColor: color.withValues(alpha: 0.1),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.bgElevated,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Stack(
            children: [
              // ─── AMBIENT GLOW ─────────────────────────────────────
              Positioned(
                bottom: -20,
                right: -20,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [glowColor, Colors.transparent],
                      stops: const [0.1, 1.0],
                    ),
                  ),
                ),
              ),
              // ─── CONTENT ─────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.bgInput,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: color.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Icon(icon, color: color, size: 20),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          description,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: delay))
        .fadeIn(duration: 350.ms)
        .slideY(begin: 0.05, end: 0, curve: AppConstants.smoothCurve);
  }
}

/// Simple nav item data.
class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}
