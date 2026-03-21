import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../config/theme.dart';
import '../../config/theme_mode_provider.dart';
import '../../core/extensions.dart';
import '../../l10n/app_localizations.dart';
import '../../models/gym_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/gym_provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/performance_provider.dart';
import '../../providers/unit_provider.dart';
import '../../services/notification_service.dart';
import '../../widgets/glassmorphic_card.dart';

class MemberProfileScreen extends ConsumerWidget {
  const MemberProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final colors = context.fitTheme;
    final user = ref.watch(currentUserProvider).value;
    final gym = ref.watch(selectedGymProvider);
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
    final unitSystem = ref.watch(unitProvider);

    Future<void> signOut() async {
      await ref.read(currentUserProvider.notifier).signOut();
      if (context.mounted) {
        context.go('/login');
      }
    }

    return Scaffold(
      backgroundColor: colors.background,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colors.backgroundAlt.withOpacity(0.7),
              colors.background,
            ],
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              top: -120,
              right: -90,
              child: _SettingsGlow(
                color: colors.brand.withOpacity(0.12),
                size: 240,
              ),
            ),
            Positioned(
              bottom: -140,
              left: -120,
              child: _SettingsGlow(
                color: colors.brandSecondary.withOpacity(0.1),
                size: 300,
              ),
            ),
            SafeArea(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: Row(
                        children: [
                          _RoundIconButton(
                            icon: Icons.arrow_back_rounded,
                            onTap: () {
                              if (Navigator.of(context).canPop()) {
                                Navigator.of(context).maybePop();
                              } else {
                                context.go('/member');
                              }
                            },
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Profile',
                            style: GoogleFonts.inter(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: colors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
                    sliver: SliverToBoxAdapter(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => _showEditProfileSheet(context, ref, user),
                        child: _ProfileCard(
                          user: user,
                          gym: gym,
                          colors: colors,
                        ),
                      ),
                    ),
                  ),
                  const SliverPadding(
                    padding: EdgeInsets.fromLTRB(16, 24, 16, 0),
                    sliver: SliverToBoxAdapter(
                      child: _SectionTitle(label: 'ACCOUNT'),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                    sliver: SliverToBoxAdapter(
                      child: _SettingsGroup(
                        children: [
                          _SettingsRow(
                            icon: Icons.person_rounded,
                            title: 'Personal Info',
                            subtitle: user?.email ?? 'Not signed in',
                            onTap: () {
                              _showEditProfileSheet(context, ref, user);
                            },
                          ),
                          _SettingsRow(
                            icon: Icons.shield_rounded,
                            title: 'Security & Password',
                            subtitle: 'Update login and recovery settings',
                            onTap: () => context.push('/change-password'),
                          ),
                          _SettingsRow(
                            icon: Icons.card_membership_rounded,
                            title: 'Membership',
                            subtitle: _membershipLabel(user, gym),
                            onTap: () => context.push('/pricing'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SliverPadding(
                    padding: EdgeInsets.fromLTRB(16, 24, 16, 0),
                    sliver: SliverToBoxAdapter(
                      child: _SectionTitle(label: 'PREFERENCES'),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                    sliver: SliverToBoxAdapter(
                      child: _SettingsGroup(
                        children: [
                          _SettingsRow(
                            icon: Icons.notifications_rounded,
                            title: 'Notifications',
                            subtitle: 'Manage notification permissions',
                            onTap: () async {
                              final granted =
                                  await NotificationService.requestPermissions();
                              if (context.mounted) {
                                context.showSnackBar(
                                  granted
                                      ? 'Notifications enabled!'
                                      : 'Notification permission denied. Enable it in device settings.',
                                  isError: !granted,
                                );
                              }
                            },
                          ),
                          _SettingsRow(
                            icon: Icons.straighten_rounded,
                            title: 'Units',
                            subtitle: _unitLabel(unitSystem),
                            onTap: () => _showUnitPicker(context, ref),
                          ),
                          _SettingsRow(
                            icon: Icons.language_rounded,
                            title: t.language,
                            subtitle: _languageLabel(locale.languageCode),
                            onTap: () => _showLanguagePicker(context, ref),
                          ),
                          _SettingsRow(
                            icon: themeMode == ThemeMode.dark
                                ? Icons.dark_mode_rounded
                                : themeMode == ThemeMode.light
                                    ? Icons.light_mode_rounded
                                    : Icons.phone_android_rounded,
                            title: 'Theme',
                            subtitle: _themeLabel(themeMode),
                            onTap: () => _showThemePicker(context, ref),
                          ),
                          _PerformanceSwitch(
                            value: ref.watch(performanceProvider),
                            onChanged: (val) => ref
                                .read(performanceProvider.notifier)
                                .setLowPerformanceMode(val),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SliverPadding(
                    padding: EdgeInsets.fromLTRB(16, 24, 16, 0),
                    sliver: SliverToBoxAdapter(
                      child: _SectionTitle(label: 'SUPPORT'),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                    sliver: SliverToBoxAdapter(
                      child: _SettingsGroup(
                        children: [
                          _SettingsRow(
                            icon: Icons.help_rounded,
                            title: 'Help Center',
                            subtitle: 'Guides, FAQs, and setup support',
                            onTap: () {
                              context.showSnackBar('Support center is coming next.');
                            },
                          ),
                          _SettingsRow(
                            icon: Icons.policy_rounded,
                            title: 'Privacy Policy',
                            subtitle: 'How FitNexora handles your data',
                            onTap: () {
                              context.showSnackBar('Privacy documentation is coming next.');
                            },
                          ),
                          _SettingsRow(
                            icon: Icons.description_rounded,
                            title: 'Terms of Service',
                            subtitle: 'Platform usage and subscription terms',
                            onTap: () {
                              context.showSnackBar('Terms documentation is coming next.');
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                    sliver: SliverToBoxAdapter(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(56),
                          side: BorderSide(
                            color: colors.brand.withOpacity(0.2),
                            width: 1.4,
                          ),
                          foregroundColor: colors.brand,
                          backgroundColor: colors.surface.withOpacity(0.85),
                        ),
                        onPressed: signOut,
                        icon: const Icon(Icons.logout_rounded),
                        label: const Text('Log Out'),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 18, 16, 110),
                      child: Center(
                        child: Text(
                          'FITNEXORA V2.6.0 (MEMBER BUILD)',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.1,
                            color: colors.textMuted,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _themeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.system:
        return 'System';
    }
  }

  static String _languageLabel(String code) {
    switch (code) {
      case 'hi':
        return 'Hindi';
      case 'bn':
        return 'Bengali';
      case 'ta':
        return 'Tamil';
      case 'te':
        return 'Telugu';
      case 'mr':
        return 'Marathi';
      default:
        return 'English (US)';
    }
  }

  static String _unitLabel(UnitSystem system) {
    switch (system) {
      case UnitSystem.imperial:
        return 'Imperial (lbs, in)';
      case UnitSystem.metric:
        return 'Metric (kg, cm)';
    }
  }

  static String _membershipLabel(AppUser? user, Gym? gym) {
    if (gym != null) {
      return '${gym.planTier.label} Plan Active';
    }
    return 'Member access active';
  }

  static Future<void> _showLanguagePicker(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final currentLocale = ref.read(localeProvider);
    final colors = context.fitTheme;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: colors.surface,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final entry in const {
                'en': 'English (US)',
                'hi': 'Hindi',
                'bn': 'Bengali',
                'ta': 'Tamil',
                'te': 'Telugu',
                'mr': 'Marathi',
              }.entries)
                RadioListTile<String>(
                  value: entry.key,
                  groupValue: currentLocale.languageCode,
                  title: Text(entry.value),
                  onChanged: (value) async {
                    if (value == null) return;
                    await ref
                        .read(localeProvider.notifier)
                        .setLocale(Locale(value));
                    if (context.mounted) Navigator.of(context).pop();
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  static Future<void> _showUnitPicker(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final currentUnit = ref.read(unitProvider);
    final colors = context.fitTheme;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: colors.surface,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final option in const {
                UnitSystem.metric: 'Metric (kg, cm)',
                UnitSystem.imperial: 'Imperial (lbs, in)',
              }.entries)
                RadioListTile<UnitSystem>(
                  value: option.key,
                  groupValue: currentUnit,
                  title: Text(option.value),
                  onChanged: (value) async {
                    if (value == null) return;
                    await ref.read(unitProvider.notifier).setUnitSystem(value);
                    if (context.mounted) Navigator.of(context).pop();
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  static Future<void> _showThemePicker(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final currentMode = ref.read(themeModeProvider);
    final colors = context.fitTheme;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: colors.surface,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final option in const {
                ThemeMode.light: ('Light', Icons.light_mode_rounded),
                ThemeMode.dark: ('Dark', Icons.dark_mode_rounded),
                ThemeMode.system: ('System', Icons.phone_android_rounded),
              }.entries)
                RadioListTile<ThemeMode>(
                  value: option.key,
                  groupValue: currentMode,
                  secondary: Icon(option.value.$2),
                  title: Text(option.value.$1),
                  onChanged: (value) async {
                    if (value == null) return;
                    await ref.read(themeModeProvider.notifier).setThemeMode(value);
                    if (context.mounted) Navigator.of(context).pop();
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  static Future<void> _showEditProfileSheet(
    BuildContext context,
    WidgetRef ref,
    AppUser? user,
  ) async {
    if (user == null) {
      context.showSnackBar('Profile is still loading. Please try again.');
      return;
    }
    final colors = context.fitTheme;
    final nameCtrl = TextEditingController(text: user.fullName);
    final phoneCtrl = TextEditingController(text: user.phone ?? '');
    final formKey = GlobalKey<FormState>();

    final picker = ImagePicker();
    String? localAvatarUrl = user.avatarUrl;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: colors.surface,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 8,
                bottom: MediaQuery.viewInsetsOf(sheetCtx).bottom + 24,
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Edit Profile',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: Stack(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: colors.surfaceAlt,
                              border: Border.all(color: colors.brand, width: 2),
                            ),
                            child: ClipOval(
                              child: localAvatarUrl != null
                                  ? CachedNetworkImage(
                                      imageUrl: localAvatarUrl!,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) =>
                                          const CircularProgressIndicator(),
                                      errorWidget: (context, url, error) =>
                                          Icon(Icons.person_rounded,
                                              size: 50, color: colors.textMuted),
                                    )
                                  : Icon(Icons.person_rounded,
                                      size: 50, color: colors.textMuted),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: () async {
                                final XFile? image = await picker.pickImage(
                                  source: ImageSource.gallery,
                                  imageQuality: 70,
                                );
                                if (image != null) {
                                  try {
                                    final bytes = await image.readAsBytes();
                                    final extension =
                                        image.path.split('.').last;
                                    final fileName =
                                        'avatar_${DateTime.now().millisecondsSinceEpoch}.$extension';

                                    final publicUrl = await ref
                                        .read(storageServiceProvider)
                                        .uploadAvatar(
                                          user.id,
                                          bytes,
                                          fileName,
                                        );

                                    setSheetState(() {
                                      localAvatarUrl = publicUrl;
                                    });
                                  } catch (e) {
                                    if (sheetCtx.mounted) {
                                      ScaffoldMessenger.of(sheetCtx).showSnackBar(
                                        SnackBar(
                                            content:
                                                Text('Upload failed: $e'),
                                            backgroundColor: Colors.red),
                                      );
                                    }
                                  }
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: colors.brand,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: colors.surface, width: 2),
                                ),
                                child: const Icon(Icons.camera_alt_rounded,
                                    size: 18, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: nameCtrl,
                      style: GoogleFonts.inter(color: colors.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'Full Name',
                        labelStyle: GoogleFonts.inter(color: colors.textMuted),
                        prefixIcon:
                            Icon(Icons.person_rounded, color: colors.brand),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: colors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: colors.brand, width: 2),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: colors.danger),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: colors.danger, width: 2),
                        ),
                        filled: true,
                        fillColor: colors.surfaceMuted,
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Name is required'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      style: GoogleFonts.inter(color: colors.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'Phone Number',
                        labelStyle: GoogleFonts.inter(color: colors.textMuted),
                        prefixIcon:
                            Icon(Icons.phone_rounded, color: colors.brand),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: colors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: colors.brand, width: 2),
                        ),
                        filled: true,
                        fillColor: colors.surfaceMuted,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.brand,
                          foregroundColor: colors.textPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () async {
                          if (!formKey.currentState!.validate()) return;
                          final updated = user.copyWith(
                            fullName: nameCtrl.text.trim(),
                            phone: phoneCtrl.text.trim().isEmpty
                                ? null
                                : phoneCtrl.text.trim(),
                            avatarUrl: localAvatarUrl,
                          );
                          try {
                            await ref
                                .read(authServiceProvider)
                                .updateProfile(updated);
                            ref.read(currentUserProvider.notifier).updateUser(updated);
                            if (sheetCtx.mounted) Navigator.of(sheetCtx).pop();
                            if (context.mounted) {
                              context.showSnackBar(
                                  'Profile updated successfully');
                            }
                          } catch (e) {
                            if (context.mounted) {
                              context.showSnackBar('Update failed: $e',
                                  isError: true);
                            }
                          }
                        },
                        child: Text(
                          'Save Changes',
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700, fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    nameCtrl.dispose();
    phoneCtrl.dispose();
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.user,
    required this.gym,
    required this.colors,
  });

  final AppUser? user;
  final Gym? gym;
  final FitNexoraThemeTokens colors;

  @override
  Widget build(BuildContext context) {
    final initial = (user?.fullName.isNotEmpty ?? false)
        ? user!.fullName[0].toUpperCase()
        : 'F';

    return GlassmorphicCard(
      borderRadius: 24,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Stack(
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    gradient: colors.brandGradient,
                    shape: BoxShape.circle,
                  ),
                  child: user?.avatarUrl != null
                      ? ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: user!.avatarUrl!,
                            fit: BoxFit.cover,
                            width: 76,
                            height: 76,
                            placeholder: (context, url) =>
                                const CircularProgressIndicator(strokeWidth: 2),
                            errorWidget: (context, url, error) => Center(
                              child: Text(
                                initial,
                                style: GoogleFonts.inter(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        )
                      : Center(
                           child: Text(
                             initial,
                             style: GoogleFonts.inter(
                               fontSize: 28,
                               fontWeight: FontWeight.w800,
                               color: Colors.white,
                             ),
                           ),
                         ),
                ),
                Positioned(
                  bottom: 2,
                  right: 2,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: colors.brand,
                      shape: BoxShape.circle,
                      border: Border.all(color: colors.surface, width: 2),
                    ),
                    child: const Icon(
                      Icons.verified_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user?.fullName ?? 'FitNexora User',
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.email ?? 'Not signed in',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: colors.brand.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      gym != null
                          ? '${gym!.planTier.label} Tier'
                          : user?.globalRole.label ?? 'Member',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: colors.brand,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.fitTheme;
    return Text(
      label,
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.2,
        color: colors.textMuted,
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = context.fitTheme;
    return GlassmorphicCard(
      borderRadius: 24,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1)
              Divider(height: 1, color: colors.divider),
          ],
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.fitTheme;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      onTap: onTap,
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: colors.brand.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: colors.brand),
      ),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: colors.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.inter(
          fontSize: 12,
          color: colors.textSecondary,
        ),
      ),
      trailing: Icon(Icons.chevron_right_rounded, color: colors.textMuted),
    );
  }
}

class _PerformanceSwitch extends StatelessWidget {
  const _PerformanceSwitch({
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.fitTheme;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: colors.accent.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(Icons.speed_rounded, color: colors.accent),
      ),
      title: Text(
        'Low-End Device Mode',
        style: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: colors.textPrimary,
        ),
      ),
      subtitle: Text(
        'Disable blurs & shadows for better performance',
        style: GoogleFonts.inter(
          fontSize: 12,
          color: colors.textSecondary,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: colors.accent,
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.fitTheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: colors.surface.withOpacity(0.88),
          shape: BoxShape.circle,
          border: Border.all(color: colors.border),
        ),
        child: Icon(icon, color: colors.textPrimary),
      ),
    );
  }
}

class _SettingsGlow extends StatelessWidget {
  const _SettingsGlow({
    required this.color,
    required this.size,
  });

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, Colors.transparent],
          ),
        ),
      ),
    );
  }
}
