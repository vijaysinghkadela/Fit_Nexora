import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import '../../core/constants.dart';
import '../../core/database_values.dart';
import '../../models/food_log_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/gym_provider.dart';
import '../../providers/nutrition_provider.dart';
import '../../providers/pro_member_provider.dart';
import '../../widgets/error_widgets.dart';
import '../../widgets/glassmorphic_card.dart';
import '../../widgets/loading_widgets.dart';

/// Pro Plan: Calories + Macro tracker with manual food log and barcode CTA.
class ProNutritionScreen extends ConsumerStatefulWidget {
  const ProNutritionScreen({super.key});

  @override
  ConsumerState<ProNutritionScreen> createState() =>
      _ProNutritionScreenState();
}

class _ProNutritionScreenState extends ConsumerState<ProNutritionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nutritionAsync = ref.watch(proTodayNutritionProvider);

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.bgDark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textSecondary),
          onPressed: () => context.pop(),
        ),
        title: Text('Nutrition Tracker',
            style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary)),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMuted,
          tabs: const [
            Tab(text: 'Today'),
            Tab(text: 'Log Food'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          // Tab 1: Today summary
          _TodaySummaryTab(nutritionAsync: nutritionAsync),
          // Tab 2: Log food
          const _LogFoodTab(),
        ],
      ),
    );
  }
}

// ─── Today Summary Tab ────────────────────────────────────────────────────────

class _TodaySummaryTab extends ConsumerWidget {
  final AsyncValue<NutritionSummary> nutritionAsync;
  const _TodaySummaryTab({required this.nutritionAsync});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).value;
    final pagedLogs =
        user != null ? ref.watch(pagedTodayFoodLogsProvider(user.id)) : null;
    return nutritionAsync.when(
      loading: () => ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          CardSkeleton(height: 190),
          SizedBox(height: 16),
          CardSkeleton(height: 110),
          SizedBox(height: 16),
          CardSkeleton(height: 140),
        ],
      ),
      error: (e, _) => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.6,
            child: ErrorStateWidget(
              message: 'Unable to load nutrition summary.',
              onRetry: () => ref.invalidate(proTodayNutritionProvider),
            ),
          ),
        ],
      ),
      data: (s) => RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(proTodayNutritionProvider);
          ref.invalidate(proTodayFoodLogsProvider);
          if (user != null) {
            ref.invalidate(pagedTodayFoodLogsProvider(user.id));
          }
          await ref.read(proTodayNutritionProvider.future);
        },
        backgroundColor: AppColors.bgElevated,
        color: AppColors.primary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
          // Calories ring top
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverToBoxAdapter(
              child: _BigCaloriesRing(summary: s),
            ),
          ),

          // Macro cards row
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  Expanded(
                      child: _MacroCard('Protein', s.protein,
                          DailyTargets.protein, 'g', AppColors.primary)),
                  const SizedBox(width: 10),
                  Expanded(
                      child: _MacroCard('Carbs', s.carbs,
                          DailyTargets.carbs, 'g', AppColors.accent)),
                  const SizedBox(width: 10),
                  Expanded(
                      child: _MacroCard('Fat', s.fat,
                          DailyTargets.fat, 'g', AppColors.warning)),
                ],
              ),
            ),
          ),

          // Extra nutrients
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            sliver: SliverToBoxAdapter(
              child: GlassmorphicCard(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Other Nutrients',
                          style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary)),
                      const SizedBox(height: 12),
                      _NutrientRow('Sugar', s.sugar, DailyTargets.sugar,
                          'g', AppColors.error),
                      _NutrientRow('Fiber', s.fiber, DailyTargets.fiber,
                          'g', AppColors.success),
                      _NutrientRow('Sodium', s.sodium,
                          DailyTargets.sodiumMg, 'mg', AppColors.info),
                    ],
                  ),
                ),
              ).animate(delay: 100.ms).fadeIn(),
            ),
          ),

          // Food log list
          if (s.logs.isNotEmpty) ...[
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              sliver: SliverToBoxAdapter(
                child: Text("TODAY'S FOODS",
                    style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMuted,
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
                      children: [
                        if (pagedLogs == null || pagedLogs.isInitialLoading)
                          ...List.generate(
                            3,
                            (_) => const Padding(
                              padding: EdgeInsets.only(bottom: 10),
                              child: SkeletonBox(height: 44, radius: 10),
                            ),
                          )
                        else if (pagedLogs.items.isEmpty && pagedLogs.hasError)
                          ErrorStateWidget(
                            compact: true,
                            message: 'Unable to load food logs.',
                            onRetry: () => ref
                                .read(pagedTodayFoodLogsProvider(user!.id).notifier)
                                .loadInitial(),
                          )
                        else
                          ...pagedLogs.items.asMap().entries.map((entry) {
                            final i = entry.key;
                            final log = entry.value;
                            return Column(
                              children: [
                                _FoodLogTile(log: log, ref: ref),
                                if (i < pagedLogs.items.length - 1)
                                  const Divider(
                                      color: AppColors.divider, height: 1),
                              ],
                            );
                          }),
                        if (pagedLogs != null)
                          LoadingFooter(
                            isLoading: pagedLogs.isLoadingMore,
                            hasMore: pagedLogs.hasMore,
                            error: pagedLogs.items.isNotEmpty ? pagedLogs.error : null,
                            onPressed: () => ref
                                .read(pagedTodayFoodLogsProvider(user!.id).notifier)
                                .loadMore(),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],

          const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
          ],
        ),
      ),
    );
  }
}

