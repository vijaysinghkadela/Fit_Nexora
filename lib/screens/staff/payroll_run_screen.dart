// lib/screens/staff/payroll_run_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../core/extensions.dart';
import '../../models/payroll_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/payroll_provider.dart';
import '../../widgets/glassmorphic_card.dart';

class PayrollRunScreen extends ConsumerStatefulWidget {
  final String runId;
  const PayrollRunScreen({super.key, required this.runId});

  @override
  ConsumerState<PayrollRunScreen> createState() => _PayrollRunScreenState();
}

class _PayrollRunScreenState extends ConsumerState<PayrollRunScreen> {
  @override
  Widget build(BuildContext context) {
    final colors = context.fitTheme;
    final detailsAsync = ref.watch(payrollRunDetailsProvider(widget.runId));

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.surface,
        title: Text('Payroll Run', style: TextStyle(color: colors.textPrimary)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: colors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: detailsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
            child: Text('Error: $e', style: TextStyle(color: colors.danger))),
        data: (data) {
          final run = data['run'] as PayrollRun;
          final slips = data['slips'] as List<SalarySlip>;
          final isPaid = run.status == 'paid';
          final monthName =
              DateFormat('MMMM').format(DateTime(run.year, run.month));

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              // Summary Card
              GlassmorphicCard(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Text('$monthName ${run.year}',
                          style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: colors.textPrimary)),
                      const SizedBox(height: 8),
                      Text(
                          'Total Payout: ₹${run.totalPayout.toStringAsFixed(2)}',
                          style: GoogleFonts.inter(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: colors.brand)),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isPaid
                              ? colors.success.withOpacity(0.2)
                              : colors.warning.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          isPaid ? 'PAID' : 'DRAFT',
                          style: TextStyle(
                              color: isPaid ? colors.success : colors.warning,
                              fontWeight: FontWeight.bold),
                        ),
                      )
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Slips
              Text('Trainer Slips',
                  style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary)),
              const SizedBox(height: 12),
              ...slips.map((slip) => GlassmorphicCard(
                    margin: const EdgeInsets.only(bottom: 12),
                    onTap: isPaid ? null : () => _editSlip(context, slip),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(slip.trainerName ?? 'Trainer',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)),
                              Text('₹${slip.netPayable.toStringAsFixed(2)}',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: colors.brand,
                                      fontSize: 16)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Base: ₹${slip.baseAmount}',
                                  style: TextStyle(
                                      color: colors.textSecondary,
                                      fontSize: 12)),
                              Text('Bonuses: ₹${slip.bonuses}',
                                  style: TextStyle(
                                      color: colors.textSecondary,
                                      fontSize: 12)),
                              Text('Deductions: ₹${slip.deductions}',
                                  style: TextStyle(
                                      color: colors.textSecondary,
                                      fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  )),

              const SizedBox(height: 32),
              if (!isPaid)
                FilledButton.icon(
                  onPressed: () => _markAsPaid(context, run.id),
                  icon: const Icon(Icons.check_circle_rounded),
                  label: const Text('Mark Run as Paid'),
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.success,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  void _editSlip(BuildContext context, SalarySlip slip) {
    final bonusesController =
        TextEditingController(text: slip.bonuses.toString());
    final deductionsController =
        TextEditingController(text: slip.deductions.toString());
    final notesController = TextEditingController(text: slip.notes ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.fitTheme.surface,
        title: Text('Edit Slip: ${slip.trainerName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: bonusesController,
              decoration: const InputDecoration(labelText: 'Bonuses (₹)'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: deductionsController,
              decoration: const InputDecoration(labelText: 'Deductions (₹)'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(labelText: 'Notes'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final db = ref.read(databaseServiceProvider);
              await db.updateSalarySlip(slip.id, {
                'bonuses': double.tryParse(bonusesController.text) ?? 0,
                'deductions': double.tryParse(deductionsController.text) ?? 0,
                'notes': notesController.text,
              });
              ref.invalidate(payrollRunDetailsProvider(widget.runId));
              ref.invalidate(payrollRunsProvider);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _markAsPaid(BuildContext context, String runId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.fitTheme.surface,
        title: const Text('Confirm Payout'),
        content: const Text(
            'Are you sure you want to mark this payroll run as paid? This cannot be undone and will notify trainers.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: context.fitTheme.success),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Mark Paid'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final db = ref.read(databaseServiceProvider);
      await db.markPayrollAsPaid(runId);
      ref.invalidate(payrollRunDetailsProvider(widget.runId));
      ref.invalidate(payrollRunsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Payroll marked as paid! Trainers notified.')));
      }
    }
  }
}
