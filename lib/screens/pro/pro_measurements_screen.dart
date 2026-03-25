import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/extensions.dart';
import '../../providers/auth_provider.dart';
import '../../providers/gym_provider.dart';
import '../../providers/member_provider.dart';
import '../../providers/pro_member_provider.dart';
import '../../widgets/glassmorphic_card.dart';

/// Pro: Body measurements log + history with progress indicators.
class ProMeasurementsScreen extends ConsumerStatefulWidget {
  const ProMeasurementsScreen({super.key});

  @override
  ConsumerState<ProMeasurementsScreen> createState() =>
      _ProMeasurementsScreenState();
}

class _ProMeasurementsScreenState extends ConsumerState<ProMeasurementsScreen> {
  final _weightCtrl = TextEditingController();
  final _bodyFatCtrl = TextEditingController();
  final _waistCtrl = TextEditingController();
  final _chestCtrl = TextEditingController();
  final _armsCtrl = TextEditingController();
  final _hipsCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _weightCtrl.dispose();
    _bodyFatCtrl.dispose();
    _waistCtrl.dispose();
    _chestCtrl.dispose();
    _armsCtrl.dispose();
    _hipsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;
    final allAsync = ref.watch(proAllMeasurementsProvider);

    return Scaffold(
      backgroundColor: t.background,
      appBar: AppBar(
        backgroundColor: t.background,
        leading: BackButton(color: t.textSecondary),
        title: Text('Body Measurements',
            style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: t.textPrimary)),
        actions: [
          TextButton.icon(
            onPressed: () => _showLogSheet(context),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: Text('Log', style: GoogleFonts.inter(fontSize: 13)),
            style: TextButton.styleFrom(foregroundColor: t.accent),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: allAsync.when(
        loading: () => Center(child: CircularProgressIndicator(color: t.brand)),
        error: (e, _) => Center(
            child: Text('$e', style: GoogleFonts.inter(color: t.danger))),
        data: (entries) {
          if (entries.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.straighten_rounded, size: 56, color: t.textMuted),
                  const SizedBox(height: 16),
                  Text('No measurements logged yet',
                      style: GoogleFonts.inter(
                          color: t.textSecondary, fontSize: 16)),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => _showLogSheet(context),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Log First Measurement'),
                    style: FilledButton.styleFrom(backgroundColor: t.accent),
                  ),
                ],
              ),
            );
          }

          final latest = entries.first;
          final prev = entries.length > 1 ? entries[1] : null;