class _BigCaloriesRing extends StatelessWidget {
  final NutritionSummary summary;
  const _BigCaloriesRing({required this.summary});

  @override
  Widget build(BuildContext context) {
    final consumed = summary.calories;
    final target = DailyTargets.calories;
    final progress = (consumed / target).clamp(0.0, 1.0);
    final remaining = math.max(0.0, target - consumed);

    return Row(
      children: [
        SizedBox(
          width: 150,
          height: 150,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size(150, 150),
                painter: _ProRingPainter(progress: progress),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    consumed.toStringAsFixed(0),
                    style: GoogleFonts.inter(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary),
                  ),
                  Text('/ ${target.toStringAsFixed(0)} kcal',
                      style: GoogleFonts.inter(
                          fontSize: 11, color: AppColors.textMuted)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SummaryRow('Consumed', '${consumed.toStringAsFixed(0)} kcal',
                  AppColors.primary),
              const SizedBox(height: 8),
              _SummaryRow(
                  remaining == 0 ? 'Over by' : 'Remaining',
                  '${remaining == 0 ? (consumed - target).abs().toStringAsFixed(0) : remaining.toStringAsFixed(0)} kcal',
                  remaining == 0 ? AppColors.error : AppColors.success),
              const SizedBox(height: 8),
              _SummaryRow(
                  'Foods logged', '${summary.count} items', AppColors.info),
            ],
          ),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _SummaryRow(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: GoogleFonts.inter(
                fontSize: 12, color: AppColors.textSecondary)),
        Text(value,
            style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: color)),
      ],
    );
  }
}

class _MacroCard extends StatelessWidget {
  final String label;
  final double current;
  final double target;
  final String unit;
  final Color color;
  const _MacroCard(this.label, this.current, this.target, this.unit, this.color);

  @override
  Widget build(BuildContext context) {
    final pct = (current / target).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Column(
        children: [
          Text('${current.toStringAsFixed(0)}$unit',
              style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: color)),
          const SizedBox(height: 2),
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 11, color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: color.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 5,
            ),
          ),
          const SizedBox(height: 4),
          Text('/ ${target.toStringAsFixed(0)}$unit',
              style: GoogleFonts.inter(
                  fontSize: 9, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

class _NutrientRow extends StatelessWidget {
  final String label;
  final double current;
  final double target;
  final String unit;
  final Color color;
  const _NutrientRow(
      this.label, this.current, this.target, this.unit, this.color);

  @override
  Widget build(BuildContext context) {
    final pct = (current / target).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: GoogleFonts.inter(
                      fontSize: 13, color: AppColors.textSecondary)),
              Text(
                '${current.toStringAsFixed(0)} / ${target.toStringAsFixed(0)} $unit',
                style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color),
              ),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: color.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 5,
            ),
          ),
        ],
      ),
    );
  }
}

class _FoodLogTile extends StatelessWidget {
  final FoodLog log;
  final WidgetRef ref;
  const _FoodLogTile({required this.log, required this.ref});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      title: Text(log.productName,
          style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary)),
      subtitle: Text(
          '${log.mealType.toUpperCase()} · P:${log.proteinG.toStringAsFixed(0)}g  C:${log.carbsG.toStringAsFixed(0)}g  F:${log.fatG.toStringAsFixed(0)}g',
          style: GoogleFonts.inter(
              fontSize: 11, color: AppColors.textSecondary)),
      trailing: Text('${log.caloriesKcal.toStringAsFixed(0)} kcal',
          style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.primary)),
    );
  }
}

class _ProRingPainter extends CustomPainter {
  final double progress;
  _ProRingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 16) / 2;
    final bgPaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.12)
      ..strokeWidth = 12
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final fgPaint = Paint()
      ..shader = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: -math.pi / 2 + 2 * math.pi * progress,
        colors: [AppColors.primary.withValues(alpha: 0.5), AppColors.primary],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..strokeWidth = 12
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);
    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        fgPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ProRingPainter old) =>
      old.progress != progress;
}

// ─── Log Food Tab ─────────────────────────────────────────────────────────────

class _LogFoodTab extends ConsumerStatefulWidget {
  const _LogFoodTab();

  @override
  ConsumerState<_LogFoodTab> createState() => _LogFoodTabState();
}

