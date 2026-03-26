// lib/screens/staff/manage_staff_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../core/extensions.dart';
import '../../providers/auth_provider.dart';
import '../../providers/gym_provider.dart';
import '../../providers/payroll_provider.dart';
import '../../widgets/fit_management_scaffold.dart';
import '../../widgets/glassmorphic_card.dart';
import '../dashboard/dashboard_screen.dart'; // For managementDestinations

class ManageStaffScreen extends ConsumerWidget {
  const ManageStaffScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).value;
    return FitManagementScaffold(
      userName: user?.fullName ?? 'Owner',
      userEmail: user?.email ?? '',
      currentRoute: '/staff',
      destinations: const [
        ...managementDestinations,
        FitShellDestination(
          icon: Icons.badge_rounded,
          label: 'Staff',
          route: '/staff',
        ),
      ],
      mobileDestinations: managementDestinations,
      child: const _StaffBody(),
    );
  }
}

class _StaffBody extends ConsumerWidget {
  const _StaffBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.fitTheme;
    final contractsAsync = ref.watch(trainerContractsProvider);
    final payrollRunsAsync = ref.watch(payrollRunsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Staff & Payroll',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: colors.textPrimary,
                ),
              ),
              FilledButton.icon(
                onPressed: () {
                  // Add staff functionality could go here
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(
                            'Staff addition is handled via role assignment.')),
                  );
                },
                icon: const Icon(Icons.person_add_rounded),
                label: const Text('Add Staff'),
                style: FilledButton.styleFrom(backgroundColor: colors.brand),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Trainers List
          Text(
            'Active Trainers',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          contractsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) =>
                Text('Error: $e', style: TextStyle(color: colors.danger)),
            data: (contracts) {
              if (contracts.isEmpty) {
                return GlassmorphicCard(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        'No trainers found. Ensure trainers are assigned to this gym.',
                        style: TextStyle(color: colors.textMuted),
                      ),
                    ),
                  ),
                );
              }
              return Column(
                children: contracts
                    .map((c) => GlassmorphicCard(
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: colors.brand.withOpacity(0.2),
                              child: Icon(Icons.fitness_center_rounded,
                                  color: colors.brand),
                            ),
                            title: Text(c.trainerName ?? 'Unknown Trainer',
                                style: TextStyle(
                                    color: colors.textPrimary,
                                    fontWeight: FontWeight.bold)),
                            subtitle: Text(
                                'Base Salary: ₹${c.baseSalary.toStringAsFixed(0)} / mo',
                                style: TextStyle(color: colors.textSecondary)),
                            trailing: Switch(
                              value: c.isActive,
                              onChanged:
                                  null, // Edit functionality could be added
                              activeColor: colors.brand,
                            ),
                          ),
                        ))
                    .toList(),
              );
            },
          ),

          const SizedBox(height: 32),

          // Payroll Runs
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Payroll History',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
              TextButton.icon(
                onPressed: () => _generateDraft(context, ref),
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Run Current Month'),
                style: TextButton.styleFrom(foregroundColor: colors.brand),
              ),
            ],
          ),
          const SizedBox(height: 12),
          payrollRunsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) =>
                Text('Error: $e', style: TextStyle(color: colors.danger)),
            data: (runs) {
              if (runs.isEmpty) {
                return GlassmorphicCard(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        'No payroll runs found.',
                        style: TextStyle(color: colors.textMuted),
                      ),
                    ),
                  ),
                );
              }
              return Column(
                children: runs.map((r) {
                  final monthName =
                      DateFormat('MMMM').format(DateTime(r.year, r.month));
                  final isPaid = r.status == 'paid';
                  return GlassmorphicCard(
                    onTap: () => context.push('/staff/payroll/${r.id}'),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isPaid
                            ? colors.success.withOpacity(0.2)
                            : colors.warning.withOpacity(0.2),
                        child: Icon(
                            isPaid
                                ? Icons.check_rounded
                                : Icons.pending_actions_rounded,
                            color: isPaid ? colors.success : colors.warning),
                      ),
                      title: Text('$monthName ${r.year}',
                          style: TextStyle(
                              color: colors.textPrimary,
                              fontWeight: FontWeight.bold)),
                      subtitle: Text(
                          'Total: ₹${r.totalPayout.toStringAsFixed(2)}',
                          style: TextStyle(color: colors.textSecondary)),
                      trailing: const Icon(Icons.chevron_right_rounded),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _generateDraft(BuildContext context, WidgetRef ref) async {
    final now = DateTime.now();
    final gym = ref.read(selectedGymProvider);
    if (gym == null) return;

    try {
      final db = ref.read(databaseServiceProvider);
      final res = await db.generateDraftPayrollRun(gym.id, now.month, now.year);
      ref.invalidate(payrollRunsProvider);
      if (context.mounted) {
        context.push('/staff/payroll/${res['run']['id']}');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }
}
