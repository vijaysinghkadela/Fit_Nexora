import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/chart_buckets.dart';
import '../../core/constants.dart';
import '../../core/database_values.dart';
import '../../models/food_log_model.dart';
import '../../models/food_product_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/gym_provider.dart';
import '../../providers/nutrition_provider.dart';
import '../../widgets/error_widgets.dart';
import '../../widgets/glassmorphic_card.dart';
import '../../widgets/loading_widgets.dart';
import '../../core/responsive.dart';

class NutritionScreen extends ConsumerStatefulWidget {
  const NutritionScreen({super.key});

  @override
  ConsumerState<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends ConsumerState<NutritionScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

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
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.bgDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded,
              color: AppColors.textSecondary, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Nutrition',
          style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary),
        ),
        bottom: TabBar(
          controller: _tabs,
          labelColor: AppColors.accent,
          unselectedLabelColor: AppColors.textMuted,
          indicatorColor: AppColors.accent,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle:
              GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'Scan & Log'),
            Tab(text: 'Reports'),
          ],
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabs,
          children: const [
            _ScanTab(),
            _ReportsTab(),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SCAN & LOG TAB
// ═══════════════════════════════════════════════════════════════════════════

class _ScanTab extends ConsumerStatefulWidget {
  const _ScanTab();

  @override
  ConsumerState<_ScanTab> createState() => _ScanTabState();
}

class _ScanTabState extends ConsumerState<_ScanTab> {
  final _barcodeCtrl = TextEditingController();
  FoodProduct? _product;
  bool _searching = false;
  String? _searchError;

  final _servingCtrl = TextEditingController();
  double _quantity = 1;
  String _mealType = DatabaseValues.defaultMealType;
  bool _logging = false;

  @override
  void dispose() {
    _barcodeCtrl.dispose();
    _servingCtrl.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final barcode = _barcodeCtrl.text.trim();
    if (barcode.isEmpty) return;
    setState(() {
      _searching = true;
      _searchError = null;
      _product = null;
    });
    final svc = ref.read(foodServiceProvider);
    final result = await svc.getProductByBarcode(barcode);
    if (!mounted) return;
    if (result == null) {
      setState(() {
        _searching = false;
        _searchError = 'Product not found. Try a different barcode.';
      });
    } else {
      _servingCtrl.text = result.defaultServingSizeG.toStringAsFixed(0);
      setState(() {
        _searching = false;
        _product = result;
      });
    }
  }

  Future<void> _logFood() async {
    final p = _product;
    if (p == null) return;
    final user = ref.read(currentUserProvider).value;
    final gym = ref.read(selectedGymProvider);
    if (user == null) return;

    final servingG =
        double.tryParse(_servingCtrl.text) ?? p.defaultServingSizeG;
    final nutrients = p.nutrientsForServing(servingG, _quantity);

    setState(() => _logging = true);
    try {
      final db = ref.read(databaseServiceProvider);
      await db.logFood(FoodLog(
        id: '',
        userId: user.id,
        gymId: gym?.id,
        barcode: p.barcode,
        productName: p.name,
        brand: p.brand,
        caloriesKcal: nutrients['calories']!,
        proteinG: nutrients['protein']!,
        fatG: nutrients['fat']!,
        carbsG: nutrients['carbs']!,
        sugarG: nutrients['sugar']!,
        fiberG: nutrients['fiber']!,
        sodiumMg: nutrients['sodium']!,
        servingSizeG: servingG,
        quantity: _quantity,
        mealType: _mealType,
        loggedAt: DateTime.now(),
      ));
      ref.invalidate(todayFoodLogsProvider(user.id));
      ref.invalidate(pagedTodayFoodLogsProvider(user.id));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${p.name} logged!',
              style: GoogleFonts.inter(color: Colors.black)),
          backgroundColor: AppColors.accent,
          duration: const Duration(seconds: 2),
        ));
        setState(() {
          _product = null;
          _barcodeCtrl.clear();
          _quantity = 1;
          _mealType = DatabaseValues.defaultMealType;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to log: $e'),
          backgroundColor: AppColors.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _logging = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).value;
    return RefreshIndicator(
      onRefresh: () async {
        if (user == null) return;
        ref.invalidate(todayFoodLogsProvider(user.id));
        ref.invalidate(pagedTodayFoodLogsProvider(user.id));
        await Future.wait([
          ref.read(todayFoodLogsProvider(user.id).future),
        ]);
      },
      backgroundColor: AppColors.bgElevated,
      color: AppColors.primary,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          _BarcodeSearchCard(
            controller: _barcodeCtrl,
            searching: _searching,
            error: _searchError,
            onSearch: _search,
          ),
          if (_product != null) ...[
            const SizedBox(height: 16),
            _ProductCard(product: _product!),
            const SizedBox(height: 12),
            _LogFormCard(
              product: _product!,
              servingCtrl: _servingCtrl,
              quantity: _quantity,
              mealType: _mealType,
              logging: _logging,
              onQuantityChanged: (v) => setState(() => _quantity = v),
              onMealTypeChanged: (v) => setState(() => _mealType = v),
              onLog: _logFood,
            ),
          ],
          const SizedBox(height: 20),
          if (user != null) _TodayLogSection(userId: user.id),
        ],
      ),
    );
  }
}

