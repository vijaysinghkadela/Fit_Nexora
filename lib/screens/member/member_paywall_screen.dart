import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../providers/gym_provider.dart';
import '../../widgets/glassmorphic_card.dart';

/// Paywall screen shown when a client has no active paid membership.
/// Explains the Basic Plan features and tells them to contact their gym.
class MemberPaywallScreen extends ConsumerWidget {
  const MemberPaywallScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gym = ref.watch(selectedGymProvider);

    final features = [
      (Icons.card_membership_rounded, 'Membership Management',
          'Digital membership card, start/expiry dates, plan name'),
      (Icons.qr_code_scanner_rounded, 'Attendance Tracking',
          'Check-in to the gym, view monthly attendance count'),
      (Icons.fitness_center_rounded, 'Trainer-Assigned Workout',
          'Day-by-day workout plan created by your trainer'),
      (Icons.restaurant_rounded, 'Trainer-Assigned Diet Plan',
          'Breakfast, lunch, snack & dinner plan based on your goals'),
      (Icons.show_chart_rounded, 'Weight Progress Tracker',
          'Log your weight and see your progress chart over time'),
      (Icons.campaign_rounded, 'Gym Announcements',
          'Timely notices, holiday closures, and events from your gym'),
    ];

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: CustomScrollView(
        slivers: [
          // Header
          SliverAppBar(
            backgroundColor: AppColors.bgDark,
            expandedHeight: 200,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary.withValues(alpha: 0.25),
                      AppColors.accent.withValues(alpha: 0.1),
                      AppColors.bgDark,
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.primary, AppColors.accent],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.4),
                              blurRadius: 24,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.lock_open_rounded,
                          size: 36,
                          color: Colors.white,
                        ),
                      ).animate().scale(
                            duration: 600.ms,
                            curve: Curves.elasticOut,
                          ),
                      const SizedBox(height: 16),
                      Text(
                        'Basic Plan — ₹499/month',
                        style: GoogleFonts.inter(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                        ),
                      ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.2),
                      const SizedBox(height: 4),
                      Text(
                        'Purchase this plan from your gym to unlock all features',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ).animate(delay: 300.ms).fadeIn(),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Features list
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
            sliver: SliverToBoxAdapter(
              child: Text(
                'WHAT YOU GET',
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
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverToBoxAdapter(
              child: GlassmorphicCard(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    children: features.asMap().entries.map((entry) {
                      final i = entry.key;
                      final (icon, title, subtitle) = entry.value;
                      return Column(
                        children: [
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(colors: [
                                  AppColors.primary,
                                  AppColors.accent
                                ]),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(icon, color: Colors.white, size: 18),
                            ),
                            title: Text(
                              title,
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            subtitle: Text(
                              subtitle,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          if (i < features.length - 1)
                            const Divider(
                                color: AppColors.divider, height: 1),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.04),
            ),
          ),

          // CTA
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
            sliver: SliverToBoxAdapter(
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withValues(alpha: 0.15),
                          AppColors.accent.withValues(alpha: 0.08),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.store_rounded,
                            color: AppColors.primary, size: 32),
                        const SizedBox(height: 12),
                        Text(
                          gym?.name ?? 'Your Gym',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (gym?.phone != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            '📞 ${gym!.phone}',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                        const SizedBox(height: 4),
                        Text(
                          'Visit or call your gym to purchase the Basic Plan',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ).animate(delay: 400.ms).fadeIn().slideY(begin: 0.04),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
