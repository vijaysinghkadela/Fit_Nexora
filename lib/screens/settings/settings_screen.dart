import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:go_router/go_router.dart';
import '../../core/constants.dart';
import '../../core/enums.dart';
import '../../providers/auth_provider.dart';
import '../../providers/gym_provider.dart';
import '../../providers/locale_provider.dart';
import '../../widgets/glassmorphic_card.dart';
import '../../l10n/app_localizations.dart';

/// Settings screen — gym profile, plan management, GST, account.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    final currentUser = ref.watch(currentUserProvider);
    final gym = ref.watch(selectedGymProvider);

    return SafeArea(
      child: CustomScrollView(
        slivers: [

        /// APP BAR
        SliverAppBar(
          floating: true,
          backgroundColor: AppColors.bgDark,
          title: Text(
            t.settings,
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ),

        /// ACCOUNT
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          sliver: SliverToBoxAdapter(
            child: _buildSectionHeader(t.account),
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
                      trailing: const Text(
                        'Edit',
                        style: TextStyle(color: AppColors.primary),
                      ),
                    ),

                    const Divider(color: AppColors.divider, height: 1),

                    _buildSettingTile(
                      icon: Icons.security_rounded,
                      title: t.changePassword,
                      subtitle: t.updateLoginCredentials,
                    ),

                    const Divider(color: AppColors.divider, height: 1),

                    _buildSettingTile(
                      icon: Icons.badge_rounded,
                      title: t.role,
                      subtitle: currentUser.value?.globalRole.label ?? 'Client',
                    ),
                  ],
                ),
              ),
            ).animate(delay: 100.ms).fadeIn(),
          ),
        ),

        /// GYM PROFILE
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
          sliver: SliverToBoxAdapter(
            child: _buildSectionHeader(t.gymProfile),
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
                      subtitle: t.gymNameLocation,
                      trailing: const Text(
                        'Edit',
                        style: TextStyle(color: AppColors.primary),
                      ),
                    ),

                    const Divider(color: AppColors.divider, height: 1),

                    _buildSettingTile(
                      icon: Icons.schedule_rounded,
                      title: t.operatingHours,
                      subtitle: t.setWorkingHours,
                    ),

                    const Divider(color: AppColors.divider, height: 1),

                    /// LANGUAGE
                    _buildSettingTile(
                      icon: Icons.language_rounded,
                      title: t.language,
                      subtitle: _getCurrentLanguageName(),
                      onTap: () => _showLanguagePicker(context),
                    ),
                  ],
                ),
              ),
            ).animate(delay: 200.ms).fadeIn(),
          ),
        ),

        /// BILLING
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
          sliver: SliverToBoxAdapter(
            child: _buildSectionHeader(t.subscriptionBilling),
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
                      title: t.currentPlan,
                      subtitle: t.manageSubscription,
                    ),

                    const Divider(color: AppColors.divider, height: 1),

                    _buildSettingTile(
                      icon: Icons.receipt_long_rounded,
                      title: t.invoices,
                      subtitle: t.viewInvoices,
                    ),

                    const Divider(color: AppColors.divider, height: 1),

                    _buildSettingTile(
                      icon: Icons.credit_card_rounded,
                      title: t.paymentMethod,
                      subtitle: 'Stripe / Razorpay',
                    ),

                    const Divider(color: AppColors.divider, height: 1),

                    _buildSettingTile(
                      icon: Icons.description_rounded,
                      title: t.gstSettings,
                      subtitle: t.gstDescription,
                    ),
                  ],
                ),
              ),
            ).animate(delay: 300.ms).fadeIn(),
          ),
        ),

        /// SUPER ADMIN SECTION — only visible to super_admin users
        if (currentUser.value?.globalRole == UserRole.superAdmin) ...[
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
            sliver: SliverToBoxAdapter(
              child: _buildSectionHeader('SUPER ADMIN'),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverToBoxAdapter(
              child: GlassmorphicCard(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: _buildSettingTile(
                    icon: Icons.admin_panel_settings_rounded,
                    title: 'Admin Panel',
                    subtitle: 'Platform stats, user management & controls',
                    titleColor: AppColors.primary,
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.accent],
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'ADMIN',
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    onTap: () => context.go('/admin'),
                  ),
                ),
              ).animate(delay: 150.ms).fadeIn(),
            ),
          ),
        ],

        /// SIGN OUT
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
          sliver: SliverToBoxAdapter(
            child: _buildSectionHeader(t.dangerZone),
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
                      title: t.signOut,
                      subtitle: t.logoutAccount,
                      titleColor: AppColors.warning,
                      onTap: () async {
                        await ref.read(currentUserProvider.notifier).signOut();
                      },
                    ),

                    const Divider(color: AppColors.divider, height: 1),

                    _buildSettingTile(
                      icon: Icons.delete_forever_rounded,
                      title: t.deleteAccount,
                      subtitle: t.deleteAccountWarning,
                      titleColor: AppColors.error,
                    ),
                  ],
                ),
              ),
            ).animate(delay: 500.ms).fadeIn(),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      ),
    );
  }

  /// Section Header
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

  /// Settings Tile
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
      leading: Icon(icon, color: titleColor ?? AppColors.primary),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: trailing ??
          const Icon(Icons.chevron_right_rounded,
              color: AppColors.textMuted, size: 20),
    );
  }

  /// CURRENT LANGUAGE NAME
  String _getCurrentLanguageName() {
    final locale = ref.watch(localeProvider);

    switch (locale.languageCode) {
      case 'hi':
        return 'हिन्दी';
      case 'bn':
        return 'বাংলা';
      case 'ta':
        return 'தமிழ்';
      case 'te':
        return 'తెలుగు';
      case 'mr':
        return 'मराठी';
      default:
        return 'English';
    }
  }

  /// LANGUAGE PICKER
  void _showLanguagePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Consumer(
          builder: (context, ref, _) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                ListTile(
                  title: const Text('English'),
                  onTap: () {
                    ref.read(localeProvider.notifier).setLocale(const Locale('en'));
                    Navigator.pop(context);
                  },
                ),

                ListTile(
                  title: const Text('Hindi'),
                  onTap: () {
                    ref.read(localeProvider.notifier).setLocale(const Locale('hi'));
                    Navigator.pop(context);
                  },
                ),

                ListTile(
                  title: const Text('Tamil'),
                  onTap: () {
                    ref.read(localeProvider.notifier).setLocale(const Locale('ta'));
                    Navigator.pop(context);
                  },
                ),

                ListTile(
                  title: const Text('Telugu'),
                  onTap: () {
                    ref.read(localeProvider.notifier).setLocale(const Locale('te'));
                    Navigator.pop(context);
                  },
                ),

                ListTile(
                  title: const Text('Marathi'),
                  onTap: () {
                    ref.read(localeProvider.notifier).setLocale(const Locale('mr'));
                    Navigator.pop(context);
                  },
                ),

                ListTile(
                  title: const Text('Bengali'),
                  onTap: () {
                    ref.read(localeProvider.notifier).setLocale(const Locale('bn'));
                    Navigator.pop(context);
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

}