// ─── Barcode search ───────────────────────────────────────────────────────────

class _BarcodeSearchCard extends StatelessWidget {
  final TextEditingController controller;
  final bool searching;
  final String? error;
  final VoidCallback onSearch;

  const _BarcodeSearchCard({
    required this.controller,
    required this.searching,
    required this.error,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    final rs = ResponsiveSize.of(context);
    return GlassmorphicCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.qr_code_scanner_rounded,
                  color: AppColors.accent, size: 20),
              const SizedBox(width: 8),
              Text('Scan Product Barcode',
                  style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
            ]),
            const SizedBox(height: 4),
            Text('Enter the barcode number printed on the product',
                style: GoogleFonts.inter(
                    fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.inter(color: AppColors.textPrimary),
                  onSubmitted: (_) => onSearch(),
                  decoration: InputDecoration(
                    hintText: 'e.g. 5449000000996',
                    hintStyle: GoogleFonts.inter(
                        color: AppColors.textMuted.withValues(alpha: 0.5)),
                    filled: true,
                    fillColor: AppColors.bgInput,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 14),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: AppColors.border)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                            color:
                                AppColors.border.withValues(alpha: 0.5))),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: AppColors.accent, width: 1.5)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: rs.sp(48),
                width: rs.sp(48),
                child: ElevatedButton(
                  onPressed: searching ? null : onSearch,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: EdgeInsets.zero,
                  ),
                  child: searching
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.black))
                      : const Icon(Icons.search_rounded, size: 22),
                ),
              ),
            ]),
            if (error != null) ...[
              const SizedBox(height: 10),
              Text(error!,
                  style: GoogleFonts.inter(
                      fontSize: 13, color: AppColors.error)),
            ],
          ],
        ),
      ),
    ).animate().fadeIn().slideY(begin: 0.1, end: 0);
  }
}

// ─── Product card ─────────────────────────────────────────────────────────────

class _ProductCard extends StatelessWidget {
  final FoodProduct product;
  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return GlassmorphicCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.name,
                        style: GoogleFonts.inter(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary)),
                    if (product.brand != null)
                      Text(product.brand!,
                          style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppColors.textSecondary)),
                  ],
                ),
              ),
              if (product.nutriscoreGrade != null)
                _NutriScore(grade: product.nutriscoreGrade!),
            ]),
            const SizedBox(height: 16),
            // Macros grid
            Row(children: [
              _MacroCell('Calories',
                  product.caloriesPer100g.toStringAsFixed(0), 'kcal',
                  AppColors.warning),
              _MacroCell('Protein',
                  product.proteinPer100g.toStringAsFixed(1), 'g',
                  AppColors.accent),
              _MacroCell('Fat',
                  product.fatPer100g.toStringAsFixed(1), 'g',
                  AppColors.error),
              _MacroCell('Carbs',
                  product.carbsPer100g.toStringAsFixed(1), 'g',
                  AppColors.primary),
            ]),
            const SizedBox(height: 4),
            Text('per 100 g',
                style: GoogleFonts.inter(
                    fontSize: 11, color: AppColors.textMuted)),
            const SizedBox(height: 16),
            // Ingredient alerts
            Text('Ingredient Analysis',
                style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 10),
            ...product.alerts.map((a) => _AlertRow(alert: a)),
          ],
        ),
      ),
    ).animate(delay: 100.ms).fadeIn().slideY(begin: 0.1, end: 0);
  }
}

class _MacroCell extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color color;
  const _MacroCell(this.label, this.value, this.unit, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border:
              Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(children: [
          Text(value,
              style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: color)),
          Text(unit,
              style:
                  GoogleFonts.inter(fontSize: 10, color: color)),
          const SizedBox(height: 2),
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 10, color: AppColors.textMuted)),
        ]),
      ),
    );
  }
}

