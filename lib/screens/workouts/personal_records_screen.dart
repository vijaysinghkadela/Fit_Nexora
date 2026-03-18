// lib/screens/workouts/personal_records_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../config/theme.dart';
import '../../core/extensions.dart';
import '../../models/personal_record_model.dart';
import '../../providers/personal_records_provider.dart';
import '../../widgets/glassmorphic_card.dart';

class PersonalRecordsScreen extends ConsumerWidget {
  const PersonalRecordsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.fitTheme;
    final bests = ref.watch(prBestsProvider);
    final allAsync = ref.watch(personalRecordsProvider);

    return Scaffold(
      backgroundColor: t.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddSheet(context, ref),
        backgroundColor: t.brand,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text(
          'Log PR',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            backgroundColor: t.surface,
            title: Text(
              'Personal Records',
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

          // Bests hall of fame
          if (bests.isNotEmpty) ...[
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              sliver: SliverToBoxAdapter(
                child: Text(
                  'HALL OF FAME',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: t.textMuted,
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              sliver: SliverToBoxAdapter(
                child: SizedBox(
                  height: 130,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: bests.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, i) => _PRBestCard(record: bests[i])
                        .animate(delay: (i * 60).ms)
                        .fadeIn(duration: 300.ms)
                        .slideX(begin: 0.06),
                  ),
                ),
              ),
            ),
          ],

          // All records
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            sliver: SliverToBoxAdapter(
              child: Text(
                'ALL RECORDS',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: t.textMuted,
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 120),
            sliver: allAsync.when(
              loading: () => const SliverToBoxAdapter(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => SliverToBoxAdapter(
                child: Text('Error: $e',
                    style: TextStyle(color: t.danger)),
              ),
              data: (list) {
                if (list.isEmpty) {
                  return SliverToBoxAdapter(
                    child: _EmptyPR(colors: t),
                  );
                }
                return SliverList.builder(
                  itemCount: list.length,
                  itemBuilder: (context, i) => Dismissible(
                    key: Key(list[i].id),
                    direction: DismissDirection.endToStart,
                    onDismissed: (_) => ref
                        .read(personalRecordsProvider.notifier)
                        .delete(list[i].id),
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: t.danger.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(Icons.delete_outline_rounded,
                          color: t.danger),
                    ),
                    child: _PRRow(record: list[i])
                        .animate(delay: (i * 40).ms)
                        .fadeIn(duration: 250.ms),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  static Future<void> _showAddSheet(
      BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddPRSheet(ref: ref),
    );
  }
}

// ─── Hall of Fame Card ───────────────────────────────────────────────────────

class _PRBestCard extends StatelessWidget {
  const _PRBestCard({required this.record});
  final PersonalRecord record;

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;
    return GlassmorphicCard(
      borderRadius: 20,
      child: SizedBox(
        width: 140,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.emoji_events_rounded,
                      color: const Color(0xFFF6B546), size: 18),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: t.brand.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${record.reps} rep',
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: t.brand,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                record.exerciseName,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: t.textPrimary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              Text(
                record.displayWeight,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: t.brand,
                ),
              ),
              Text(
                '1RM ~${record.estimatedOneRepMax.toStringAsFixed(0)} kg',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: t.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── PR Row ──────────────────────────────────────────────────────────────────

class _PRRow extends StatelessWidget {
  const _PRRow({required this.record});
  final PersonalRecord record;

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;
    return Container(
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
            child: Icon(Icons.fitness_center_rounded,
                color: t.brand, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.exerciseName,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: t.textPrimary,
                  ),
                ),
                Text(
                  '${record.reps} × ${record.displayWeight}  ·  ${DateFormat('MMM d, y').format(record.achievedAt)}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: t.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '~${record.estimatedOneRepMax.toStringAsFixed(0)} kg',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: t.brand,
                ),
              ),
              Text(
                'est. 1RM',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: t.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Empty State ─────────────────────────────────────────────────────────────

class _EmptyPR extends StatelessWidget {
  const _EmptyPR({required this.colors});
  final FitNexoraThemeTokens colors;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          const Text('🏆', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          Text(
            'No PRs logged yet',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Track your personal bests for\nevery exercise.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
                fontSize: 14, color: colors.textMuted),
          ),
        ],
      ),
    );
  }
}

// ─── Add PR Sheet ─────────────────────────────────────────────────────────────

class _AddPRSheet extends StatefulWidget {
  const _AddPRSheet({required this.ref});
  final WidgetRef ref;

  @override
  State<_AddPRSheet> createState() => _AddPRSheetState();
}

class _AddPRSheetState extends State<_AddPRSheet> {
  final _exerciseCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _repsCtrl = TextEditingController(text: '1');
  final _notesCtrl = TextEditingController();
  bool _saving = false;

  static const _popularExercises = [
    'Bench Press', 'Squat', 'Deadlift', 'Overhead Press',
    'Barbell Row', 'Pull-up', 'Dip', 'Romanian Deadlift',
  ];

  @override
  void dispose() {
    _exerciseCtrl.dispose();
    _weightCtrl.dispose();
    _repsCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.92,
      expand: false,
      builder: (_, ctrl) => Container(
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: t.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(
                'Log Personal Record',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: t.textPrimary,
                ),
              ),
            ),
            Expanded(
              child: ListView(
                controller: ctrl,
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                children: [
                  // Exercise chips
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: _popularExercises.map((e) {
                      final selected = _exerciseCtrl.text == e;
                      return ChoiceChip(
                        label: Text(e),
                        selected: selected,
                        onSelected: (_) {
                          setState(() => _exerciseCtrl.text = e);
                        },
                        selectedColor: t.brand,
                        labelStyle: GoogleFonts.inter(
                          color: selected ? Colors.white : t.textSecondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                        backgroundColor: t.surfaceAlt,
                        side: BorderSide(
                          color: selected ? t.brand : t.border,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _exerciseCtrl,
                    style: TextStyle(color: t.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Exercise name',
                      hintText: 'Or type a custom exercise',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _weightCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                          style: TextStyle(color: t.textPrimary),
                          decoration: const InputDecoration(
                            labelText: 'Weight (kg)',
                            hintText: '100.0',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _repsCtrl,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          style: TextStyle(color: t.textPrimary),
                          decoration: const InputDecoration(
                            labelText: 'Reps',
                            hintText: '1',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _notesCtrl,
                    style: TextStyle(color: t.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Notes (optional)',
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _saving ? null : _save,
                    style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(56)),
                    child: _saving
                        ? const SizedBox(
                            height: 20, width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : Text('Save PR',
                            style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final exercise = _exerciseCtrl.text.trim();
    final weight = double.tryParse(_weightCtrl.text);
    final reps = int.tryParse(_repsCtrl.text) ?? 1;

    if (exercise.isEmpty || weight == null) {
      context.showSnackBar('Enter exercise name and weight.', isError: true);
      return;
    }

    setState(() => _saving = true);
    try {
      await widget.ref.read(personalRecordsProvider.notifier).add(
            exerciseName: exercise,
            weightKg: weight,
            reps: reps,
            notes: _notesCtrl.text.isEmpty ? null : _notesCtrl.text,
          );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) context.showSnackBar('Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
