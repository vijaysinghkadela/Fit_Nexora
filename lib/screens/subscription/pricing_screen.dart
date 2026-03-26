import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/plan_limits.dart';
import '../../core/enums.dart';
import '../../models/subscription_model.dart';
import '../../core/extensions.dart';
import '../../providers/auth_provider.dart';
import '../../providers/gym_provider.dart';
import '../../providers/payment_provider.dart';
import '../../widgets/fit_pricing.dart';

class PricingScreen extends ConsumerStatefulWidget {
  const PricingScreen({super.key});

  @override
  ConsumerState<PricingScreen> createState() => _PricingScreenState();
}

class _PricingScreenState extends ConsumerState<PricingScreen> {
  bool _isAnnual = false;

  static const _basicPalette = FitPlanPalette(
    primary: Color(0xFF3A3A44),
    secondary: Color(0xFF5A5A66),
  );

  static const _proPalette = FitPlanPalette(
    primary: Color(0xFFE84F00),
    secondary: Color(0xFFFF7A2E),
  );

  static const _elitePalette = FitPlanPalette(
    primary: Color(0xFFFF5C00),
    secondary: Color(0xFFFFB830),
  );

  String _priceFor(PlanTier tier) {
    if (_isAnnual) {
      final perMonth = PlanLimits.annualPrice[tier]! / 12;
      return '₹${perMonth.toStringAsFixed(0)}';
    }
    return '₹${PlanLimits.monthlyPrice[tier]!.toInt()}';
  }

  BillingInterval get _interval =>
      _isAnnual ? BillingInterval.annual : BillingInterval.monthly;

  double _checkoutAmount(PlanTier tier) {
    return _isAnnual
        ? PlanLimits.annualPrice[tier]!
        : PlanLimits.monthlyPrice[tier]!;
  }