class _AlertRow extends StatelessWidget {
  final NutrientAlert alert;
  const _AlertRow({required this.alert});

  @override
  Widget build(BuildContext context) {
    final c = alert.level.color;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        Icon(alert.level.icon, color: c, size: 16),
        const SizedBox(width: 8),
        SizedBox(
          width: 100,
          child: Text(alert.name,
              style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),
        ),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: c.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(alert.level.label,
              style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: c)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(alert.note,
              style: GoogleFonts.inter(
                  fontSize: 11, color: AppColors.textSecondary),
              overflow: TextOverflow.ellipsis),
        ),
      ]),
    );
  }
}

class _NutriScore extends StatelessWidget {
  final String grade;
  const _NutriScore({required this.grade});

  @override
  Widget build(BuildContext context) {
    final color = switch (grade) {
      'A' => const Color(0xFF038C43),
      'B' => const Color(0xFF85BB2F),
      'C' => const Color(0xFFFECB02),
      'D' => const Color(0xFFEE8100),
      _ => AppColors.error,
    };
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(grade,
            style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Colors.white)),
      ),
    );
  }
}

// ─── Log form card ────────────────────────────────────────────────────────────

class _LogFormCard extends StatelessWidget {
  final FoodProduct product;
  final TextEditingController servingCtrl;
  final double quantity;
  final String mealType;
  final bool logging;
  final ValueChanged<double> onQuantityChanged;
  final ValueChanged<String> onMealTypeChanged;
  final VoidCallback onLog;

  const _LogFormCard({
    required this.product,
    required this.servingCtrl,
    required this.quantity,
    required this.mealType,
    required this.logging,
    required this.onQuantityChanged,
    required this.onMealTypeChanged,
    required this.onLog,
  });

  @override
  Widget build(BuildContext context) {
    final rs = ResponsiveSize.of(context);
    final servingG =
        double.tryParse(servingCtrl.text) ?? product.defaultServingSizeG;
    final n = product.nutrientsForServing(servingG, quantity);

    return GlassmorphicCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Log This Food',
                style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Serving size (g)',
                        style: GoogleFonts.inter(
                            fontSize: 12, color: AppColors.textMuted)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: servingCtrl,
                      keyboardType: TextInputType.number,
                      style: GoogleFonts.inter(
                          color: AppColors.textPrimary, fontSize: 15),
                      decoration: _inputDec(),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Qty',
                      style: GoogleFonts.inter(
                          fontSize: 12, color: AppColors.textMuted)),
                  const SizedBox(height: 6),
                  Row(children: [
                    _QtyBtn(
                        icon: Icons.remove,
                        onTap: quantity > 0.5
                            ? () => onQuantityChanged(
                                double.parse(
                                    (quantity - 0.5).toStringAsFixed(1)))
                            : null),
                    const SizedBox(width: 8),
                    Text(quantity.toStringAsFixed(1),
                        style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary)),
                    const SizedBox(width: 8),
                    _QtyBtn(
                        icon: Icons.add,
                        onTap: () => onQuantityChanged(
                            double.parse(
                                (quantity + 0.5).toStringAsFixed(1)))),
                  ]),
                ],
              ),
            ]),
            const SizedBox(height: 12),
            Text('Meal type',
                style: GoogleFonts.inter(
                    fontSize: 12, color: AppColors.textMuted)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              children: DatabaseValues.mealTypes
                  .map((m) => ChoiceChip(
                        label: Text(m[0].toUpperCase() + m.substring(1),
                            style: GoogleFonts.inter(
                                fontSize: 12,
                                color: mealType == m
                                    ? Colors.black
                                    : AppColors.textSecondary)),
                        selected: mealType == m,
                        selectedColor: AppColors.accent,
                        backgroundColor: AppColors.bgElevated,
                        side: BorderSide(
                            color: mealType == m
                                ? AppColors.accent
                                : AppColors.border
                                    .withValues(alpha: 0.4)),
                        onSelected: (_) => onMealTypeChanged(m),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 14),
            // Computed totals preview
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.bgElevated,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _MiniStat(
                        n['calories']!.toStringAsFixed(0), 'kcal'),
                    _MiniStat(
                        '${n['protein']!.toStringAsFixed(1)}g', 'protein'),
                    _MiniStat(
                        '${n['fat']!.toStringAsFixed(1)}g', 'fat'),
                    _MiniStat(
                        '${n['sugar']!.toStringAsFixed(1)}g', 'sugar'),
                  ]),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: rs.sp(48),
              child: ElevatedButton.icon(
                onPressed: logging ? null : onLog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                icon: logging
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.black))
                    : const Icon(Icons.add_circle_rounded, size: 20),
                label: Text(logging ? 'Logging…' : 'Log Food',
                    style: GoogleFonts.inter(
                        fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.1, end: 0);
  }

  InputDecoration _inputDec() => InputDecoration(
        filled: true,
        fillColor: AppColors.bgInput,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
                color: AppColors.border.withValues(alpha: 0.5))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                const BorderSide(color: AppColors.accent, width: 1.5)),
      );
}

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _QtyBtn({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: onTap != null
              ? AppColors.bgElevated
              : AppColors.bgElevated.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: AppColors.border.withValues(alpha: 0.4)),
        ),
        child: Icon(icon,
            size: 16,
            color: onTap != null
                ? AppColors.textPrimary
                : AppColors.textMuted),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String value;
  final String label;
  const _MiniStat(this.value, this.label);

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(value,
          style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary)),
      Text(label,
          style:
              GoogleFonts.inter(fontSize: 10, color: AppColors.textMuted)),
    ]);
  }
}

