import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/plan_limits.dart';
import '../../core/enums.dart';
import '../../models/subscription_model.dart';
import '../../core/extensions.dart';
import '../../providers/auth_provider.dart';
import '../../providers/gym_provider.dart';
import '../../providers/payment_provider.dart';
import '../../widgets/fit_pricing.dart';

class PricingScreen extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
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
        if (context.canPop()) {
          context.pop();
          return;
        }
        context.go('/');
      },
      onPlanSelected: (planData) async {
        final tier = _tierFromTitle(planData.title);
        if (tier == PlanTier.basic) {
          context.showSnackBar('Basic plan selected. You are already on this plan or it is free.');
          return;
        }

        final user = ref.read(currentUserProvider).value;
        final gym = ref.read(selectedGymProvider);

        if (user == null || gym == null) {
          context.showSnackBar('Please sign in to upgrade your plan.');
          return;
        }

        final paymentService = ref.read(paymentServiceProvider);
        final amount = PlanLimits.monthlyPrice[tier] ?? 0;

        // Initiate Razorpay
        paymentService.startRazorpayCheckout(
          options: {
            'amount': (amount * 100).toInt(), // Razorpay expects amount in paise
            'name': 'FitNexora ${planData.title}',
            'description': 'Monthly subscription for ${gym.name}',
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
                interval: BillingInterval.monthly,
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
            context.showSnackBar('External wallet selected: ${response.walletName}');
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

  static String _priceFor(PlanTier tier) {
    final price = PlanLimits.monthlyPrice[tier] ?? 0;
    return '\$${price.toStringAsFixed(2)}';
  }
}
