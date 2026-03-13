import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../widgets/glassmorphic_card.dart';

/// Trainer-facing dashboard — assigned clients, workload, performance.
class TrainerDashboardScreen extends ConsumerWidget {
  const TrainerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          floating: true,
          backgroundColor: AppColors.bgDark,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Trainer Dashboard',
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                'Manage your clients',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),

        // ─── Stats Row ─────────────────────────────────────────
        SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: SliverToBoxAdapter(
            child: Row(
              children: [
                _StatTile(
                  icon: Icons.people_rounded,
                  label: 'Assigned',
                  value: '0',
                  color: AppColors.primary,
                  delay: 0,
                ),
                const SizedBox(width: 12),
                _StatTile(
                  icon: Icons.fitness_center_rounded,
                  label: 'Active Plans',
                  value: '0',
                  color: AppColors.accent,
                  delay: 80,
                ),
                const SizedBox(width: 12),
                _StatTile(
                  icon: Icons.trending_up_rounded,
                  label: 'Check-ins',
                  value: '0',
                  color: AppColors.info,
                  delay: 160,
                ),
                const SizedBox(width: 12),
                _StatTile(
                  icon: Icons.star_rounded,
                  label: 'Score',
                  value: '—',
                  color: AppColors.warning,
                  delay: 240,
                ),
              ],
            ),
          ),
        ),

        // ─── Workload Indicator ─────────────────────────────────
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverToBoxAdapter(
            child: _buildWorkloadCard(),
          ),
        ),

        // ─── Today's Schedule ───────────────────────────────────
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          sliver: SliverToBoxAdapter(
            child: Text(
              'Today\'s Schedule',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ).animate(delay: 300.ms).fadeIn(),
          ),
        ),

        // Empty schedule
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverToBoxAdapter(
            child: GlassmorphicCard(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(Icons.event_available_rounded,
                        size: 40,
                        color: AppColors.textMuted.withValues(alpha: 0.4)),
                    const SizedBox(height: 12),
                    Text(
                      'No sessions scheduled today',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ).animate(delay: 350.ms).fadeIn(),
          ),
        ),

        // ─── Assigned Clients ────────────────────────────────────
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
          sliver: SliverToBoxAdapter(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'My Clients',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text('View All'),
                ),
              ],
            ),
          ),
        ),

        // Empty clients
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverToBoxAdapter(
            child: GlassmorphicCard(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(Icons.person_search_rounded,
                        size: 40,
                        color: AppColors.textMuted.withValues(alpha: 0.4)),
                    const SizedBox(height: 12),
                    Text(
                      'No clients assigned yet',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ask your gym owner to assign clients to you',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ).animate(delay: 400.ms).fadeIn(),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 40)),
      ],
    );
  }

  Widget _buildWorkloadCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.08),
            AppColors.accent.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.speed_rounded,
                  color: AppColors.accent, size: 18),
              const SizedBox(width: 8),
              Text(
                'Workload Monitor',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'LOW',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppColors.success,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: 0.0,
              backgroundColor: AppColors.bgElevated,
              valueColor: const AlwaysStoppedAnimation(AppColors.accent),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '0 / 30 client capacity',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    ).animate(delay: 250.ms).fadeIn();
  }
}

/// Compact stat tile for trainer dashboard.
class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final int delay;

  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 10),
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ).animate(delay: Duration(milliseconds: delay)).fadeIn().slideY(
            begin: 0.1,
            end: 0,
          ),
    );
  }
}