// ─── Today's log section ──────────────────────────────────────────────────────

class _TodayLogSection extends ConsumerWidget {
  final String userId;
  const _TodayLogSection({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(todayFoodLogsProvider(userId));
    final pagedLogs = ref.watch(pagedTodayFoodLogsProvider(userId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Today's Log",
            style: GoogleFonts.inter(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
        const SizedBox(height: 12),
        summaryAsync.when(
          data: (summaryLogs) {
            if (summaryLogs.isEmpty && !pagedLogs.isInitialLoading) {
              return GlassmorphicCard(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    child: Text('No foods logged today',
                        style: GoogleFonts.inter(
                            color: AppColors.textMuted, fontSize: 14)),
                  ),
                ),
              );
            }
            final summary = NutritionSummary.fromLogs(summaryLogs);
            return GlassmorphicCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(children: [
                  if (pagedLogs.isInitialLoading)
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
                          .read(pagedTodayFoodLogsProvider(userId).notifier)
                          .loadInitial(),
                    )
                  else
                    ...pagedLogs.items.map((log) => _FoodLogTile(
                          log: log,
                          onDelete: () async {
                            await ref
                                .read(databaseServiceProvider)
                                .deleteFoodLog(log.id);
                            ref.invalidate(todayFoodLogsProvider(userId));
                            ref.invalidate(pagedTodayFoodLogsProvider(userId));
                          },
                        )),
                  if (!pagedLogs.isInitialLoading)
                    LoadingFooter(
                      isLoading: pagedLogs.isLoadingMore,
                      hasMore: pagedLogs.hasMore,
                      error: pagedLogs.items.isNotEmpty ? pagedLogs.error : null,
                      onPressed: () => ref
                          .read(pagedTodayFoodLogsProvider(userId).notifier)
                          .loadMore(),
                    ),
                  const Divider(color: AppColors.border, height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Daily Total',
                          style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary)),
                      Text(
                          '${summary.calories.toStringAsFixed(0)} kcal  •  ${summary.protein.toStringAsFixed(1)}g protein',
                          style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppColors.accent,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ]),
              ),
            );
          },
          loading: () => const CardSkeleton(height: 180),
          error: (e, _) => ErrorStateWidget(
            message: 'Unable to load today\'s summary.',
            onRetry: () => ref.invalidate(todayFoodLogsProvider(userId)),
          ),
        ),
      ],
    );
  }
}