class _LogFoodTabState extends ConsumerState<_LogFoodTab> {
  final _nameCtrl = TextEditingController();
  final _calCtrl = TextEditingController();
  final _protCtrl = TextEditingController();
  final _carbCtrl = TextEditingController();
  final _fatCtrl = TextEditingController();
  String _mealType = DatabaseValues.defaultManualMealType;
  bool _saving = false;

  final _meals = DatabaseValues.mealTypes;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _calCtrl.dispose();
    _protCtrl.dispose();
    _carbCtrl.dispose();
    _fatCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Barcode scanner CTA
          GlassmorphicCard(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [AppColors.accent, AppColors.primary]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.qr_code_scanner_rounded,
                    color: Colors.white, size: 22),
              ),
              title: Text('Scan Barcode',
                  style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
              subtitle: Text('Auto-fill nutrition from product barcode',
                  style: GoogleFonts.inter(
                      fontSize: 12, color: AppColors.textSecondary)),
              trailing: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: AppColors.accent.withValues(alpha: 0.3)),
                ),
                child: Text('SCAN',
                    style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.accent,
                        letterSpacing: 1)),
              ),
              onTap: () => _showBarcodeInfo(context),
            ),
          ).animate().fadeIn(),

          const SizedBox(height: 20),
          Text('OR ENTER MANUALLY',
              style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted,
                  letterSpacing: 1.2)),
          const SizedBox(height: 12),

          _field(_nameCtrl, 'Food name', TextInputType.text),
          const SizedBox(height: 10),

          // Meal type picker
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _meals.map((m) {
                final sel = m == _mealType;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(m[0].toUpperCase() + m.substring(1),
                        style: GoogleFonts.inter(
                            fontSize: 12,
                            color: sel
                                ? Colors.white
                                : AppColors.textSecondary,
                            fontWeight: FontWeight.w600)),
                    selected: sel,
                    selectedColor: AppColors.primary,
                    backgroundColor: AppColors.bgCard,
                    onSelected: (_) => setState(() => _mealType = m),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(child: _field(_calCtrl, 'Calories (kcal)',
                  TextInputType.number)),
              const SizedBox(width: 10),
              Expanded(child: _field(_protCtrl, 'Protein (g)',
                  TextInputType.number)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _field(_carbCtrl, 'Carbs (g)',
                  TextInputType.number)),
              const SizedBox(width: 10),
              Expanded(child: _field(_fatCtrl, 'Fat (g)',
                  TextInputType.number)),
            ],
          ),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              onPressed: _saving ? null : _saveLog,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.add_circle_rounded),
              label: Text('Log Food',
                  style: GoogleFonts.inter(
                      fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(TextEditingController c, String hint, TextInputType type) {
    return TextFormField(
      controller: c,
      keyboardType: type,
      style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 13),
        filled: true,
        fillColor: AppColors.bgCard,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
      ),
    );
  }

  Future<void> _saveLog() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    final cal = double.tryParse(_calCtrl.text) ?? 0;
    final prot = double.tryParse(_protCtrl.text) ?? 0;
    final carb = double.tryParse(_carbCtrl.text) ?? 0;
    final fat = double.tryParse(_fatCtrl.text) ?? 0;

    final user = ref.read(currentUserProvider).value;
    final gym = ref.read(selectedGymProvider);
    if (user == null) return;

    setState(() => _saving = true);
    try {
      final db = ref.read(databaseServiceProvider);
      await db.logFood(FoodLog(
        id: '',
        userId: user.id,
        gymId: gym?.id,
        productName: name,
        caloriesKcal: cal,
        proteinG: prot,
        fatG: fat,
        carbsG: carb,
        sugarG: 0,
        fiberG: 0,
        sodiumMg: 0,
        servingSizeG: 100,
        quantity: 1,
        mealType: _mealType,
        loggedAt: DateTime.now(),
      ));

      ref.invalidate(proTodayFoodLogsProvider);
      ref.invalidate(proTodayNutritionProvider);
      ref.invalidate(pagedTodayFoodLogsProvider(user.id));

      if (mounted) {
        _nameCtrl.clear();
        _calCtrl.clear();
        _protCtrl.clear();
        _carbCtrl.clear();
        _fatCtrl.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Food logged!'),
              backgroundColor: AppColors.success),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showBarcodeInfo(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textMuted.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Icon(Icons.qr_code_scanner_rounded,
                size: 48, color: AppColors.accent),
            const SizedBox(height: 16),
            Text('Barcode Scanner',
                style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            Text(
              'To enable the barcode scanner, add the flutter_barcode_scanner package to your pubspec.yaml and connect it to the OpenFoodFacts API for nutrition lookup.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.5),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.bgElevated,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '# pubspec.yaml\nflutter_barcode_scanner: ^2.0.0\nhttp: ^1.0.0  # For OpenFoodFacts API',
                style: GoogleFonts.sourceCodePro(
                    fontSize: 12, color: AppColors.accent),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
