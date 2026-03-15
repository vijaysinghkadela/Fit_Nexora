import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/extensions.dart';
import '../../providers/gym_provider.dart';
import '../../widgets/fit_pricing.dart';

/// Upgrade prompt for members trying to access Pro features.
class ProPaywallScreen extends ConsumerWidget {
  const ProPaywallScreen({super.key});

  static const _palette = FitPlanPalette(
    primary: Color(0xFFF2B451),
    secondary: Color(0xFFFF8C42),
    darkOnAccent: true,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gym = ref.watch(selectedGymProvider);
    final phone = gym?.phone?.trim() ?? '';

    return FitPlanUpgradePage(
      title: 'Upgrade to Pro',
      subtitle:
          'Everything in Basic, plus AI-powered guidance for workouts, food tracking, and body metrics.',
      sectionTitle: 'WHAT UNLOCKS WITH PRO',
      offer: const FitPricingPlanData(
        title: 'Pro',
        price: 'Rs 899',
        period: '/month',
        description:
            'The smart member tier for AI-enhanced training, nutrition analysis, and deeper progress insight.',
        ctaLabel: 'Upgrade at Your Gym',
        palette: _palette,
        features: [
          FitPricingFeatureData(label: 'Everything in Basic'),
          FitPricingFeatureData(label: 'AI workout recommendations', emphasize: true),
          FitPricingFeatureData(label: 'AI diet suggestions'),
          FitPricingFeatureData(label: 'Barcode and macro tracking'),
          FitPricingFeatureData(label: 'Body measurements dashboard'),
        ],
      ),
      featureItems: const [
        FitUpgradeFeatureItemData(
          icon: Icons.smart_toy_rounded,
          title: 'AI workout recommendations',
          subtitle: 'Generate smarter plans based on your goal, schedule, and current training load.',
          palette: _palette,
          accent: true,
        ),
        FitUpgradeFeatureItemData(
          icon: Icons.restaurant_rounded,
          title: 'AI diet suggestions',
          subtitle: 'Get meals and macro guidance tailored to your training target and daily intake.',
          palette: _palette,
        ),
        FitUpgradeFeatureItemData(
          icon: Icons.local_fire_department_rounded,
          title: 'Calories and macro tracking',
          subtitle: 'Track what you eat, what you burn, and how well you are staying aligned with your goal.',
          palette: _palette,
        ),
        FitUpgradeFeatureItemData(
          icon: Icons.qr_code_scanner_rounded,
          title: 'Barcode nutrition logging',
          subtitle: 'Scan packaged foods and log nutrition faster during busy days.',
          palette: _palette,
        ),
        FitUpgradeFeatureItemData(
          icon: Icons.straighten_rounded,
          title: 'Body measurements and charts',
          subtitle: 'Log waist, chest, arms, hips, and progress trends beyond body weight alone.',
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
