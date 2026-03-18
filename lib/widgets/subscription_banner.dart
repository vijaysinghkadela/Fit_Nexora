import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants.dart';
import '../core/enums.dart';
import '../models/subscription_model.dart';

/// Banner showing current plan, trial status, and upgrade CTA.
class SubscriptionBanner extends StatelessWidget {
  final Subscription? subscription;
  final VoidCallback? onUpgrade;

  const SubscriptionBanner({
    super.key,
    this.subscription,
    this.onUpgrade,
  });

  @override
  Widget build(BuildContext context) {
    if (subscription == null) return _buildNoPlanBanner();

    final sub = subscription!;

    if (sub.isTrialing) return _buildTrialBanner(sub);
    return _buildActiveBanner(sub);
  }

  Widget _buildNoPlanBanner() {
    return _buildContainer(
      gradient: [
        AppColors.primary.withOpacity(0.15),
        AppColors.accent.withOpacity(0.08),
      ],
      borderColor: AppColors.primary.withOpacity(0.3),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.rocket_launch_rounded,
                color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Get Started with GymOS',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Choose a plan to unlock all features',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          _buildUpgradeButton('View Plans'),
        ],
      ),
    );
  }

  Widget _buildTrialBanner(Subscription sub) {
    final daysLeft = sub.trialDaysRemaining;
    final isUrgent = daysLeft <= 3;

    return _buildContainer(
      gradient: [
        (isUrgent ? AppColors.warning : AppColors.accent)
            .withOpacity(0.12),
        (isUrgent ? AppColors.error : AppColors.primary)
            .withOpacity(0.06),
      ],
      borderColor: (isUrgent ? AppColors.warning : AppColors.accent)
          .withOpacity(0.3),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (isUrgent ? AppColors.warning : AppColors.accent)
                  .withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isUrgent ? Icons.timer_outlined : Icons.diamond_rounded,
              color: isUrgent ? AppColors.warning : AppColors.accent,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildPlanBadge(sub.planTier),
                    const SizedBox(width: 8),
                    Text(
                      'TRIAL',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppColors.accent,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  isUrgent
                      ? '$daysLeft day${daysLeft == 1 ? '' : 's'} left — subscribe to keep your data'
                      : '$daysLeft days remaining in your free trial',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color:
                        isUrgent ? AppColors.warning : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          _buildUpgradeButton('Subscribe Now'),
        ],
      ),
    );
  }

  Widget _buildActiveBanner(Subscription sub) {
    return _buildContainer(
      gradient: [
        AppColors.bgCard,
        AppColors.bgElevated.withOpacity(0.5),
      ],
      borderColor: AppColors.border,
      child: Row(
        children: [
          _buildPlanBadge(sub.planTier),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${sub.planTier.label} Plan',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '${sub.billingInterval.label} • ${sub.periodDaysRemaining} days remaining',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (sub.planTier != PlanTier.elite) _buildUpgradeButton('Upgrade'),
        ],
      ),
    );
  }

  Widget _buildContainer({
    required List<Color> gradient,
    required Color borderColor,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradient),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: child,
    ).animate().fadeIn(delay: 100.ms);
  }

  Widget _buildPlanBadge(PlanTier tier) {
    final color = tier == PlanTier.elite
        ? AppColors.primary
        : tier == PlanTier.pro
            ? AppColors.accent
            : AppColors.textMuted;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        tier.label.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildUpgradeButton(String label) {
    return OutlinedButton(
      onPressed: onUpgrade,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Revenue summary card for the dashboard.
class RevenueCard extends StatelessWidget {
  final double monthlyRevenue;
  final int activeSubscriptions;
  final int newThisMonth;
  final double? growthPercent;

  const RevenueCard({
    super.key,
    this.monthlyRevenue = 0,
    this.activeSubscriptions = 0,
    this.newThisMonth = 0,
    this.growthPercent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.accent.withOpacity(0.08),
            AppColors.primary.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_balance_wallet_rounded,
                  color: AppColors.accent, size: 20),
              const SizedBox(width: 8),
              Text(
                'Revenue Overview',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMetric(
                  'Monthly Revenue',
                  '₹${_formatCurrency(monthlyRevenue)}',
                  growthPercent != null
                      ? '${growthPercent! >= 0 ? '+' : ''}${growthPercent!.toStringAsFixed(1)}%'
                      : null,
                  growthPercent != null && growthPercent! >= 0,
                ),
              ),
              Container(
                width: 1,
                height: 45,
                color: AppColors.divider,
              ),
              Expanded(
                child: _buildMetric(
                  'Active Subs',
                  '$activeSubscriptions',
                  null,
                  true,
                ),
              ),
              Container(
                width: 1,
                height: 45,
                color: AppColors.divider,
              ),
              Expanded(
                child: _buildMetric(
                  'New This Month',
                  '$newThisMonth',
                  null,
                  true,
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate(delay: 350.ms).fadeIn().slideY(begin: 0.05, end: 0);
  }

  Widget _buildMetric(
      String label, String value, String? badge, bool isPositive) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              if (badge != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: (isPositive ? AppColors.success : AppColors.error)
                        .withOpacity(0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    badge,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: isPositive ? AppColors.success : AppColors.error,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double amount) {
    if (amount >= 100000) {
      return '${(amount / 100000).toStringAsFixed(1)}L';
    }
    if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    }
    return amount.toStringAsFixed(0);
  }
}
