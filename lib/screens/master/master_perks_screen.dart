import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/extensions.dart';
import '../../config/theme.dart';
import '../../widgets/glassmorphic_card.dart';

/// Master tier perks detail screen — showcases all premium benefits.
class MasterPerksScreen extends ConsumerWidget {
  const MasterPerksScreen({super.key});

  static const routePath = '/master/perks';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.fitTheme;

    return Scaffold(
      backgroundColor: t.background,
      appBar: AppBar(
        backgroundColor: t.background,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: t.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Master Tier Perks',
          style: GoogleFonts.inter(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: t.textPrimary,
          ),
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                // Hero section with gold gradient badge
                SliverToBoxAdapter(
                  child: _HeroSection(t: t)
                      .animate()
                      .fadeIn(duration: 400.ms)
                      .slideY(begin: 0.08),
                ),

                // Section header
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
                  sliver: SliverToBoxAdapter(
                    child: Text(
                      'YOUR EXCLUSIVE BENEFITS',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: t.textMuted,
                        letterSpacing: 1.2,
                      ),
                    ).animate(delay: 80.ms).fadeIn(duration: 400.ms),
                  ),
                ),

                // Perks list
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final perk = _perks(t)[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _PerkCard(perk: perk, t: t)
                              .animate(delay: (100 + index * 60).ms)
                              .fadeIn(duration: 400.ms)
                              .slideX(begin: -0.05),
                        );
                      },
                      childCount: _perks(t).length,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // CTA button
          _CtaButton(t: t)
              .animate(delay: 500.ms)
              .fadeIn(duration: 400.ms)
              .slideY(begin: 0.15),
        ],
      ),
    );
  }

  List<_PerkData> _perks(FitNexoraThemeTokens t) => [
        _PerkData(
          icon: Icons.headset_mic_rounded,
          title: 'Priority Support',
          description: 'Skip the queue with dedicated 24/7 support from Master specialists.',
          color: t.brand,
        ),
        _PerkData(
          icon: Icons.psychology_alt_outlined,
          title: 'Exclusive AI Coach',
          description: 'Your personal AI coach trained on elite-level biomechanics data.',
          color: t.accent,
        ),
        _PerkData(
          icon: Icons.bar_chart_rounded,
          title: 'Advanced Analytics',
          description: 'Deep performance insights including CNS readiness and force curves.',
          color: t.info,
        ),
        _PerkData(
          icon: Icons.video_call_rounded,
          title: 'Live Group Sessions',
          description: 'Join unlimited live training sessions led by world-class coaches.',
          color: t.warning,
        ),
        _PerkData(
          icon: Icons.person_rounded,
          title: 'Monthly 1:1 Consultation',
          description: 'One dedicated monthly session with a certified performance coach.',
          color: t.accent,
        ),
        _PerkData(
          icon: Icons.group_rounded,
          title: 'Exclusive Community Access',
          description: 'Private Master-tier community with elite athletes and experts.',
          color: t.brand,
        ),
      ];
}

// ---------------------------------------------------------------------------
// Hero section
// ---------------------------------------------------------------------------

class _HeroSection extends StatelessWidget {
  final FitNexoraThemeTokens t;
  const _HeroSection({required this.t});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            t.brand.withOpacity(0.22),
            t.info.withOpacity(0.10),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: t.brand.withOpacity(0.30)),
      ),
      child: Column(
        children: [
          // Gold "MASTER" badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(999),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFD700).withOpacity(0.45),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Text(
              'MASTER',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 3.0,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'The Pinnacle of\nFitness Performance',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: t.textPrimary,
              letterSpacing: -0.6,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Unlock every tool, every insight, and every advantage\navailable in FitNexora.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: t.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _HeroStat(value: '6', label: 'Features', color: t.brand, t: t),
              const SizedBox(width: 24),
              _HeroStat(value: '∞', label: 'AI Queries', color: t.accent, t: t),
              const SizedBox(width: 24),
              _HeroStat(value: '24/7', label: 'Support', color: t.info, t: t),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  final FitNexoraThemeTokens t;
  const _HeroStat({
    required this.value,
    required this.label,
    required this.color,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            color: t.textMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Perk card
// ---------------------------------------------------------------------------

class _PerkData {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  const _PerkData({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });
}

class _PerkCard extends StatelessWidget {
  final _PerkData perk;
  final FitNexoraThemeTokens t;
  const _PerkCard({required this.perk, required this.t});

  @override
  Widget build(BuildContext context) {
    return GlassmorphicCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: perk.color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(perk.icon, color: perk.color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    perk.title,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: t.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    perk.description,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: t.textSecondary,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.check_circle_rounded, color: perk.color, size: 20),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// CTA button
// ---------------------------------------------------------------------------

class _CtaButton extends StatelessWidget {
  final FitNexoraThemeTokens t;
  const _CtaButton({required this.t});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      color: t.background,
      child: Container(
        decoration: BoxDecoration(
          gradient: t.brandGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: t.brand.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {},
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'Renew Master Membership',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
