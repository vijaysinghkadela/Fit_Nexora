import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/gym_provider.dart';
import '../../widgets/glassmorphic_card.dart';

/// Settings screen — gym profile, plan management, GST, account.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final gym = ref.watch(selectedGymProvider);

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          floating: true,
          backgroundColor: AppColors.bgDark,
          title: Text(
            'Settings',
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ),

        // ─── Account Section ──────────────────────────────────
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          sliver: SliverToBoxAdapter(
            child: _buildSectionHeader('Account'),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverToBoxAdapter(
            child: GlassmorphicCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildSettingTile(
                      icon: Icons.person_rounded,
                      title: currentUser.value?.fullName ?? 'User',
                      subtitle: currentUser.value?.email ?? '',
                      trailing: const Text('Edit',
                          style: TextStyle(color: AppColors.primary)),
                    ),
                    const Divider(color: AppColors.divider, height: 1),
                    _buildSettingTile(
                      icon: Icons.security_rounded,
                      title: 'Change Password',
                      subtitle: 'Update your login credentials',
                    ),
                    const Divider(color: AppColors.divider, height: 1),
                    _buildSettingTile(
                      icon: Icons.badge_rounded,
                      title: 'Role',
                      subtitle: currentUser.value?.globalRole.label ?? 'Client',
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          currentUser.value?.globalRole.label.toUpperCase() ??
                              'CLIENT',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ).animate(delay: 100.ms).fadeIn(),
          ),
        ),

        // ─── Gym Profile ──────────────────────────────────────
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
          sliver: SliverToBoxAdapter(
            child: _buildSectionHeader('Gym Profile'),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverToBoxAdapter(
            child: GlassmorphicCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildSettingTile(
                      icon: Icons.store_rounded,
                      title: gym?.name ?? 'Your Gym',
                      subtitle: 'Gym name, logo, location',
                      trailing: const Text('Edit',
                          style: TextStyle(color: AppColors.primary)),
                    ),
                    const Divider(color: AppColors.divider, height: 1),
                    _buildSettingTile(
                      icon: Icons.schedule_rounded,
                      title: 'Operating Hours',
                      subtitle: 'Set your gym\'s working hours',
                    ),
                    const Divider(color: AppColors.divider, height: 1),
                    _buildSettingTile(
                      icon: Icons.language_rounded,
                      title: 'Language',
                      subtitle: 'English',
                      trailing: const Icon(Icons.chevron_right_rounded,
                          color: AppColors.textMuted, size: 20),
                    ),
                  ],
                ),
              ),
            ).animate(delay: 200.ms).fadeIn(),
          ),
        ),

        // ─── Subscription & Billing ──────────────────────────
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
          sliver: SliverToBoxAdapter(
            child: _buildSectionHeader('Subscription & Billing'),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverToBoxAdapter(
            child: GlassmorphicCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildSettingTile(
                      icon: Icons.workspace_premium_rounded,
                      title: 'Current Plan',
                      subtitle: 'Manage your subscription',
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'BASIC',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: AppColors.accent,
                          ),
                        ),
                      ),
                    ),
                    const Divider(color: AppColors.divider, height: 1),
                    _buildSettingTile(
                      icon: Icons.receipt_long_rounded,
                      title: 'Invoices',
                      subtitle: 'View GST invoices & payment history',
                    ),
                    const Divider(color: AppColors.divider, height: 1),
                    _buildSettingTile(
                      icon: Icons.credit_card_rounded,
                      title: 'Payment Method',
                      subtitle: 'Stripe / Razorpay',
                    ),
                    const Divider(color: AppColors.divider, height: 1),
                    _buildSettingTile(
                      icon: Icons.description_rounded,
                      title: 'GST Settings',
                      subtitle: 'GSTIN, place of supply, HSN code',
                    ),
                  ],
                ),
              ),
            ).animate(delay: 300.ms).fadeIn(),
          ),
        ),

        // ─── AI Configuration ────────────────────────────────
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
          sliver: SliverToBoxAdapter(
            child: _buildSectionHeader('AI Configuration'),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverToBoxAdapter(
            child: GlassmorphicCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildSettingTile(
                      icon: Icons.auto_awesome,
                      title: 'AI Model',
                      subtitle: 'Claude Haiku (Pro) / Opus (Elite)',
                    ),
                    const Divider(color: AppColors.divider, height: 1),
                    _buildSettingTile(
                      icon: Icons.data_usage_rounded,
                      title: 'AI Usage',
                      subtitle: 'Token budget & overage settings',
                    ),
                    const Divider(color: AppColors.divider, height: 1),
                    _buildSettingTile(
                      icon: Icons.tune_rounded,
                      title: 'AI Preferences',
                      subtitle: 'Response language, tone, detail level',
                    ),
                  ],
                ),
              ),
            ).animate(delay: 400.ms).fadeIn(),
          ),
        ),

        // ─── Danger Zone ─────────────────────────────────────
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
          sliver: SliverToBoxAdapter(
            child: _buildSectionHeader('Danger Zone'),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverToBoxAdapter(
            child: GlassmorphicCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildSettingTile(
                      icon: Icons.logout_rounded,
                      title: 'Sign Out',
                      subtitle: 'Log out of your account',
                      titleColor: AppColors.warning,
                      onTap: () async {
                        await ref.read(currentUserProvider.notifier).signOut();
                      },
                    ),
                    const Divider(color: AppColors.divider, height: 1),
                    _buildSettingTile(
                      icon: Icons.delete_forever_rounded,
                      title: 'Delete Account',
                      subtitle: 'Permanently delete your account and all data',
                      titleColor: AppColors.error,
                    ),
                  ],
                ),
              ),
            ).animate(delay: 500.ms).fadeIn(),
          ),
        ),

        // ─── Legal & Compliance ──────────────────────────────
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
          sliver: SliverToBoxAdapter(
            child: _buildSectionHeader('Legal & Compliance'),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverToBoxAdapter(
            child: GlassmorphicCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildSettingTile(
                      icon: Icons.gavel_rounded,
                      title: 'Terms of Service',
                      subtitle: 'Read our terms of service agreement',
                      onTap: () => _launchURL('https://manglamtech.com/terms'),
                    ),
                    const Divider(color: AppColors.divider, height: 1),
                    _buildSettingTile(
                      icon: Icons.privacy_tip_rounded,
                      title: 'Privacy Policy',
                      subtitle: 'Read how we handle and protect your data',
                      onTap: () =>
                          _launchURL('https://manglamtech.com/privacy'),
                    ),
                  ],
                ),
              ),
            ).animate(delay: 550.ms).fadeIn(),
          ),
        ),

        // ─── App Info ────────────────────────────────────────
        SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: SliverToBoxAdapter(
            child: Center(
              child: Column(
                children: [
                  Text(
                    'GymOS v0.1.0',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'AI-Powered Gym Management',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.textMuted.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ).animate(delay: 600.ms).fadeIn(),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 20)),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: AppColors.textMuted,
        letterSpacing: 1,
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    Color? titleColor,
    VoidCallback? onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      splashColor: AppColors.primary.withValues(alpha: 0.1),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: titleColor != null
              ? titleColor.withValues(alpha: 0.1)
              : AppColors.bgInput,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: titleColor != null
                ? titleColor.withValues(alpha: 0.2)
                : AppColors.border.withValues(alpha: 0.5),
          ),
        ),
        child: Icon(icon, color: titleColor ?? AppColors.primary, size: 20),
      ),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: titleColor ?? AppColors.textPrimary,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          subtitle,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ),
      trailing: trailing ??
          const Icon(Icons.chevron_right_rounded,
              color: AppColors.textMuted, size: 20),
    );
  }

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }
}
