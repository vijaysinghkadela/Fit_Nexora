import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/extensions.dart';
import '../../config/theme.dart';
import '../../widgets/glassmorphic_card.dart';

/// Master tier profile screen.
class MasterProfileScreen extends ConsumerWidget {
  const MasterProfileScreen({super.key});

  static const routePath = '/master/profile';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.fitTheme;

    return Scaffold(
      backgroundColor: t.background,
      body: Stack(
        children: [
          // Radial glow orbs background
          Positioned(
            top: -80,
            right: -60,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    t.brand.withOpacity(0.22),
                    t.brand.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 160,
            left: -80,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    t.accent.withOpacity(0.12),
                    t.accent.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),
          // Main scrollable content
          CustomScrollView(
            slivers: [
              // AppBar
              SliverAppBar(
                pinned: true,
                backgroundColor: t.background.withOpacity(0.96),
                leading: IconButton(
                  icon: Icon(Icons.arrow_back_rounded, color: t.textPrimary),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                title: Text(
                  'Master Profile',
                  style: GoogleFonts.inter(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: t.textPrimary,
                  ),
                ),
                actions: [
                  IconButton(
                    icon: Icon(Icons.settings_outlined, color: t.textPrimary),
                    onPressed: () {},
                  ),
                  const SizedBox(width: 8),
                ],
              ),

              // Header: avatar + name + badge
              SliverToBoxAdapter(
                child: _ProfileHeader(t: t)
                    .animate()
                    .fadeIn(duration: 400.ms)
                    .slideY(begin: 0.1),
              ),

              // Membership card
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: _MembershipCard(t: t)
                      .animate(delay: 80.ms)
                      .fadeIn(duration: 400.ms)
                      .slideY(begin: 0.1),
                ),
              ),

              // Achievement stats
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: _AchievementStats(t: t)
                      .animate(delay: 140.ms)
                      .fadeIn(duration: 400.ms)
                      .slideY(begin: 0.1),
                ),
              ),

              // Master features grid
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MASTER FEATURES',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: t.textMuted,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _MasterFeaturesGrid(t: t),
                    ],
                  )
                      .animate(delay: 200.ms)
                      .fadeIn(duration: 400.ms)
                      .slideY(begin: 0.1),
                ),
              ),

              // Account settings
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ACCOUNT SETTINGS',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: t.textMuted,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _AccountSettingsList(t: t),
                    ],
                  )
                      .animate(delay: 260.ms)
                      .fadeIn(duration: 400.ms)
                      .slideY(begin: 0.1),
                ),
              ),

              const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Profile header
// ---------------------------------------------------------------------------

class _ProfileHeader extends StatelessWidget {
  final FitNexoraThemeTokens t;
  const _ProfileHeader({required this.t});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        children: [
          // Avatar with glow border
          Stack(
            alignment: Alignment.bottomCenter,
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: t.brandGradient,
                  boxShadow: [
                    BoxShadow(
                      color: t.brand.withOpacity(0.55),
                      blurRadius: 24,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    'AJ',
                    style: GoogleFonts.inter(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: -10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFFFD700),
                        Color(0xFFFFA500),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFD700).withOpacity(0.4),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Text(
                    'Master',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Text(
            'Alex Johnson',
            style: GoogleFonts.inter(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: t.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _TagBadge(label: '#12 Global', color: t.accent, t: t),
              const SizedBox(width: 8),
              _TagBadge(label: 'Master Tier', color: t.brand, t: t),
            ],
          ),
        ],
      ),
    );
  }
}

class _TagBadge extends StatelessWidget {
  final String label;
  final Color color;
  final FitNexoraThemeTokens t;
  const _TagBadge({required this.label, required this.color, required this.t});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.13),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Membership card
// ---------------------------------------------------------------------------

class _MembershipCard extends StatelessWidget {
  final FitNexoraThemeTokens t;
  const _MembershipCard({required this.t});

