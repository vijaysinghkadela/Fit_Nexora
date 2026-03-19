// lib/screens/health/body_measurements_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../config/theme.dart';
import '../../core/extensions.dart';
import '../../models/body_measurement_model.dart';
import '../../providers/body_measurement_provider.dart';
import '../../widgets/glassmorphic_card.dart';

class BodyMeasurementsScreen extends ConsumerStatefulWidget {
  const BodyMeasurementsScreen({super.key});

  @override
  ConsumerState<BodyMeasurementsScreen> createState() =>
      _BodyMeasurementsScreenState();
}

class _BodyMeasurementsScreenState
    extends ConsumerState<BodyMeasurementsScreen> {
  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;
    final measurementsAsync = ref.watch(bodyMeasurementProvider);
    final latest = ref.watch(latestMeasurementProvider);

    return Scaffold(
      backgroundColor: t.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddSheet(context, ref),
        backgroundColor: t.brand,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text(
          'Log Measurement',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            backgroundColor: t.surface,
            title: Text(
              'Body Measurements',
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: t.textPrimary,
              ),
            ),
            leading: IconButton(
              icon: Icon(Icons.arrow_back_rounded, color: t.textPrimary),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ),

          // Latest snapshot card
          if (latest != null)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              sliver: SliverToBoxAdapter(
                child: _SnapshotCard(
                  measurement: latest,
                ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.08),
              ),
            ),

          // History list
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
            sliver: measurementsAsync.when(
              loading: () => const SliverToBoxAdapter(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => SliverToBoxAdapter(
                child: Center(
                  child: Text('Error: $e',
                      style: TextStyle(color: t.danger)),
                ),
              ),
              data: (list) {
                if (list.isEmpty) {
                  return SliverToBoxAdapter(
                    child: _EmptyState(colors: t),
                  );
                }
                return SliverList.builder(
                  itemCount: list.length,
                  itemBuilder: (context, i) => _MeasurementRow(
                    measurement: list[i],
                    onDelete: () => ref
                        .read(bodyMeasurementProvider.notifier)
                        .delete(list[i].id),
                  )
                      .animate(delay: (i * 40).ms)
                      .fadeIn(duration: 250.ms)
                      .slideX(begin: -0.04),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  static Future<void> _showAddSheet(
    BuildContext context,
    WidgetRef ref,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddMeasurementSheet(ref: ref),
    );
  }
}

// ─── Snapshot Card ─────────────────────────────────────────────────────────

class _SnapshotCard extends StatelessWidget {
  const _SnapshotCard({
    required this.measurement,
  });
  final BodyMeasurement measurement;

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;
    final bmi = measurement.bmi;

    return GlassmorphicCard(
      borderRadius: 24,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: t.brand.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Latest',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: t.brand,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  DateFormat('MMM d, y').format(measurement.recordedAt),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: t.textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                if (measurement.weightKg != null)
                  _StatChip(
                    label: 'Weight',
                    value: '${measurement.weightKg!.toStringAsFixed(1)} kg',
                    color: t.brand,
                  ),
                if (bmi != null)
                  _StatChip(
                    label: 'BMI',
                    value: bmi.toStringAsFixed(1),
                    color: _bmiColor(bmi, t),
                    sub: measurement.bmiCategory,
                  ),
                if (measurement.bodyFatPercent != null)
                  _StatChip(
                    label: 'Body Fat',
                    value: '${measurement.bodyFatPercent!.toStringAsFixed(1)}%',
                    color: t.warning,
                  ),
                if (measurement.muscleMassKg != null)
                  _StatChip(
                    label: 'Muscle',
                    value:
                        '${measurement.muscleMassKg!.toStringAsFixed(1)} kg',
                    color: t.success,
                  ),
                if (measurement.waistCm != null)
                  _StatChip(
                    label: 'Waist',
                    value: '${measurement.waistCm!.toStringAsFixed(0)} cm',
                    color: t.info,
                  ),
                if (measurement.chestCm != null)
                  _StatChip(
                    label: 'Chest',
                    value: '${measurement.chestCm!.toStringAsFixed(0)} cm',
                    color: t.info,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static Color _bmiColor(double bmi, t) {
    if (bmi < 18.5) return t.info;
    if (bmi < 25) return t.success;
    if (bmi < 30) return t.warning;
    return t.danger;
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
    this.sub,
  });
  final String label;
  final String value;
  final Color color;
  final String? sub;

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: t.textMuted,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          if (sub != null)
            Text(
              sub!,
              style: GoogleFonts.inter(fontSize: 10, color: color),
            ),
        ],
      ),
    );
  }
}

// ─── History Row ────────────────────────────────────────────────────────────

