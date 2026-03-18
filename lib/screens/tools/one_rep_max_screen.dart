// lib/screens/tools/one_rep_max_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/theme.dart';
import '../../core/extensions.dart';
import '../../widgets/glassmorphic_card.dart';

class OneRepMaxScreen extends ConsumerStatefulWidget {
  const OneRepMaxScreen({super.key});

  @override
  ConsumerState<OneRepMaxScreen> createState() => _OneRepMaxScreenState();
}

class _OneRepMaxScreenState extends ConsumerState<OneRepMaxScreen> {
  final _weightCtrl = TextEditingController();
  final _repsCtrl = TextEditingController();
  _OneRMResult? _result;

  @override
  void dispose() {
    _weightCtrl.dispose();
    _repsCtrl.dispose();
    super.dispose();
  }

  void _calculate() {
    final w = double.tryParse(_weightCtrl.text);
    final r = int.tryParse(_repsCtrl.text);
    if (w == null || r == null || r <= 0) {
      context.showSnackBar('Enter valid weight and reps.', isError: true);
      return;
    }
    setState(() => _result = _OneRMResult.calculate(w, r));
  }

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;

    return Scaffold(
      backgroundColor: t.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            backgroundColor: t.surface,
            title: Text(
              '1RM Calculator',
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

          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverToBoxAdapter(
              child: Column(
                children: [
                  // Input card
                  GlassmorphicCard(
                    borderRadius: 24,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Text(
                            'One Rep Max Estimator',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: t.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Enter the weight you lifted and the reps completed',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: t.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _weightCtrl,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                                  decoration: const InputDecoration(
                                    labelText: 'Weight (kg)',
                                    hintText: '80',
                                    prefixIcon: Icon(Icons.fitness_center_rounded),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: _repsCtrl,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                  decoration: const InputDecoration(
                                    labelText: 'Reps',
                                    hintText: '5',
                                    prefixIcon: Icon(Icons.repeat_rounded),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: _calculate,
                            style: ElevatedButton.styleFrom(
                                minimumSize: const Size.fromHeight(52)),
                            child: Text(
                              'Calculate 1RM',
                              style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (_result != null) ...[
                    const SizedBox(height: 24),

                    // Hero result
                    GlassmorphicCard(
                      borderRadius: 24,
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Text(
                              '🏆 Estimated 1RM',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: t.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${_result!.epley.toStringAsFixed(1)} kg',
                              style: GoogleFonts.inter(
                                fontSize: 48,
                                fontWeight: FontWeight.w900,
                                color: t.brand,
                              ),
                            ),
                            Text(
                              '(Epley formula)',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: t.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ).animate().fadeIn(duration: 350.ms).scale(begin: const Offset(0.9, 0.9)),

                    const SizedBox(height: 16),

                    // Percentage table
                    GlassmorphicCard(
                      borderRadius: 20,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'PERCENTAGE TABLE',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.1,
                                color: t.textMuted,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ..._result!.percentages.entries.map(
                              (e) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 52,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: t.brand.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '${e.key}%',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: t.brand,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(999),
                                        child: LinearProgressIndicator(
                                          value: e.key / 100.0,
                                          minHeight: 6,
                                          backgroundColor: t.ringTrack,
                                          valueColor: AlwaysStoppedAnimation<Color>(t.brand),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      '${e.value.toStringAsFixed(1)} kg',
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: t.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ).animate(delay: 100.ms).fadeIn(duration: 300.ms),

                    const SizedBox(height: 16),

                    // Multiple formulas comparison
                    GlassmorphicCard(
                      borderRadius: 20,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'FORMULA COMPARISON',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.1,
                                color: t.textMuted,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _formulaRow('Epley', _result!.epley, t),
                            _formulaRow('Brzycki', _result!.brzycki, t),
                            _formulaRow('Lombardi', _result!.lombardi, t),
                            _formulaRow('Mayhew', _result!.mayhew, t),
                          ],
                        ),
                      ),
                    ).animate(delay: 150.ms).fadeIn(duration: 300.ms),
                  ],

                  const SizedBox(height: 60),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Widget _formulaRow(String name, double value, FitNexoraThemeTokens t) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              name,
              style: GoogleFonts.inter(
                  fontSize: 13, color: t.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              '${value.toStringAsFixed(1)} kg',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: t.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );

class _OneRMResult {
  final double epley;
  final double brzycki;
  final double lombardi;
  final double mayhew;

  const _OneRMResult({
    required this.epley,
    required this.brzycki,
    required this.lombardi,
    required this.mayhew,
  });

  factory _OneRMResult.calculate(double weight, int reps) {
    if (reps == 1) {
      return _OneRMResult(
          epley: weight,
          brzycki: weight,
          lombardi: weight,
          mayhew: weight);
    }
    return _OneRMResult(
      epley: weight * (1 + reps / 30.0),
      brzycki: weight * (36.0 / (37.0 - reps)),
      lombardi: weight * (reps.toDouble()).ceilToDouble() * 0.10 + weight,
      mayhew: (100 * weight) / (52.2 + 41.9 * (2.71828 * (-0.055 * reps))),
    );
  }

  Map<int, double> get percentages {
    final pcts = [100, 95, 90, 85, 80, 75, 70, 65, 60];
    return {for (final p in pcts) p: epley * p / 100.0};
  }
}