  @override
  Widget build(BuildContext context) {
    const totalDays = 365;
    const daysUsed = 287;
    const daysLeft = totalDays - daysUsed;
    final progress = daysUsed / totalDays;

    return GlassmorphicCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: t.brand.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'MEMBERSHIP',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: t.brand,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  'Active',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: t.accent,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: t.accent,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Renews on',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: t.textMuted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Mar 15, 2027',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: t.textPrimary,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Days remaining',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: t.textMuted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$daysLeft days',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: t.accent,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: t.ringTrack,
                valueColor: AlwaysStoppedAnimation<Color>(t.brand),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '$daysUsed of $totalDays days used',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: t.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Achievement stats
// ---------------------------------------------------------------------------

class _AchievementStats extends StatelessWidget {
  final FitNexoraThemeTokens t;
  const _AchievementStats({required this.t});

  @override
  Widget build(BuildContext context) {
    final stats = [
      _StatData(value: '248', label: 'Workouts', icon: Icons.fitness_center_rounded, color: t.brand),
      _StatData(value: '67', label: 'Day Streak', icon: Icons.local_fire_department_rounded, color: t.accent),
      const _StatData(value: '12', label: 'Wins', icon: Icons.emoji_events_rounded, color: Color(0xFFFFD700)),
    ];

    return Row(
      children: stats.asMap().entries.map((entry) {
        final i = entry.key;
        final s = entry.value;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              left: i == 0 ? 0 : 6,
              right: i == stats.length - 1 ? 0 : 6,
            ),
            child: GlassmorphicCard(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
                child: Column(
                  children: [
                    Icon(s.icon, color: s.color, size: 22),
                    const SizedBox(height: 8),
                    Text(
                      s.value,
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: t.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      s.label,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: t.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _StatData {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  const _StatData({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });
}

// ---------------------------------------------------------------------------
// Master features 2x2 grid
// ---------------------------------------------------------------------------

class _MasterFeaturesGrid extends StatelessWidget {
  final FitNexoraThemeTokens t;
  const _MasterFeaturesGrid({required this.t});

  @override
  Widget build(BuildContext context) {
    final features = [
      _FeatureData(
        icon: Icons.smart_toy_outlined,
        label: 'AI Coach',
        subtitle: 'Personalised plans',
        color: t.brand,
      ),
      _FeatureData(
        icon: Icons.bar_chart_rounded,
        label: 'Analytics',
        subtitle: 'Deep insights',
        color: t.info,
      ),
      _FeatureData(
        icon: Icons.videocam_outlined,
        label: 'Live Sessions',
        subtitle: 'Group & 1:1',
        color: t.warning,
      ),
      _FeatureData(
        icon: Icons.emoji_events_outlined,
        label: 'Challenges',
        subtitle: 'Compete & win',
        color: t.accent,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: features.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.55,
      ),
      itemBuilder: (context, i) {
        final f = features[i];
        return GlassmorphicCard(
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: f.color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(f.icon, color: f.color, size: 18),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      f.label,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: t.textPrimary,
                      ),
                    ),
                    Text(
                      f.subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: t.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _FeatureData {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  const _FeatureData({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
  });
}

// ---------------------------------------------------------------------------
// Account settings list
// ---------------------------------------------------------------------------

class _AccountSettingsList extends StatelessWidget {
  final FitNexoraThemeTokens t;
  const _AccountSettingsList({required this.t});

  @override
  Widget build(BuildContext context) {
    final items = [
      _SettingItem(icon: Icons.person_outline_rounded, label: 'Profile', color: t.brand),
      _SettingItem(icon: Icons.notifications_outlined, label: 'Notifications', color: t.info),
      _SettingItem(icon: Icons.lock_outlined, label: 'Privacy', color: t.warning),
      _SettingItem(icon: Icons.credit_card_outlined, label: 'Billing', color: t.accent),
    ];

    return GlassmorphicCard(
      child: Column(
        children: items.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          return Column(
            children: [
              InkWell(
                onTap: () {},
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: item.color.withOpacity(0.13),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(item.icon, color: item.color, size: 18),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          item.label,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: t.textPrimary,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: t.textMuted,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
              if (i < items.length - 1)
                Divider(
                  height: 1,
                  thickness: 1,
                  indent: 16,
                  endIndent: 16,
                  color: t.divider,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _SettingItem {
  final IconData icon;
  final String label;
  final Color color;
  const _SettingItem({
    required this.icon,
    required this.label,
    required this.color,
  });
}