class _FoodLogTile extends StatelessWidget {
  final FoodLog log;
  final VoidCallback onDelete;
  const _FoodLogTile({required this.log, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(log.mealType[0].toUpperCase() + log.mealType.substring(1),
              style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryLight)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(log.productName,
                  style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary),
                  overflow: TextOverflow.ellipsis),
              Text(
                  '${log.caloriesKcal.toStringAsFixed(0)} kcal  •  P: ${log.proteinG.toStringAsFixed(1)}g  F: ${log.fatG.toStringAsFixed(1)}g',
                  style: GoogleFonts.inter(
                      fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline_rounded,
              color: AppColors.textMuted, size: 18),
          onPressed: onDelete,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// REPORTS TAB
// ═══════════════════════════════════════════════════════════════════════════

class _ReportsTab extends ConsumerStatefulWidget {
  const _ReportsTab();

  @override
  ConsumerState<_ReportsTab> createState() => _ReportsTabState();
}

class _ReportsTabState extends ConsumerState<_ReportsTab>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).value;
    if (user == null) {
      return const DashboardSkeletonScaffold();
    }

    return Column(
      children: [
        Container(
          color: AppColors.bgDark,
          child: TabBar(
            controller: _tabs,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textMuted,
            indicatorColor: AppColors.primary,
            indicatorSize: TabBarIndicatorSize.label,
            labelStyle: GoogleFonts.inter(
                fontSize: 13, fontWeight: FontWeight.w600),
            tabs: const [
              Tab(text: 'Today'),
              Tab(text: 'This Week'),
              Tab(text: 'This Month'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: [
              _DayReport(userId: user.id),
              _PeriodReport(
                  userId: user.id,
                  provider: weeklyFoodLogsProvider,
                  label: 'This Week'),
              _PeriodReport(
                  userId: user.id,
                  provider: monthlyFoodLogsProvider,
                  label: 'This Month'),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Today report ─────────────────────────────────────────────────────────────

class _DayReport extends ConsumerWidget {
  final String userId;
  const _DayReport({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logs = ref.watch(todayFoodLogsProvider(userId));
    return logs.when(
      data: (list) {
        final s = NutritionSummary.fromLogs(list);
        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(todayFoodLogsProvider(userId));
            await ref.read(todayFoodLogsProvider(userId).future);
          },
          backgroundColor: AppColors.bgElevated,
          color: AppColors.primary,
          child: _ReportBody(summary: s, showFoodList: true),
        );
      },
      loading: () => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: const [
          CardSkeleton(height: 92),
          SizedBox(height: 16),
          CardSkeleton(height: 220),
          SizedBox(height: 16),
          ChartSkeleton(height: 100),
        ],
      ),
      error: (e, _) => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.6,
            child: ErrorStateWidget(
              message: 'Unable to load today\'s report.',
              onRetry: () => ref.invalidate(todayFoodLogsProvider(userId)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Week / Month report ──────────────────────────────────────────────────────

class _PeriodReport extends ConsumerWidget {
  final String userId;
  final FutureProviderFamily<List<FoodLog>, String> provider;
  final String label;

  const _PeriodReport({
    required this.userId,
    required this.provider,
    required this.label,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logs = ref.watch(provider(userId));
    return logs.when(
      data: (list) {
        final s = NutritionSummary.fromLogs(list);
        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(provider(userId));
            await ref.read(provider(userId).future);
          },
          backgroundColor: AppColors.bgElevated,
          color: AppColors.primary,
          child: _ReportBody(
            summary: s,
            showFoodList: false,
            periodLabel: label,
            logs: list,
          ),
        );
      },
      loading: () => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: const [
          CardSkeleton(height: 92),
          SizedBox(height: 16),
          CardSkeleton(height: 220),
          SizedBox(height: 16),
          ChartSkeleton(height: 100),
        ],
      ),
      error: (e, _) => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.6,
            child: ErrorStateWidget(
              message: 'Unable to load this report.',
              onRetry: () => ref.invalidate(provider(userId)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Shared report body ───────────────────────────────────────────────────────

class _ReportBody extends StatelessWidget {
  final NutritionSummary summary;
  final bool showFoodList;
  final String? periodLabel;
  final List<FoodLog>? logs;

  const _ReportBody({
    required this.summary,
    required this.showFoodList,
    this.periodLabel,
    this.logs,
  });

  @override
  Widget build(BuildContext context) {
    final insight = buildNutritionInsight(summary);
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      children: [
        // Insight card
        GlassmorphicCard(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.lightbulb_rounded,
                    color: AppColors.warning, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(insight,
                    style: GoogleFonts.inter(
                        fontSize: 13, color: AppColors.textSecondary)),
              ),
            ]),
          ),
        ).animate().fadeIn(),
        const SizedBox(height: 16),

        // Macro progress bars
        GlassmorphicCard(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    periodLabel != null
                        ? 'Totals — $periodLabel'
                        : "Today's Totals",
                    style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 16),
                _MacroBar('Calories', summary.calories,
                    DailyTargets.calories, 'kcal', AppColors.warning),
                _MacroBar('Protein', summary.protein, DailyTargets.protein,
                    'g', AppColors.accent),
                _MacroBar(
                    'Fat', summary.fat, DailyTargets.fat, 'g', AppColors.error),
                _MacroBar('Carbs', summary.carbs, DailyTargets.carbs, 'g',
                    AppColors.primary),
                _MacroBar('Sugar', summary.sugar, DailyTargets.sugar, 'g',
                    AppColors.warning),
                _MacroBar('Fiber', summary.fiber, DailyTargets.fiber, 'g',
                    AppColors.accent),
                _MacroBar('Sodium', summary.sodium, DailyTargets.sodiumMg,
                    'mg', AppColors.info),
              ],
            ),
          ),
        ).animate(delay: 100.ms).fadeIn(),

        // Daily bar chart for weekly/monthly view
        if (!showFoodList && logs != null && logs!.isNotEmpty) ...[
          const SizedBox(height: 16),
          _DailyCaloriesChart(logs: logs!),
        ],

        // Food list for Today
        if (showFoodList && summary.logs.isNotEmpty) ...[
          const SizedBox(height: 16),
          GlassmorphicCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Foods Today",
                      style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 10),
                  ...summary.logs.map((log) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(children: [
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(right: 10, top: 4),
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              shape: BoxShape.circle,
                            ),
                          ),
                          Expanded(
                            child: Text(log.productName,
                                style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: AppColors.textPrimary),
                                overflow: TextOverflow.ellipsis),
                          ),
                          Text(
                              '${log.caloriesKcal.toStringAsFixed(0)} kcal',
                              style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: AppColors.textSecondary)),
                        ]),
                      )),
                ],
              ),
            ),
          ).animate(delay: 200.ms).fadeIn(),
        ],
      ],
    );
  }
}

