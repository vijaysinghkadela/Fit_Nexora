import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../models/client_profile_model.dart';
import '../../models/membership_model.dart';
import '../../providers/auth_provider.dart';

/// Bottom sheet form for creating a new membership.
class AddMembershipScreen extends ConsumerStatefulWidget {
  final ClientProfile client;

  const AddMembershipScreen({super.key, required this.client});

  @override
  ConsumerState<AddMembershipScreen> createState() =>
      _AddMembershipScreenState();
}

class _AddMembershipScreenState extends ConsumerState<AddMembershipScreen> {
  final _formKey = GlobalKey<FormState>();
  final _planNameController = TextEditingController();
  final _amountController = TextEditingController();

  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 30));
  String _duration = '1_month';
  bool _autoRenew = false;
  bool _isLoading = false;

  final _durationOptions = const {
    '1_month': '1 Month',
    '3_months': '3 Months',
    '6_months': '6 Months',
    '1_year': '1 Year',
    'custom': 'Custom',
  };

  @override
  void dispose() {
    _planNameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _updateEndDate() {
    switch (_duration) {
      case '1_month':
        _endDate =
            DateTime(_startDate.year, _startDate.month + 1, _startDate.day);
        break;
      case '3_months':
        _endDate =
            DateTime(_startDate.year, _startDate.month + 3, _startDate.day);
        break;
      case '6_months':
        _endDate =
            DateTime(_startDate.year, _startDate.month + 6, _startDate.day);
        break;
      case '1_year':
        _endDate =
            DateTime(_startDate.year + 1, _startDate.month, _startDate.day);
        break;
    }
    setState(() {});
  }

  Future<void> _selectDate(bool isStart) async {
    final date = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              surface: AppColors.bgCard,
            ),
          ),
          child: child!,
        );
      },
    );

    if (date != null) {
      setState(() {
        if (isStart) {
          _startDate = date;
          _updateEndDate();
        } else {
          _endDate = date;
          _duration = 'custom';
        }
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final db = ref.read(databaseServiceProvider);
      final membership = Membership(
        id: '',
        clientId: widget.client.id,
        gymId: widget.client.gymId,
        planName: _planNameController.text.trim(),
        amount: double.tryParse(_amountController.text),
        startDate: _startDate,
        endDate: _endDate,
        autoRenew: _autoRenew,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await db.createMembership(membership);

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Membership created for ${widget.client.fullName}'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: AppColors.glassBorder, width: 1),
          left: BorderSide(color: AppColors.glassBorder, width: 1),
          right: BorderSide(color: AppColors.glassBorder, width: 1),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textMuted.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'New Membership',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'For ${widget.client.fullName ?? 'client'}',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded,
                      color: AppColors.textMuted),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          const Divider(color: AppColors.divider, height: 1),

          // Form
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(24, 20, 24, 20 + bottomInset),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Plan Name
                    TextFormField(
                      controller: _planNameController,
                      style: GoogleFonts.inter(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'Plan Name *',
                        hintText: 'Monthly Premium, Annual Gold…',
                        prefixIcon: const Icon(Icons.card_membership_rounded,
                            color: AppColors.textMuted, size: 18),
                        filled: true,
                        fillColor: AppColors.bgInput,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: AppColors.primary, width: 2),
                        ),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Plan name is required'
                          : null,
                    ),

                    const SizedBox(height: 18),

                    // Amount
                    TextFormField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      style: GoogleFonts.inter(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'Amount (₹)',
                        hintText: '1500',
                        prefixIcon: const Icon(Icons.currency_rupee_rounded,
                            color: AppColors.textMuted, size: 18),
                        filled: true,
                        fillColor: AppColors.bgInput,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: AppColors.primary, width: 2),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Duration selector
                    Text(
                      'Duration',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _durationOptions.entries.map((entry) {
                        final isSelected = _duration == entry.key;
                        return GestureDetector(
                          onTap: () {
                            setState(() => _duration = entry.key);
                            if (entry.key != 'custom') _updateEndDate();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary.withValues(alpha: 0.15)
                                  : AppColors.bgInput,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.border,
                              ),
                            ),
                            child: Text(
                              entry.value,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 20),

                    // Date pickers
                    Row(
                      children: [
                        Expanded(
                          child: _buildDateField(
                            'Start Date',
                            _startDate,
                            () => _selectDate(true),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildDateField(
                            'End Date',
                            _endDate,
                            () => _selectDate(false),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Auto-renew toggle
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.bgInput,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.autorenew_rounded,
                                  color: AppColors.textMuted, size: 20),
                              const SizedBox(width: 10),
                              Text(
                                'Auto-renew',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          Switch(
                            value: _autoRenew,
                            onChanged: (v) => setState(() => _autoRenew = v),
                            activeColor: AppColors.primary,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Submit
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton(
                        onPressed: _isLoading ? null : _handleSubmit,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.black,
                                ),
                              )
                            : Text(
                                'Create Membership',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().slideY(begin: 0.05, end: 0, duration: 300.ms).fadeIn();
  }

  Widget _buildDateField(String label, DateTime date, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.bgInput,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.calendar_today_rounded,
                    size: 14, color: AppColors.textMuted),
                const SizedBox(width: 6),
                Text(
                  '${date.day}/${date.month}/${date.year}',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
