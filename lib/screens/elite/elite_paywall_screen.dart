import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants.dart';
import '../../providers/gym_provider.dart';

/// Elite Paywall — shown to Basic/Pro members trying to access Elite.
class ElitePaywallScreen extends ConsumerWidget {
  const ElitePaywallScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gym = ref.watch(selectedGymProvider);

    final features = [
      (Icons.psychology_rounded, 'Advanced AI Personal Trainer',
          'Claude Opus AI gives you a full personal trainer experience with deep fitness analysis'),
      (Icons.auto_awesome_rounded, 'Personalized Workout Optimization',
          'AI continuously optimizes your plan based on performance and recovery'),
      (Icons.restaurant_menu_rounded, 'Personalized Diet Planning',
          'Custom meal plans generated to your macros, preferences, and goals'),
      (Icons.medication_rounded, 'Supplement Tracker',
          'Log creatine, protein, vitamins — get AI-suggested supplement timing'),
      (Icons.percent_rounded, 'Body Fat Analysis',
          'Track body fat % trends with visual graphs and AI commentary'),
      (Icons.fitness_center_rounded, 'Muscle Group Progress Tracking',
          'Visualise strength gains per muscle group over time'),
      (Icons.compare_rounded, 'Transformation Photo Comparison',
          'Side-by-side before/after progress photos stored securely'),
      (Icons.chat_rounded, 'Trainer Chat Support',
          'Direct real-time messaging with your assigned trainer'),
    ];

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: AppColors.bgDark,
            expandedHeight: 240,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF9C27B0).withValues(alpha: 0.25),
                      const Color(0xFF3F51B5).withValues(alpha: 0.15),
                      AppColors.bgDark,
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 22, vertical: 12),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [
                            Color(0xFF9C27B0),
                            Color(0xFF3F51B5),
                          ]),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF9C27B0)
                                  .withValues(alpha: 0.45),
                              blurRadius: 28,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.diamond_rounded,
                                color: Colors.white, size: 22),
                            const SizedBox(width: 8),
                            Text(
                              'ELITE PLAN',
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ).animate().scale(
                            duration: 600.ms, curve: Curves.elasticOut),
                      const SizedBox(height: 14),
                      Text(
                        '₹1499 / month',
                        style: GoogleFonts.inter(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary),
                      ).animate(delay: 200.ms).fadeIn(),
                      const SizedBox(height: 4),
                      Text(
                        'Everything in Pro + Advanced AI + Personal Trainer',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                            fontSize: 13, color: AppColors.textSecondary),
                      ).animate(delay: 300.ms).fadeIn(),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
            sliver: SliverToBoxAdapter(
              child: Text('WHAT YOU GET WITH ELITE',
                  style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMuted,
                      letterSpacing: 1.2)),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverToBoxAdapter(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.bgCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    children: features.asMap().entries.map((entry) {
                      final i = entry.key;
                      final (icon, title, subtitle) = entry.value;
                      final isAI = title.startsWith('Advanced') ||
                          title.startsWith('Personalized');
                      return Column(
                        children: [
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                gradient: isAI
                                    ? const LinearGradient(colors: [
                                        Color(0xFF9C27B0), Color(0xFF3F51B5)])
                                    : LinearGradient(colors: [
                                        AppColors.primary,
                                        AppColors.accent
                                      ]),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(icon, color: Colors.white, size: 18),
                            ),
                            title: Text(title,
                                style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: AppColors.textPrimary)),
                            subtitle: Text(subtitle,
                                style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                    height: 1.4)),
                          ),
                          if (i < features.length - 1)
                            const Divider(color: AppColors.divider, height: 1),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.04),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
            sliver: SliverToBoxAdapter(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    const Color(0xFF9C27B0).withValues(alpha: 0.1),
                    const Color(0xFF3F51B5).withValues(alpha: 0.06),
                  ]),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: const Color(0xFF9C27B0).withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.diamond_rounded,
                        color: Color(0xFF9C27B0), size: 32),
                    const SizedBox(height: 12),
                    Text(gym?.name ?? 'Your Gym',
                        style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary)),
                    if (gym?.phone != null) ...[
                      const SizedBox(height: 6),
                      Text('📞 ${gym!.phone}',
                          style: GoogleFonts.inter(
                              fontSize: 14,
                              color: AppColors.textSecondary)),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      'Upgrade to Elite at your gym to unlock the full AI experience',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                          fontSize: 13, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ).animate(delay: 400.ms).fadeIn(),
            ),
          ),
        ],
      ),
    );
  }
}