class _MacroBar extends StatelessWidget {
  final String label;
  final double value;
  final double target;
  final String unit;
  final Color color;
  const _MacroBar(
      this.label, this.value, this.target, this.unit, this.color);

  @override
  Widget build(BuildContext context) {
    final frac = (value / target).clamp(0.0, 1.0);
    final over = value > target;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),
          const Spacer(),
          Text(
              '${value.toStringAsFixed(value >= 10 ? 0 : 1)} / ${target.toStringAsFixed(0)} $unit',
              style: GoogleFonts.inter(
                  fontSize: 11,
                  color: over ? AppColors.error : AppColors.textSecondary)),
          if (over) ...[
            const SizedBox(width: 4),
            const Icon(Icons.warning_rounded,
                color: AppColors.error, size: 12),
          ],
        ]),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: frac,
            minHeight: 8,
            backgroundColor: color.withValues(alpha: 0.12),
            valueColor: AlwaysStoppedAnimation(over ? AppColors.error : color),
          ),
        ),
      ]),
    );
  }
}

// ─── Daily calories bar chart (week/month view) ───────────────────────────────

class _DailyCaloriesChart extends StatelessWidget {
  final List<FoodLog> logs;
  const _DailyCaloriesChart({required this.logs});

  @override
  Widget build(BuildContext context) {
    final byDay = groupLogsByDay(logs);
    final sorted = byDay.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return GlassmorphicCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxBars = constraints.maxWidth < 360 ? 10 : 30;
            final buckets = bucketLabeledValues(
              values: sorted
                  .map(
                    (entry) => LabeledChartBucket(
                      label: entry.key.substring(8),
                      value: entry.value.calories,
                    ),
                  )
                  .toList(),
              maxBuckets: maxBars,
            );
            final maxCal = buckets.isEmpty
                ? 1.0
                : buckets
                    .map((e) => e.value)
                    .reduce((a, b) => a > b ? a : b)
                    .clamp(1.0, double.infinity);
            final chartHeight = constraints.maxWidth < 360 ? 90.0 : 110.0;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Calories per Day',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: chartHeight,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: buckets.map((entry) {
                      final frac = entry.value / maxCal;
                      final overTarget = entry.value > DailyTargets.calories;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 500),
                                height: (frac * (chartHeight - 16))
                                    .clamp(3, chartHeight - 16),
                                decoration: BoxDecoration(
                                  color: overTarget
                                      ? AppColors.error
                                      : AppColors.accent,
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(4),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: buckets.map((entry) {
                    return Expanded(
                      child: Text(
                        entry.label,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: constraints.maxWidth < 360 ? 8 : 9,
                          color: AppColors.textMuted,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            );
          },
        ),
      ),
    ).animate(delay: 200.ms).fadeIn();
  }

}
