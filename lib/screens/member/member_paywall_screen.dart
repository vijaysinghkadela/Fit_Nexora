import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/extensions.dart';
import '../../providers/auth_provider.dart';
import '../../providers/gym_provider.dart';
import '../../widgets/fit_pricing.dart';

/// Paywall shown when a client needs to upgrade for premium features.
/// 
/// REMINDER: Free tier features (attendance, traffic, calendar, quotes, check-in/out) 
/// are always accessible without membership. This paywall only appears for premium features.
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
      title: 'Upgrade Membership',
      subtitle: 
          'You have access to FREE features: attendance, live gym traffic, calendar, motivation quotes, and check-in/check-out. '
          'Upgrade to unlock premium features: AI workout plans, advanced analytics, body measurements, and more.',
      sectionTitle: 'PREMIUM FEATURES YOU\'LL GET',
      actions: [
        IconButton(
          onPressed: () => ref.read(currentUserProvider.notifier).signOut(),
          icon: const Icon(Icons.logout_rounded),
          tooltip: 'Logout',
        ),
      ],
      offer: const FitPricingPlanData(
        title: 'Premium',
        price: '', // Pricing determined by gym - not shown here
        period: '',
        description:
            'Unlock all premium features including AI workout plans, advanced analytics, and nutrition tracking.',
        ctaLabel: 'Contact Your Gym to Upgrade',
        palette: _palette,
        features: [
          FitPricingFeatureData(label: 'AI Workout Plans'),
          FitPricingFeatureData(label: 'AI Diet Plans'),
          FitPricingFeatureData(label: 'Body Measurements'),
          FitPricingFeatureData(label: 'Water Tracker'),
          FitPricingFeatureData(label: 'Personal Records'),
          FitPricingFeatureData(label: 'Macro Calculator'),
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
      contactTitle: 'Ready to Upgrade?',
      contactMessage:
          'Your gym manages all membership upgrades. Contact them to learn about premium plan options and pricing.',
      gymName: gym?.name,
      gymPhone: phone.isEmpty ? null : phone,
      primaryActionLabel: 'Contact Gym',
      onPrimaryAction: () => context.showSnackBar(
        phone.isEmpty
            ? 'Visit your gym front desk or use the contact information provided.'
            : 'Call $phone to learn about premium plans.',
      ),
      secondaryActionLabel: 'Not Now',
      onSecondaryAction: () {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/member');
        }
      },
    );
  }
}
