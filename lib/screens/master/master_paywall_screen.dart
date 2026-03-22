import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/extensions.dart';
import '../../providers/gym_provider.dart';
import '../../widgets/fit_pricing.dart';

/// Master paywall shown when the user does not have the Master tier.
class MasterPaywallScreen extends ConsumerWidget {
  const MasterPaywallScreen({super.key});

  static const _palette = FitPlanPalette(
    primary: Color(0xFFFF3D5E),
    secondary: Color(0xFFFF8C00),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gym = ref.watch(selectedGymProvider);
    final phone = gym?.phone?.trim() ?? '';

    return FitPlanUpgradePage(
      title: 'Enter Master Tier',
      subtitle:
          'This is the top-end guided performance tier, built for members who want daily AI coaching and direct high-touch support.',
      sectionTitle: 'EXCLUSIVE MASTER FEATURES',
      offer: const FitPricingPlanData(
        title: 'Master',
        price: 'Rs 2499',
        period: '/month',
        description:
            'All Elite features plus the deepest AI coaching, live sessions, and recovery-aware guidance in the app.',
        ctaLabel: 'Upgrade at Your Gym',
        palette: _palette,
        highlighted: true,
        badge: 'Highest Tier',
        features: [
          FitPricingFeatureData(label: 'Everything in Elite'),
          FitPricingFeatureData(label: 'Full AI coach', emphasize: true),
          FitPricingFeatureData(label: 'Adaptive daily plans'),
          FitPricingFeatureData(label: 'Live trainer sessions'),
          FitPricingFeatureData(label: 'Priority support'),
        ],
      ),
      featureItems: const [
        FitUpgradeFeatureItemData(
          icon: Icons.smart_toy_rounded,
          title: 'Full AI fitness coach',
          subtitle: 'Get deeper day-to-day coaching, not just isolated recommendations, across your training cycle.',
          palette: _palette,
          accent: true,
        ),
        FitUpgradeFeatureItemData(
          icon: Icons.bolt_rounded,
          title: 'Adaptive daily programming',
          subtitle: 'Plans shift with fatigue, energy, readiness, and your near-term performance trend.',
          palette: _palette,
        ),
        FitUpgradeFeatureItemData(
          icon: Icons.restaurant_menu_rounded,
          title: 'AI nutrition coaching',
          subtitle: 'Adjust meals, calories, and recovery nutrition with more active guidance from the system.',
          palette: _palette,
        ),
        FitUpgradeFeatureItemData(
          icon: Icons.video_call_rounded,
          title: 'Live trainer sessions',
          subtitle: 'Book direct sessions for a more human coaching loop when you need review or accountability.',
          palette: _palette,
        ),
        FitUpgradeFeatureItemData(
          icon: Icons.analytics_rounded,
          title: 'Recovery and analytics suite',
          subtitle: 'Track readiness, performance shifts, and deeper insight signals that shape your next block.',
          palette: _palette,
        ),
      ],
      contactTitle: 'Master upgrades go through your gym',
      contactMessage:
          'Your gym enables Master access. Reach out if you want the highest coaching tier with live sessions and full AI support.',
      gymName: gym?.name,
      gymPhone: phone.isEmpty ? null : phone,
      primaryActionLabel: 'Contact Gym',
      onPrimaryAction: () => context.showSnackBar(
        phone.isEmpty
            ? 'Ask your gym front desk to activate the Master plan.'
            : 'Call $phone to activate the Master plan.',
      ),
      secondaryActionLabel: 'Not Now',
      onSecondaryAction: () => Navigator.of(context).maybePop(),
    );
  }
}
