import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../config/plan_limits.dart';
import '../../core/enums.dart';
import '../../core/extensions.dart';
import '../../widgets/fit_pricing.dart';

class PricingScreen extends StatelessWidget {
  const PricingScreen({super.key});

  static const _basicPalette = FitPlanPalette(
    primary: Color(0xFF6E6489),
    secondary: Color(0xFF9E95B5),
  );

  static const _proPalette = FitPlanPalette(
    primary: Color(0xFFF2B451),
    secondary: Color(0xFFFFD37A),
    darkOnAccent: true,
  );

  static const _elitePalette = FitPlanPalette(
    primary: Color(0xFF895AF6),
    secondary: Color(0xFFB895FF),
  );

  @override
  Widget build(BuildContext context) {
    final plans = [
      FitPricingPlanData(
        title: 'Basic',
        price: _priceFor(PlanTier.basic),
        period: '/mo',
        description:
            'A focused starter plan for independent studios building a clean digital operation.',
        ctaLabel: 'Get Started',
        palette: _basicPalette,
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
        description:
            'Built for growing gyms that want better analytics and guided AI automation.',
        ctaLabel: 'Go Pro',
        palette: _proPalette,
        features: const [
          FitPricingFeatureData(label: '200 clients capacity'),
          FitPricingFeatureData(label: '5 trainer seats'),
          FitPricingFeatureData(label: 'Advanced analytics'),
          FitPricingFeatureData(label: 'AI Haiku assistant', emphasize: true),
          FitPricingFeatureData(label: 'Custom branding', included: false),
        ],
      ),
      FitPricingPlanData(
        title: 'Elite',
        price: _priceFor(PlanTier.elite),
        period: '/mo',
        description:
            'The premium command center for ambitious fitness brands and high-volume teams.',
        ctaLabel: 'Go Elite',
        palette: _elitePalette,
        highlighted: true,
        badge: 'Most Popular',
        features: const [
          FitPricingFeatureData(label: '500 clients capacity'),
          FitPricingFeatureData(label: 'Unlimited trainer seats'),
          FitPricingFeatureData(label: 'Full performance suite'),
          FitPricingFeatureData(label: 'AI Opus access', emphasize: true),
          FitPricingFeatureData(label: 'White-label branding'),
        ],
      ),
    ];

    final comparisonRows = [
      const FitComparisonRowData(
        label: 'Client capacity',
        values: ['Up to 50', 'Up to 200', 'Up to 500'],
        highlightedIndex: 2,
      ),
      const FitComparisonRowData(
        label: 'AI intelligence',
        values: ['None', 'Haiku', 'Opus + Haiku'],
        highlightedIndex: 2,
      ),
      const FitComparisonRowData(
        label: 'Automated workout generation',
        values: ['No', 'Yes', 'Yes'],
      ),
      const FitComparisonRowData(
        label: 'Trainer seat limits',
        values: ['1', '5', 'Unlimited'],
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
          'Transform your training business with refined AI-driven tools. Choose the plan that matches your studio growth, team size, and ambition.',
      headerActionLabel: 'Back to App',
      plans: plans,
      comparisonRows: comparisonRows,
      onHeaderAction: () {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).maybePop();
          return;
        }
        context.go('/');
      },
      onPlanSelected: (plan) {
        context.showSnackBar(
          '${plan.title} checkout is not wired yet. Connect Stripe or Razorpay to complete billing.',
        );
      },
    );
  }

  static String _priceFor(PlanTier tier) {
    final price = PlanLimits.monthlyPrice[tier] ?? 0;
    return '\$${price.toStringAsFixed(2)}';
  }
}
