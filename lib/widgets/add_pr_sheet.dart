import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/extensions.dart';
import '../providers/personal_records_provider.dart';

class AddPRSheet extends StatefulWidget {
  const AddPRSheet({super.key, this.initialExercise, this.initialWeight, this.initialReps});

  final String? initialExercise;
  final double? initialWeight;
  final int? initialReps;

  static Future<void> show(BuildContext context, {String? exercise, double? weight, int? reps}) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddPRSheet(
        initialExercise: exercise,
        initialWeight: weight,
        initialReps: reps,
      ),
    );
  }

  @override
  State<AddPRSheet> createState() => _AddPRSheetState();
}

class _AddPRSheetState extends State<AddPRSheet> {
  late final TextEditingController _exerciseCtrl;
  late final TextEditingController _weightCtrl;
  late final TextEditingController _repsCtrl;
  final _notesCtrl = TextEditingController();

  final _weightFocus = FocusNode();
  final _repsFocus = FocusNode();
  final _notesFocus = FocusNode();

  bool _saving = false;

  static const _popularExercises = [
    'Bench Press', 'Squat', 'Deadlift', 'Overhead Press',
    'Barbell Row', 'Pull-up', 'Dip', 'Romanian Deadlift',
  ];

  @override
  void initState() {
    super.initState();
    _exerciseCtrl = TextEditingController(text: widget.initialExercise ?? '');
    _weightCtrl = TextEditingController(text: widget.initialWeight?.toString() ?? '');
    _repsCtrl = TextEditingController(text: widget.initialReps?.toString() ?? '1');
  }

  @override
  void dispose() {
    _exerciseCtrl.dispose();
    _weightCtrl.dispose();
    _repsCtrl.dispose();
    _notesCtrl.dispose();
    _weightFocus.dispose();
    _repsFocus.dispose();
    _notesFocus.dispose();
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
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
                    textInputAction: TextInputAction.next,
                    onSubmitted: (_) => FocusScope.of(context).requestFocus(_weightFocus),
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
                          focusNode: _weightFocus,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          textInputAction: TextInputAction.next,
                          onSubmitted: (_) => FocusScope.of(context).requestFocus(_repsFocus),
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
                          focusNode: _repsFocus,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.next,
                          onSubmitted: (_) => FocusScope.of(context).requestFocus(_notesFocus),
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
                    focusNode: _notesFocus,
                    style: TextStyle(color: t.textPrimary),
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(
                      labelText: 'Notes (optional)',
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 24),
                  Consumer(
                    builder: (context, ref, child) {
                      return ElevatedButton(
                        onPressed: _saving ? null : () => _save(ref),
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
                      );
                    }
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save(WidgetRef ref) async {
    final exercise = _exerciseCtrl.text.trim();
    final weight = double.tryParse(_weightCtrl.text);
    final reps = int.tryParse(_repsCtrl.text) ?? 1;

    if (exercise.isEmpty || weight == null) {
      context.showSnackBar('Enter exercise name and weight.', isError: true);
      return;
    }

    setState(() => _saving = true);
    try {
      await ref.read(personalRecordsProvider.notifier).add(
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