          return CustomScrollView(
            slivers: [
              // Latest summary cards
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('LATEST',
                          style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: t.textMuted,
                              letterSpacing: 1.2)),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          if (latest.weightKg != null)
                            _MeasCard('Weight', latest.weightKg!, 'kg',
                                prev?.weightKg, t.brand),
                          if (latest.bodyFatPercent != null)
                            _MeasCard('Body Fat', latest.bodyFatPercent!, '%',
                                prev?.bodyFatPercent, t.warning),
                          if (latest.waistCm != null)
                            _MeasCard('Waist', latest.waistCm!, 'cm',
                                prev?.waistCm, t.danger),
                          if (latest.chestCm != null)
                            _MeasCard('Chest', latest.chestCm!, 'cm',
                                prev?.chestCm, t.accent),
                          if (latest.armCm != null)
                            _MeasCard('Arms', latest.armCm!, 'cm', prev?.armCm,
                                t.info),
                          if (latest.hipsCm != null)
                            _MeasCard('Hips', latest.hipsCm!, 'cm',
                                prev?.hipsCm, t.success),
                        ],
                      ),
                    ],
                  ).animate().fadeIn(),
                ),
              ),

              // History
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                sliver: SliverToBoxAdapter(
                  child: Text('HISTORY',
                      style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: t.textMuted,
                          letterSpacing: 1.2)),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverToBoxAdapter(
                  child: GlassmorphicCard(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        children: entries.asMap().entries.map((e) {
                          final i = e.key;
                          final m = e.value;
                          final dateStr = _fmt(m.checkInDate);

                          return Column(
                            children: [
                              ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 4),
                                title: Text(dateStr,
                                    style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: t.textPrimary)),
                                subtitle: Text(
                                  _buildSubtitle(m),
                                  style: GoogleFonts.inter(
                                      fontSize: 11, color: t.textSecondary),
                                ),
                                trailing: m.weightKg != null
                                    ? Text(
                                        '${m.weightKg!.toStringAsFixed(1)} kg',
                                        style: GoogleFonts.inter(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w800,
                                            color: t.brand),
                                      )
                                    : null,
                              ),
                              if (i < entries.length - 1)
                                Divider(color: t.divider, height: 1),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ).animate(delay: 100.ms).fadeIn(),
                ),
              ),

              const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
            ],
          );
        },
      ),
    );
  }

  String _buildSubtitle(dynamic m) {
    final parts = <String>[];
    if (m.bodyFatPercent != null) {
      parts.add('Fat: ${(m.bodyFatPercent as double).toStringAsFixed(1)}%');
    }
    if (m.waistCm != null) {
      parts.add('Waist: ${(m.waistCm as double).toStringAsFixed(1)}cm');
    }
    if (m.chestCm != null) {
      parts.add('Chest: ${(m.chestCm as double).toStringAsFixed(1)}cm');
    }
    return parts.isEmpty ? 'Weight only' : parts.join(' · ');
  }

  String _fmt(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  void _showLogSheet(BuildContext context) {
    final t = context.fitTheme;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: t.surfaceAlt,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: t.textMuted.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text('Log Measurements',
                  style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: t.textPrimary)),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(child: _sheetField(_weightCtrl, 'Weight (kg)', t)),
                const SizedBox(width: 12),
                Expanded(child: _sheetField(_bodyFatCtrl, 'Body Fat (%)', t)),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _sheetField(_waistCtrl, 'Waist (cm)', t)),
                const SizedBox(width: 12),
                Expanded(child: _sheetField(_chestCtrl, 'Chest (cm)', t)),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _sheetField(_armsCtrl, 'Arms (cm)', t)),
                const SizedBox(width: 12),
                Expanded(child: _sheetField(_hipsCtrl, 'Hips (cm)', t)),
              ]),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _saving ? null : () => _saveMeasurement(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: t.accent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text('Save Measurements',
                      style: GoogleFonts.inter(
                          fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sheetField(TextEditingController c, String hint, dynamic t) {
    return TextFormField(
      controller: c,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: GoogleFonts.inter(color: t.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(color: t.textMuted, fontSize: 12),
        filled: true,
        fillColor: t.surfaceMuted,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: t.border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: t.accent, width: 2)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: t.border)),
      ),
    );
  }

  Future<void> _saveMeasurement(BuildContext context) async {
    final t = context.fitTheme;
    final user = ref.read(currentUserProvider).value;
    final gym = ref.read(selectedGymProvider);
    final membership = ref.read(memberMembershipProvider).valueOrNull;
    if (user == null || gym == null) return;

    setState(() => _saving = true);
    try {
      final clientId =
          membership?.clientId ?? await ref.read(memberClientIdProvider.future);
      if (clientId == null) {
        throw Exception('Member profile not found for this gym.');
      }

      final db = ref.read(databaseServiceProvider);
      final data = {
        'gym_id': gym.id,
        'client_id': clientId,
        'checkin_date': DateTime.now().toIso8601String().split('T').first,
        if (_weightCtrl.text.isNotEmpty)
          'weight_kg': double.parse(_weightCtrl.text),
        if (_bodyFatCtrl.text.isNotEmpty)
          'body_fat_percent': double.parse(_bodyFatCtrl.text),
        if (_waistCtrl.text.isNotEmpty)
          'waist_cm': double.parse(_waistCtrl.text),
        if (_chestCtrl.text.isNotEmpty)
          'chest_cm': double.parse(_chestCtrl.text),
        if (_armsCtrl.text.isNotEmpty) 'arm_cm': double.parse(_armsCtrl.text),
        if (_hipsCtrl.text.isNotEmpty) 'hips_cm': double.parse(_hipsCtrl.text),
      };

      await db.addProgressCheckIn(data);
      ref.invalidate(proAllMeasurementsProvider);
      ref.invalidate(proBodyMeasurementsProvider);

      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: const Text('Measurements saved!'),
            backgroundColor: t.success));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed: $e'), backgroundColor: t.danger));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

// ─── Measurement comparison card ─────────────────────────────────────────────

class _MeasCard extends StatelessWidget {
  final String label;
  final double value;
  final String unit;
  final double? prevValue;
  final Color color;
  const _MeasCard(
      this.label, this.value, this.unit, this.prevValue, this.color);

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;
    final diff = prevValue != null ? value - prevValue! : null;
    final isGood = diff != null &&
        (label == 'Weight' || label == 'Body Fat' || label == 'Waist'
            ? diff < 0
            : diff >= 0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: GoogleFonts.inter(fontSize: 11, color: t.textSecondary)),
          const SizedBox(height: 2),
          Text('${value.toStringAsFixed(1)} $unit',
              style: GoogleFonts.inter(
                  fontSize: 16, fontWeight: FontWeight.w900, color: color)),
          if (diff != null)
            Text(
              '${diff > 0 ? '+' : ''}${diff.toStringAsFixed(1)} $unit',
              style: GoogleFonts.inter(
                fontSize: 10,
                color: isGood ? t.success : t.danger,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }
}
