import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/enums.dart';
import '../providers/auth_provider.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/trainer/trainer_dashboard_screen.dart';
import 'fit_management_scaffold.dart';

class SharedManagementWrapper extends ConsumerWidget {
  final Widget child;
  final String currentRoute;

  const SharedManagementWrapper({
    super.key,
    required this.currentRoute,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider).value;
    final role = currentUser?.globalRole; 
    
    // For dev bypass or edge cases, if role is null we fallback to gymOwner
    final isTrainer = role == UserRole.trainer;
    
    final destinations = isTrainer ? trainerDestinations : managementDestinations;
    final mobileDestinations = isTrainer ? trainerDestinations : managementMobileDestinations;

    final userName = (currentUser?.fullName ?? '').trim().isEmpty
        ? (isTrainer ? 'Coach Alex' : 'FitNexora Owner')
        : currentUser!.fullName;
    final userEmail = currentUser?.email ?? '';

    return FitManagementScaffold(
      currentRoute: currentRoute,
      destinations: destinations,
      mobileDestinations: mobileDestinations,
      userName: userName,
      userEmail: userEmail,
      onSignOut: () {
        ref.read(currentUserProvider.notifier).signOut().then((_) {
          if (context.mounted) {
            context.go('/login');
          }
        }).catchError((_) {
          // Navigate to login even if sign-out fails (e.g. network error)
          if (context.mounted) context.go('/login');
        });
      },
      child: child,
    );
  }
}
