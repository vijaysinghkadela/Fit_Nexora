import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/extensions.dart';
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
    final t = context.fitTheme;
    final date = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: t.brand,
              surface: t.surfaceAlt,
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
        final messenger = ScaffoldMessenger.of(context);
        final t = context.fitTheme;
        final name = widget.client.fullName;

        Navigator.of(context).pop(true);

        messenger.showSnackBar(
          SnackBar(
            content: Text('Membership created for $name'),
            backgroundColor: t.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'), backgroundColor: context.fitTheme.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: t.surfaceAlt,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: t.glassBorder, width: 1),
          left: BorderSide(color: t.glassBorder, width: 1),
          right: BorderSide(color: t.glassBorder, width: 1),
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
              color: t.textMuted.withOpacity(0.3),
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
                        color: t.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'For ${widget.client.fullName ?? 'client'}',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: t.textSecondary,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(Icons.close_rounded,
                      color: t.textMuted),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          Divider(color: t.divider, height: 1),

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
                      style: GoogleFonts.inter(color: t.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'Plan Name *',
                        hintText: 'Monthly Premium, Annual Gold…',
                        prefixIcon: Icon(Icons.card_membership_rounded,
                            color: t.textMuted, size: 18),
                        filled: true,
                        fillColor: t.surfaceMuted,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: t.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: t.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                              color: t.brand, width: 2),
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
                      style: GoogleFonts.inter(color: t.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'Amount (₹)',
                        hintText: '1500',
                        prefixIcon: Icon(Icons.currency_rupee_rounded,
                            color: t.textMuted, size: 18),
                        filled: true,
                        fillColor: t.surfaceMuted,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: t.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: t.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                              color: t.brand, width: 2),
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
                        color: t.textPrimary,
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
                                  ? t.brand.withOpacity(0.15)
                                  : t.surfaceMuted,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected
                                    ? t.brand
                                    : t.border,
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
                                    ? t.brand
                                    : t.textSecondary,
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
                        color: t.surfaceMuted,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: t.border),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.autorenew_rounded,
                                  color: t.textMuted, size: 20),
                              const SizedBox(width: 10),
                              Text(
                                'Auto-renew',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: t.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          Switch(
                            value: _autoRenew,
                            onChanged: (v) => setState(() => _autoRenew = v),
                            activeColor: t.brand,
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
                          backgroundColor: t.accent,
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
    final t = context.fitTheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: t.surfaceMuted,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: t.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: t.textMuted,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.calendar_today_rounded,
                    size: 14, color: t.textMuted),
                const SizedBox(width: 6),
                Text(
                  '${date.day}/${date.month}/${date.year}',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: t.textPrimary,
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