class _MeasurementRow extends StatelessWidget {
  const _MeasurementRow({
    required this.measurement,
    required this.onDelete,
  });
  final BodyMeasurement measurement;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;
    return Dismissible(
      key: Key(measurement.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: t.danger.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(Icons.delete_outline_rounded, color: t.danger),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: t.border),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: t.brand.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.straighten_rounded, color: t.brand, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('MMM d, y – h:mm a')
                        .format(measurement.recordedAt),
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: t.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _summaryLine(),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: t.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _summaryLine() {
    final parts = <String>[];
    if (measurement.weightKg != null) {
      parts.add('${measurement.weightKg!.toStringAsFixed(1)} kg');
    }
    final bmi = measurement.bmi;
    if (bmi != null) parts.add('BMI ${bmi.toStringAsFixed(1)}');
    if (measurement.bodyFatPercent != null) {
      parts.add('${measurement.bodyFatPercent!.toStringAsFixed(0)}% fat');
    }
    return parts.isEmpty ? 'No data recorded' : parts.join(' · ');
  }
}

// ─── Empty State ─────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.colors});
  final FitNexoraThemeTokens colors;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          const Text('📏', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          Text(
            'No measurements yet',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the button below to log your first\nbody measurement.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 14, color: colors.textMuted),
          ),
        ],
      ),
    );
  }
}

// ─── Add Sheet ────────────────────────────────────────────────────────────────

class _AddMeasurementSheet extends StatefulWidget {
  const _AddMeasurementSheet({required this.ref});
  final WidgetRef ref;

  @override
  State<_AddMeasurementSheet> createState() => _AddMeasurementSheetState();
}

class _AddMeasurementSheetState extends State<_AddMeasurementSheet> {
  final _weight = TextEditingController();
  final _height = TextEditingController();
  final _fat = TextEditingController();
  final _muscle = TextEditingController();
  final _waist = TextEditingController();
  final _chest = TextEditingController();
  final _arm = TextEditingController();
  final _thigh = TextEditingController();
  final _hip = TextEditingController();
  final _notes = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    for (final c in [
      _weight, _height, _fat, _muscle, _waist, _chest, _arm, _thigh, _hip, _notes
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      expand: false,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: t.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(
                'Log Measurement',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: t.textPrimary,
                ),
              ),
            ),
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                children: [
                  _buildSection('Weight & Height', [
                    _NumField(ctrl: _weight, label: 'Weight (kg)', hint: '75.0'),
                    _NumField(ctrl: _height, label: 'Height (cm)', hint: '175'),
                  ]),
                  const SizedBox(height: 16),
                  _buildSection('Composition', [
                    _NumField(ctrl: _fat, label: 'Body Fat %', hint: '18.5'),
                    _NumField(ctrl: _muscle, label: 'Muscle Mass (kg)', hint: '35.0'),
                  ]),
                  const SizedBox(height: 16),
                  _buildSection('Circumferences (cm)', [
                    _NumField(ctrl: _waist, label: 'Waist', hint: '82'),
                    _NumField(ctrl: _chest, label: 'Chest', hint: '100'),
                    _NumField(ctrl: _arm, label: 'Arm', hint: '36'),
                    _NumField(ctrl: _thigh, label: 'Thigh', hint: '58'),
                    _NumField(ctrl: _hip, label: 'Hip', hint: '95'),
                  ]),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _notes,
                    style: TextStyle(color: t.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Notes (optional)',
                      hintText: 'How you feel today…',
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _saving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(56),
                    ),
                    child: _saving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Save Measurement',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> fields) {
    final t = context.fitTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: t.textMuted,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: fields,
        ),
      ],
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await widget.ref.read(bodyMeasurementProvider.notifier).add(
            weightKg: double.tryParse(_weight.text),
            heightCm: double.tryParse(_height.text),
            bodyFatPercent: double.tryParse(_fat.text),
            muscleMassKg: double.tryParse(_muscle.text),
            waistCm: double.tryParse(_waist.text),
            chestCm: double.tryParse(_chest.text),
            armCm: double.tryParse(_arm.text),
            thighCm: double.tryParse(_thigh.text),
            hipCm: double.tryParse(_hip.text),
            notes: _notes.text.isEmpty ? null : _notes.text,
          );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        context.showSnackBar('Failed to save: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _NumField extends StatelessWidget {
  const _NumField({
    required this.ctrl,
    required this.label,
    required this.hint,
  });
  final TextEditingController ctrl;
  final String label;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      child: TextField(
        controller: ctrl,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
        ],
        decoration: InputDecoration(labelText: label, hintText: hint),
      ),
    );
  }
}
