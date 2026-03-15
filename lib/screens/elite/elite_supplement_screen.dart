import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/elite_member_provider.dart';
import '../../widgets/glassmorphic_card.dart';


/// Elite: Supplement Tracker — log supplements with dose, timing, and AI tips.
class EliteSupplementScreen extends ConsumerStatefulWidget {
  const EliteSupplementScreen({super.key});
  @override
  ConsumerState<EliteSupplementScreen> createState() =>
      _EliteSupplementScreenState();
}

class _EliteSupplementScreenState
    extends ConsumerState<EliteSupplementScreen> {
  final _nameCtrl = TextEditingController();
  final _doseCtrl = TextEditingController();
  String _timing = 'Pre-workout';
  bool _saving = false;

  final _timings = [
    'Pre-workout', 'Post-workout', 'Morning', 'Evening',
    'Lunch', 'Before sleep',
  ];

  // Common supplement presets with AI-backed timing
  final _presets = [
    ('Creatine', '5000', 'Post-workout', '💪'),
    ('Whey Protein', '30000', 'Post-workout', '🥛'),
    ('Vitamin D3', '2000', 'Morning', '☀️'),
    ('Omega-3', '1000', 'Morning', '🐟'),
    ('Magnesium', '400', 'Before sleep', '💤'),
    ('Caffeine', '200', 'Pre-workout', '⚡'),
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _doseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final logsAsync = ref.watch(eliteSupplementsProvider);

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.bgDark,
        leading: BackButton(color: AppColors.textSecondary),
        title: Text('Supplement Tracker',
            style: GoogleFonts.inter(
                fontSize: 20, fontWeight: FontWeight.w800,
                color: AppColors.textPrimary)),
        actions: [
          TextButton.icon(
            onPressed: () => _showLogSheet(context),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Log'),
            style: TextButton.styleFrom(foregroundColor: AppColors.accent),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // Today's logs
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            sliver: SliverToBoxAdapter(
              child: Text("TODAY'S LOG",
                  style: GoogleFonts.inter(
                      fontSize: 11, fontWeight: FontWeight.w700,
                      color: AppColors.textMuted, letterSpacing: 1.2)),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
            sliver: SliverToBoxAdapter(
              child: logsAsync.when(
                loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.primary)),
                error: (e, _) => Text('$e',
                    style: GoogleFonts.inter(color: AppColors.error)),
                data: (logs) => logs.isEmpty
                    ? GlassmorphicCard(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(children: [
                            const Icon(Icons.medication_rounded,
                                size: 40, color: AppColors.textMuted),
                            const SizedBox(height: 12),
                            Text('No supplements logged today',
                                style: GoogleFonts.inter(
                                    color: AppColors.textSecondary,
                                    fontSize: 14)),
                          ]),
                        ),
                      )
                    : GlassmorphicCard(
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            children: logs.asMap().entries.map((entry) {
                              final i = entry.key;
                              final s = entry.value;
                              return Column(children: [
                                ListTile(
                                  leading: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppColors.accent
                                          .withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.medication_rounded,
                                        color: AppColors.accent, size: 20),
                                  ),
                                  title: Text(
                                    s['supplement_name'] as String? ?? '',
                                    style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary),
                                  ),
                                  subtitle: Text(
                                    '${s['dose_mg'] ?? ''}mg · ${s['timing'] ?? ''}',
                                    style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: AppColors.textSecondary),
                                  ),
                                  trailing: const Icon(
                                      Icons.check_circle_rounded,
                                      color: AppColors.success),
                                ),
                                if (i < logs.length - 1)
                                  const Divider(
                                      color: AppColors.divider, height: 1),
                              ]);
                            }).toList(),
                          ),
                        ),
                      ).animate().fadeIn(),
              ),
            ),
          ),

          // Quick presets
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
            sliver: SliverToBoxAdapter(
              child: Text('COMMON SUPPLEMENTS',
                  style: GoogleFonts.inter(
                      fontSize: 11, fontWeight: FontWeight.w700,
                      color: AppColors.textMuted, letterSpacing: 1.2)),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
            sliver: SliverToBoxAdapter(
              child: GlassmorphicCard(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    children: _presets.asMap().entries.map((entry) {
                      final i = entry.key;
                      final (name, dose, timing, emoji) = entry.value;
                      return Column(children: [
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          leading: Text(emoji,
                              style: const TextStyle(fontSize: 24)),
                          title: Text(name,
                              style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary)),
                          subtitle: Text('$timing · ${int.parse(dose) >= 1000 ? '${(int.parse(dose) / 1000).toStringAsFixed(0)}g' : '${dose}mg'}',
                              style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: AppColors.textSecondary)),
                          trailing: GestureDetector(
                            onTap: () => _quickLog(name, dose, timing),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.accent.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: AppColors.accent.withValues(alpha: 0.3)),
                              ),
                              child: Text('+ Log',
                                  style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.accent)),
                            ),
                          ),
                        ),
                        if (i < _presets.length - 1)
                          const Divider(color: AppColors.divider, height: 1),
                      ]);
                    }).toList(),
                  ),
                ),
              ).animate(delay: 100.ms).fadeIn(),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _quickLog(String name, String dose, String timing) async {
    final user = ref.read(currentUserProvider).value;
    if (user == null) return;
    final db = ref.read(databaseServiceProvider);
    await db.addSupplementLog({
      'user_id': user.id,
      'supplement_name': name,
      'dose_mg': double.parse(dose),
      'timing': timing,
    });
    ref.invalidate(eliteSupplementsProvider);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('$name logged!'),
          backgroundColor: AppColors.success));
    }
  }

  void _showLogSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
            left: 24, right: 24, top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: AppColors.textMuted.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2)),
            )),
            const SizedBox(height: 20),
            Text('Log Supplement',
                style: GoogleFonts.inter(
                    fontSize: 20, fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 16),
            _field(_nameCtrl, 'Supplement name', TextInputType.text),
            const SizedBox(height: 10),
            _field(_doseCtrl, 'Dose (mg)', TextInputType.number),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _timings.map((t) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(t,
                        style: GoogleFonts.inter(
                            fontSize: 12,
                            color: t == _timing
                                ? Colors.white
                                : AppColors.textSecondary)),
                    selected: t == _timing,
                    selectedColor: AppColors.accent,
                    backgroundColor: AppColors.bgCard,
                    onSelected: (_) => setState(() => _timing = t),
                  ),
                )).toList(),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity, height: 52,
              child: FilledButton(
                onPressed: _saving ? null : () => _saveLog(context),
                style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14))),
                child: Text('Save Supplement',
                    style: GoogleFonts.inter(
                        fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String hint, TextInputType type) {
    return TextFormField(
      controller: c, keyboardType: type,
      style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 13),
        filled: true, fillColor: AppColors.bgInput,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.accent, width: 2)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border)),
      ),
    );
  }

  Future<void> _saveLog(BuildContext context) async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    final dose = double.tryParse(_doseCtrl.text) ?? 0;
    final user = ref.read(currentUserProvider).value;
    if (user == null) return;

    setState(() => _saving = true);
    try {
      final db = ref.read(databaseServiceProvider);
      await db.addSupplementLog({
        'user_id': user.id,
        'supplement_name': name,
        'dose_mg': dose,
        'timing': _timing,
      });
      ref.invalidate(eliteSupplementsProvider);
      _nameCtrl.clear(); _doseCtrl.clear();
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Supplement logged!'),
            backgroundColor: AppColors.success));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