  List<FitPricingPlanData> _buildPlans() {
    return [
      FitPricingPlanData(
        title: 'Basic',
        price: _priceFor(PlanTier.basic),
        period: '/mo',
        billingNote: _isAnnual
            ? 'billed ${PlanLimits.formatAnnual(PlanTier.basic)}'
            : null,
        description:
            'A focused starter plan for independent studios building a clean digital operation.',
        ctaLabel: 'Get Started',
        palette: _basicPalette,
        badge:
            _isAnnual ? PlanLimits.formatAnnualSavings(PlanTier.basic) : null,
        features: const [
          FitPricingFeatureData(label: '50 clients capacity'),
          FitPricingFeatureData(label: '1 trainer seat'),
          FitPricingFeatureData(label: 'Membership and billing tools'),
          FitPricingFeatureData(label: 'AI assistant access', included: false),
          FitPricingFeatureData(label: 'Custom branding', included: false),
        ],
      ),
      FitPricingPlanData(
        title: 'Pro',
        price: _priceFor(PlanTier.pro),
        period: '/mo',
        billingNote: _isAnnual
            ? 'billed ${PlanLimits.formatAnnual(PlanTier.pro)}'
            : null,
        description:
            'Built for growing gyms that want AI workout plans, AI diet plans, advanced analysis, and progress insights.',
        ctaLabel: 'Go Pro',
        palette: _proPalette,
        badge: _isAnnual ? PlanLimits.formatAnnualSavings(PlanTier.pro) : null,
        features: const [
          FitPricingFeatureData(label: '200 clients capacity'),
          FitPricingFeatureData(label: '5 trainer seats'),
          FitPricingFeatureData(label: 'Advanced analytics'),
          FitPricingFeatureData(
              label: 'AI workout + diet planning', emphasize: true),
          FitPricingFeatureData(label: 'Full-body progress page'),
          FitPricingFeatureData(label: 'Custom branding', included: false),
        ],
      ),
      FitPricingPlanData(
        title: 'Elite',
        price: _priceFor(PlanTier.elite),
        period: '/mo',
        billingNote: _isAnnual
            ? 'billed ${PlanLimits.formatAnnual(PlanTier.elite)}'
            : null,
        description:
            'The premium command center for ambitious fitness brands and high-volume teams.',
        ctaLabel: 'Go Elite',
        palette: _elitePalette,
        highlighted: true,
        badge: _isAnnual
            ? PlanLimits.formatAnnualSavings(PlanTier.elite)
            : 'Most Popular',
        features: const [
          FitPricingFeatureData(label: '500 clients capacity'),
          FitPricingFeatureData(label: 'Unlimited trainer seats'),
          FitPricingFeatureData(label: 'Full performance suite'),
          FitPricingFeatureData(label: 'AI Kimi Elite access', emphasize: true),
          FitPricingFeatureData(label: 'White-label branding'),
        ],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final plans = _buildPlans();

    final comparisonRows = [
      const FitComparisonRowData(
        label: 'Client capacity',
        values: ['Up to 50', 'Up to 200', 'Up to 500'],
        highlightedIndex: 2,
      ),
      const FitComparisonRowData(
        label: 'AI intelligence',
        values: ['None', 'Kimi Pro', 'Kimi Elite'],
        highlightedIndex: 2,
      ),
      const FitComparisonRowData(
        label: 'Automated workout generation',
        values: ['No', 'Yes', 'Yes'],
      ),
      const FitComparisonRowData(
        label: 'AI diet generation',
        values: ['No', 'Yes', 'Yes'],
      ),
      const FitComparisonRowData(
        label: 'Full-body progress page',
        values: ['No', 'Yes', 'Yes'],
      ),
      const FitComparisonRowData(
        label: 'Trainer seat limits',
        values: ['1', '5', 'Unlimited'],
        highlightedIndex: 2,
      ),
      FitComparisonRowData(
        label: 'Monthly price',
        values: [
          '₹${PlanLimits.monthlyPrice[PlanTier.basic]!.toInt()}',
          '₹${PlanLimits.monthlyPrice[PlanTier.pro]!.toInt()}',
          '₹${PlanLimits.monthlyPrice[PlanTier.elite]!.toInt()}',
        ],
      ),
      FitComparisonRowData(
        label: 'Annual price',
        values: [
          '₹${PlanLimits.annualPrice[PlanTier.basic]!.toInt()}/yr',
          '₹${PlanLimits.annualPrice[PlanTier.pro]!.toInt()}/yr',
          '₹${PlanLimits.annualPrice[PlanTier.elite]!.toInt()}/yr',
        ],
        highlightedIndex: 2,
      ),
      const FitComparisonRowData(
        label: 'Branding and support',
        values: ['Email support', 'Priority email', 'White-label + concierge'],
        highlightedIndex: 2,
      ),
    ];

    return FitPricingLandingPage(
      title: 'Elevate Your Fitness Journey',
      subtitle:
          'Transform your training business with AI workout plans, AI diet plans, and progress analysis. Choose the plan that matches your studio growth, team size, and ambition.',
      headerActionLabel: 'Back to App',
      plans: plans,
      comparisonRows: comparisonRows,
      billingToggle: _BillingToggle(
        isAnnual: _isAnnual,
        onChanged: (val) => setState(() => _isAnnual = val),
      ),
      onHeaderAction: () {
        if (context.canPop()) {
          context.pop();
          return;
        }
        context.go('/');
      },
      onPlanSelected: (planData) async {
        final tier = _tierFromTitle(planData.title);
        if (tier == PlanTier.basic) {
          context.showSnackBar(
              'Basic plan selected. You are already on this plan or it is free.');
          return;
        }

        final user = ref.read(currentUserProvider).value;
        final gym = ref.read(selectedGymProvider);

        if (user == null || gym == null) {
          context.showSnackBar('Please sign in to upgrade your plan.');
          return;
        }

        final paymentService = ref.read(paymentServiceProvider);
        final amount = _checkoutAmount(tier);

        // Initiate Razorpay
        paymentService.startRazorpayCheckout(
          options: {
            'amount':
                (amount * 100).toInt(), // Razorpay expects amount in paise
            'name': 'FitNexora ${planData.title}',
            'description': '${_interval.label} subscription for ${gym.name}',
            'prefill': {
              'contact': user.phone ?? '',
              'email': user.email,
            },
            'external': {
              'wallets': ['paytm']
            }
          },
          onSuccess: (response) async {
            context.showSnackBar('Payment successful! Upgrading your plan...');
            try {
              await paymentService.handleRazorpaySuccess(
                gymId: gym.id,
                plan: tier,
                interval: _interval,
                paymentId: response.paymentId ?? '',
                signature: response.signature,
                orderId: response.orderId,
              );
              // Refresh subscription state
              ref.invalidate(gymSubscriptionProvider(gym.id));
              if (context.mounted) {
                context.showSnackBar('Plan upgraded to ${planData.title}!');
              }
            } catch (e) {
              if (context.mounted) {
                context.showSnackBar('Error updating subscription: $e');
              }
            }
          },
          onError: (response) {
            context.showSnackBar('Payment failed: ${response.message}');
          },
          onExternalWallet: (response) {
            context.showSnackBar(
                'External wallet selected: ${response.walletName}');
          },
        );
      },
    );
  }

  static PlanTier _tierFromTitle(String title) {
    switch (title.toLowerCase()) {
      case 'pro':
        return PlanTier.pro;
      case 'elite':
        return PlanTier.elite;
      default:
        return PlanTier.basic;
    }
  }
}

// ─── Billing Toggle Widget ──────────────────────────────────────────

class _BillingToggle extends StatelessWidget {
  const _BillingToggle({
    required this.isAnnual,
    required this.onChanged,
  });

  final bool isAnnual;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.fitTheme;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.surfaceAlt,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _toggleOption(
            context,
            label: 'Monthly',
            isSelected: !isAnnual,
            onTap: () => onChanged(false),
          ),
          _toggleOption(
            context,
            label: 'Annual',
            isSelected: isAnnual,
            onTap: () => onChanged(true),
            badge: 'Save 17%',
          ),
        ],
      ),
    );
  }

  Widget _toggleOption(
    BuildContext context, {
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    String? badge,
  }) {
    final colors = context.fitTheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? colors.brand : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: colors.brand.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : colors.textSecondary,
              ),
            ),
            if (badge != null && isSelected) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: colors.accent,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  badge,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
