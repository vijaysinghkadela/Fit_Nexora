import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/extensions.dart';
import '../../providers/gym_provider.dart';
import '../../widgets/fit_pricing.dart';

/// Upgrade prompt for members trying to access Pro features.
class ProPaywallScreen extends ConsumerWidget {
  const ProPaywallScreen({super.key});

  static const _palette = FitPlanPalette(
    primary: Color(0xFFE84F00),
    secondary: Color(0xFFFF7A2E),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gym = ref.watch(selectedGymProvider);
    final phone = gym?.phone?.trim() ?? '';

    return FitPlanUpgradePage(
      title: 'Upgrade to Pro',
      subtitle:
          'Everything in Basic, plus AI workout plans, AI diet plans, advanced analysis, and the full-body progress page.',
      sectionTitle: 'WHAT UNLOCKS WITH PRO',
      offer: const FitPricingPlanData(
        title: 'Pro',
        price: 'Rs 899',
        period: '/month',
        description:
            'The smart member tier for AI-enhanced training, nutrition analysis, body-progress insights, and plan generation.',
        ctaLabel: 'Upgrade at Your Gym',
        palette: _palette,
        features: [
          FitPricingFeatureData(label: 'Everything in Basic'),
          FitPricingFeatureData(label: 'AI workout plans', emphasize: true),
          FitPricingFeatureData(label: 'AI diet plans'),
          FitPricingFeatureData(label: 'AI analysis'),
          FitPricingFeatureData(label: 'Full-body progress page'),
          FitPricingFeatureData(label: 'Barcode and macro tracking'),
          FitPricingFeatureData(label: 'Body measurements dashboard'),
        ],
      ),
      featureItems: const [
        FitUpgradeFeatureItemData(
          icon: Icons.smart_toy_rounded,
          title: 'AI workout plans',
          subtitle:
              'Generate smarter plans based on your goal, schedule, equipment, and current training load.',
          palette: _palette,
          accent: true,
        ),
        FitUpgradeFeatureItemData(
          icon: Icons.restaurant_rounded,
          title: 'AI diet plans',
          subtitle:
              'Get meals and macro guidance tailored to your training target, restrictions, and daily intake.',
          palette: _palette,
        ),
        FitUpgradeFeatureItemData(
          icon: Icons.insights_rounded,
          title: 'AI analysis',
          subtitle:
              'Review body trends, plan effectiveness, and the next best adjustment in one place.',
          palette: _palette,
        ),
        FitUpgradeFeatureItemData(
          icon: Icons.monitor_heart_rounded,
          title: 'Full-body progress page',
          subtitle:
              'Track measurements, trends, and the latest AI-generated action items together.',
          palette: _palette,
        ),
        FitUpgradeFeatureItemData(
          icon: Icons.local_fire_department_rounded,
          title: 'Calories and macro tracking',
          subtitle:
              'Track what you eat, what you burn, and how well you are staying aligned with your goal.',
          palette: _palette,
        ),
        FitUpgradeFeatureItemData(
          icon: Icons.qr_code_scanner_rounded,
          title: 'Barcode nutrition logging',
          subtitle:
              'Scan packaged foods and log nutrition faster during busy days.',
          palette: _palette,
        ),
        FitUpgradeFeatureItemData(
          icon: Icons.straighten_rounded,
          title: 'Body measurements and charts',
          subtitle:
              'Log waist, chest, arms, hips, and progress trends beyond body weight alone.',
          palette: _palette,
        ),
      ],
      contactTitle: 'Ask your gym to enable Pro',
      contactMessage:
          'Your gym controls member upgrades. Reach out to activate Pro and unlock the AI features attached to your account.',
      gymName: gym?.name,
      gymPhone: phone.isEmpty ? null : phone,
      primaryActionLabel: 'Contact Gym',
      onPrimaryAction: () => context.showSnackBar(
        phone.isEmpty
            ? 'Ask your gym front desk to activate the Pro plan.'
            : 'Call $phone to activate the Pro plan.',
      ),
      secondaryActionLabel: 'Not Now',
      onSecondaryAction: () => Navigator.of(context).maybePop(),
    );
  }
}
