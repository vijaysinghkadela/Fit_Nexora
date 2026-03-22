import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/enums.dart';
import '../core/extensions.dart';
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
    if (subscription == null) return _buildNoPlanBanner(context);

    final sub = subscription!;

    if (sub.isTrialing) return _buildTrialBanner(context, sub);
    return _buildActiveBanner(context, sub);
  }

  Widget _buildNoPlanBanner(BuildContext context) {
    final t = context.fitTheme;
    return _buildContainer(
      gradient: [
        t.brand.withOpacity(0.15),
        t.accent.withOpacity(0.08),
      ],
      borderColor: t.brand.withOpacity(0.3),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: t.brand.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.rocket_launch_rounded,
                color: t.brand, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Get Started with FitNexora',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: t.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Choose a plan to unlock all features',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: t.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          _buildUpgradeButton(context, 'View Plans'),
        ],
      ),
    );
  }

  Widget _buildTrialBanner(BuildContext context, Subscription sub) {
    final t = context.fitTheme;
    final daysLeft = sub.trialDaysRemaining;
    final isUrgent = daysLeft <= 3;

    final baseColor = isUrgent ? t.warning : t.accent;
    final secondaryColor = isUrgent ? t.danger : t.brand;

    return _buildContainer(
      gradient: [
        baseColor.withOpacity(0.12),
        secondaryColor.withOpacity(0.06),
      ],
      borderColor: baseColor.withOpacity(0.3),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: baseColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isUrgent ? Icons.timer_outlined : Icons.diamond_rounded,
              color: baseColor,
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
                    _buildPlanBadge(context, sub.planTier),
                    const SizedBox(width: 8),
                    Text(
                      'TRIAL',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: t.accent,
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
                        isUrgent ? t.warning : t.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          _buildUpgradeButton(context, 'Subscribe Now'),
        ],
      ),
    );
  }

  Widget _buildActiveBanner(BuildContext context, Subscription sub) {
    final t = context.fitTheme;
    return _buildContainer(
      gradient: [
        t.surface,
        t.surfaceAlt.withOpacity(0.5),
      ],
      borderColor: t.border,
      child: Row(
        children: [
          _buildPlanBadge(context, sub.planTier),
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
                    color: t.textPrimary,
                  ),
                ),
                Text(
                  '${sub.billingInterval.label} • ${sub.periodDaysRemaining} days remaining',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: t.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (sub.planTier != PlanTier.elite) _buildUpgradeButton(context, 'Upgrade'),
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

  Widget _buildPlanBadge(BuildContext context, PlanTier tier) {
    final t = context.fitTheme;
    final color = tier == PlanTier.elite
        ? t.brand
        : tier == PlanTier.pro
            ? t.accent
            : t.textMuted;

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

  Widget _buildUpgradeButton(BuildContext context, String label) {
    final t = context.fitTheme;
    return OutlinedButton(
      onPressed: onUpgrade,
      style: OutlinedButton.styleFrom(
        foregroundColor: t.brand,
        side: BorderSide(color: t.brand),
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
    final t = context.fitTheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            t.accent.withOpacity(0.08),
            t.brand.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: t.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.account_balance_wallet_rounded,
                  color: t.accent, size: 20),
              const SizedBox(width: 8),
              Text(
                'Revenue Overview',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: t.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMetric(
                  context,
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
                color: t.divider,
              ),
              Expanded(
                child: _buildMetric(
                  context,
                  'Active Subs',
                  '$activeSubscriptions',
                  null,
                  true,
                ),
              ),
              Container(
                width: 1,
                height: 45,
                color: t.divider,
              ),
              Expanded(
                child: _buildMetric(
                  context,
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
      BuildContext context, String label, String value, String? badge, bool isPositive) {
    final t = context.fitTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: t.textMuted,
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
                  color: t.textPrimary,
                ),
              ),
              if (badge != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: (isPositive ? t.success : t.danger)
                        .withOpacity(0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    badge,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: isPositive ? t.success : t.danger,
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
