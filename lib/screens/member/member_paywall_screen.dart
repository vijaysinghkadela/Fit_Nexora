import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/extensions.dart';
import '../../providers/auth_provider.dart';
import '../../providers/gym_provider.dart';
import '../../widgets/fit_pricing.dart';

/// Paywall shown when a client has no active member plan.
class MemberPaywallScreen extends ConsumerWidget {
  const MemberPaywallScreen({super.key});

  static const _palette = FitPlanPalette(
    primary: Color(0xFF895AF6),
    secondary: Color(0xFF1FD493),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gym = ref.watch(selectedGymProvider);
    final phone = gym?.phone?.trim() ?? '';

    return FitPlanUpgradePage(
      title: 'Start with Basic',
      subtitle:
          'Unlock the member experience your gym already prepared for you, from check-ins and workouts to progress tracking and announcements.',
      sectionTitle: 'WHAT YOU GET',
      actions: [
        IconButton(
          onPressed: () => ref.read(currentUserProvider.notifier).signOut(),
          icon: const Icon(Icons.logout_rounded),
          tooltip: 'Logout',
        ),
      ],
      offer: const FitPricingPlanData(
        title: 'Basic',
        price: 'Rs 499',
        period: '/month',
        description:
            'A clear, no-friction member plan for everyday training, attendance, and progress visibility.',
        ctaLabel: 'Contact Your Gym',
        palette: _palette,
        features: [
          FitPricingFeatureData(label: 'Membership management'),
          FitPricingFeatureData(label: 'Attendance tracking'),
          FitPricingFeatureData(label: 'Trainer-assigned workouts'),
          FitPricingFeatureData(label: 'Trainer-assigned diet plans'),
          FitPricingFeatureData(label: 'Weight and progress logging'),
        ],
      ),
      featureItems: const [
        FitUpgradeFeatureItemData(
          icon: Icons.card_membership_rounded,
          title: 'Membership dashboard',
          subtitle: 'See your plan name, renewal timing, and access status in one place.',
          palette: _palette,
        ),
        FitUpgradeFeatureItemData(
          icon: Icons.qr_code_scanner_rounded,
          title: 'Attendance check-ins',
          subtitle: 'Check into the gym and monitor monthly attendance without a paper register.',
          palette: _palette,
        ),
        FitUpgradeFeatureItemData(
          icon: Icons.fitness_center_rounded,
          title: 'Assigned workouts',
          subtitle: 'Follow the day-by-day plan created by your trainer and stay consistent.',
          palette: _palette,
        ),
        FitUpgradeFeatureItemData(
          icon: Icons.restaurant_rounded,
          title: 'Assigned nutrition',
          subtitle: 'Access meal plans, calorie targets, and a structured food routine matched to your goals.',
          palette: _palette,
        ),
        FitUpgradeFeatureItemData(
          icon: Icons.campaign_rounded,
          title: 'Gym announcements',
          subtitle: 'Stay updated on closures, events, reminders, and notices directly from your gym.',
          palette: _palette,
        ),
      ],
      contactTitle: 'Purchase through your gym',
      contactMessage:
          'Your gym manages member plan upgrades. Reach out to confirm the Basic plan and activate your account access.',
      gymName: gym?.name,
      gymPhone: phone.isEmpty ? null : phone,
      primaryActionLabel: 'Contact Gym',
      onPrimaryAction: () => context.showSnackBar(
        phone.isEmpty
            ? 'Ask your gym front desk to activate the Basic plan.'
            : 'Call $phone to activate the Basic plan.',
      ),
      secondaryActionLabel: 'Not Now',
      onSecondaryAction: () => Navigator.of(context).maybePop(),
    );
  }
}
