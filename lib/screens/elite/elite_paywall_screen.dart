import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/extensions.dart';
import '../../providers/gym_provider.dart';
import '../../widgets/fit_pricing.dart';

/// Elite paywall shown to members trying to access Elite tools.
class ElitePaywallScreen extends ConsumerWidget {
  const ElitePaywallScreen({super.key});

  static const _palette = FitPlanPalette(
    primary: Color(0xFF9B5DE5),
    secondary: Color(0xFF6A3DFF),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gym = ref.watch(selectedGymProvider);
    final phone = gym?.phone?.trim() ?? '';

    return FitPlanUpgradePage(
      title: 'Unlock Elite',
      subtitle:
          'Move beyond tracking into adaptive AI coaching, trainer chat, and advanced body-composition insight.',
      sectionTitle: 'WHAT UNLOCKS WITH ELITE',
      offer: const FitPricingPlanData(
        title: 'Elite',
        price: 'Rs 1499',
        period: '/month',
        description:
            'A premium member plan for advanced AI training, recovery-aware recommendations, and richer coaching support.',
        ctaLabel: 'Upgrade at Your Gym',
        palette: _palette,
        highlighted: true,
        badge: 'Elite Tier',
        features: [
          FitPricingFeatureData(label: 'Everything in Pro'),
          FitPricingFeatureData(label: 'Advanced AI trainer', emphasize: true),
          FitPricingFeatureData(label: 'Supplement tracking'),
          FitPricingFeatureData(label: 'Body-fat and muscle analytics'),
          FitPricingFeatureData(label: 'Trainer chat support'),
        ],
      ),
      featureItems: const [
        FitUpgradeFeatureItemData(
          icon: Icons.psychology_rounded,
          title: 'Advanced AI personal trainer',
          subtitle: 'Receive deeper analysis, stronger coaching prompts, and more context-aware training support.',
          palette: _palette,
          accent: true,
        ),
        FitUpgradeFeatureItemData(
          icon: Icons.auto_awesome_rounded,
          title: 'Adaptive workout optimization',
          subtitle: 'Your plan evolves with training performance, energy, and readiness instead of staying static.',
          palette: _palette,
        ),
        FitUpgradeFeatureItemData(
          icon: Icons.medication_rounded,
          title: 'Supplement guidance',
          subtitle: 'Log supplements and follow timing suggestions with a cleaner daily routine.',
          palette: _palette,
        ),
        FitUpgradeFeatureItemData(
          icon: Icons.percent_rounded,
          title: 'Body composition insight',
          subtitle: 'Track body-fat direction, muscle-group performance, and transformation milestones in one tier.',
          palette: _palette,
        ),
        FitUpgradeFeatureItemData(
          icon: Icons.chat_rounded,
          title: 'Trainer chat support',
          subtitle: 'Message your trainer directly inside the app when you need fast clarification or accountability.',
          palette: _palette,
        ),
      ],
      contactTitle: 'Enable Elite through your gym',
      contactMessage:
          'Elite upgrades are activated by your gym. Reach out to switch plans and unlock the premium AI experience.',
      gymName: gym?.name,
      gymPhone: phone.isEmpty ? null : phone,
      primaryActionLabel: 'Contact Gym',
      onPrimaryAction: () => context.showSnackBar(
        phone.isEmpty
            ? 'Ask your gym front desk to activate the Elite plan.'
            : 'Call $phone to activate the Elite plan.',
      ),
      secondaryActionLabel: 'Not Now',
      onSecondaryAction: () => Navigator.of(context).maybePop(),
    );
  }
}
