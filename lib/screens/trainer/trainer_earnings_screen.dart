// lib/screens/trainer/trainer_earnings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../core/extensions.dart';
import '../../providers/auth_provider.dart';
import '../../providers/payroll_provider.dart';
import '../../widgets/fit_management_scaffold.dart';
import '../../widgets/glassmorphic_card.dart';
import 'trainer_dashboard_screen.dart'; // For trainerDestinations

class TrainerEarningsScreen extends ConsumerWidget {
  const TrainerEarningsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).value;
    return FitManagementScaffold(
      userName: user?.fullName ?? 'Trainer',
      userEmail: user?.email ?? '',
      currentRoute: '/trainer/earnings',
      destinations: const [
        ...trainerDestinations,
        FitShellDestination(
          icon: Icons.account_balance_wallet_rounded,
          label: 'Earnings',
          route: '/trainer/earnings',
        ),
      ],
      mobileDestinations: trainerDestinations,
      child: const _EarningsBody(),
    );
  }
}

class _EarningsBody extends ConsumerWidget {
  const _EarningsBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.fitTheme;
    final contractAsync = ref.watch(trainerActiveContractProvider);
    final slipsAsync = ref.watch(trainerSalarySlipsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Earnings & Payroll',
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 24),

          // Current Contract
          Text(
            'Current Contract',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          contractAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) =>
                Text('Error: $e', style: TextStyle(color: colors.danger)),
            data: (contract) {
              if (contract == null) {
                return GlassmorphicCard(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        'No active contract found.',
                        style: TextStyle(color: colors.textMuted),
                      ),
                    ),
                  ),
                );
              }
              return GlassmorphicCard(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colors.brand.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.request_quote_rounded,
                            color: colors.brand, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Base Salary',
                                style: TextStyle(
                                    color: colors.textSecondary, fontSize: 13)),
                            Text(
                                '₹${contract.baseSalary.toStringAsFixed(2)} / mo',
                                style: GoogleFonts.inter(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: colors.textPrimary)),
                            const SizedBox(height: 4),
                            Text(
                                'Active since ${DateFormat('MMM d, yyyy').format(contract.startDate)}',
                                style: TextStyle(
                                    color: colors.textMuted, fontSize: 11)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 32),

          // Salary Slips History
          Text(
            'Salary Slips',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          slipsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) =>
                Text('Error: $e', style: TextStyle(color: colors.danger)),
            data: (slips) {
              if (slips.isEmpty) {
                return GlassmorphicCard(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        'No salary slips generated yet.',
                        style: TextStyle(color: colors.textMuted),
                      ),
                    ),
                  ),
                );
              }
              return Column(
                children: slips.map((slip) {
                  final run = slip.payrollRun;
                  final monthName = run != null
                      ? DateFormat('MMMM yyyy')
                          .format(DateTime(run.year, run.month))
                      : 'Unknown Month';
                  final isPaid = slip.status == 'paid';

                  return GlassmorphicCard(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Theme(
                      data: Theme.of(context)
                          .copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
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
                        title: Text(monthName,
                            style: TextStyle(
                                color: colors.textPrimary,
                                fontWeight: FontWeight.bold)),
                        subtitle: Text(
                            'Net Payable: ₹${slip.netPayable.toStringAsFixed(2)}',
                            style: TextStyle(
                                color: isPaid
                                    ? colors.success
                                    : colors.textSecondary)),
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                            child: Column(
                              children: [
                                const Divider(),
                                _SlipRow(
                                    'Base Amount',
                                    '₹${slip.baseAmount.toStringAsFixed(2)}',
                                    colors),
                                _SlipRow(
                                    'Bonuses',
                                    '+ ₹${slip.bonuses.toStringAsFixed(2)}',
                                    colors,
                                    isPositive: true),
                                _SlipRow(
                                    'Deductions',
                                    '- ₹${slip.deductions.toStringAsFixed(2)}',
                                    colors,
                                    isNegative: true),
                                const Divider(),
                                _SlipRow(
                                    'Net Payable',
                                    '₹${slip.netPayable.toStringAsFixed(2)}',
                                    colors,
                                    isBold: true),
                                if (slip.notes != null &&
                                    slip.notes!.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: colors.surfaceAlt,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text('Notes: ${slip.notes}',
                                        style: TextStyle(
                                            color: colors.textSecondary,
                                            fontSize: 13,
                                            fontStyle: FontStyle.italic)),
                                  ),
                                ]
                              ],
                            ),
                          ),
                        ],
                      ),
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
}

class _SlipRow extends StatelessWidget {
  final String label;
  final String value;
  final dynamic colors;
  final bool isBold;
  final bool isPositive;
  final bool isNegative;

  const _SlipRow(this.label, this.value, this.colors,
      {this.isBold = false, this.isPositive = false, this.isNegative = false});

  @override
  Widget build(BuildContext context) {
    Color valColor = colors.textPrimary;
    if (isPositive) valColor = colors.success;
    if (isNegative) valColor = colors.danger;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  color: colors.textSecondary,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(value,
              style: TextStyle(
                  color: valColor,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                  fontSize: isBold ? 16 : 14)),
        ],
      ),
    );
  }
}
