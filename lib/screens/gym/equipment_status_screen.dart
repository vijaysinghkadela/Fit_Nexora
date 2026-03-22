// lib/screens/gym/equipment_status_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:go_router/go_router.dart';

import '../../config/theme.dart';
import '../../core/extensions.dart';
import '../../providers/auth_provider.dart';
import '../../providers/gym_provider.dart';
import '../../widgets/glassmorphic_card.dart';

// ─── Data model ───────────────────────────────────────────────────────────────

class EquipmentItem {
  final String id;
  final String name;
  final String category;
  final int totalCount;
  final int inUse;
  final int outOfService;

  const EquipmentItem({
    required this.id,
    required this.name,
    required this.category,
    required this.totalCount,
    required this.inUse,
    required this.outOfService,
  });

  int get available => (totalCount - inUse - outOfService).clamp(0, totalCount);

  factory EquipmentItem.fromMap(Map<String, dynamic> m) => EquipmentItem(
        id: m['id'] as String,
        name: m['name'] as String,
        category: (m['category'] as String?) ?? 'General',
        totalCount: (m['total_units'] as int?) ?? 1,
        inUse: (m['in_use'] as int?) ?? 0,
        outOfService: (m['out_of_service'] as int?) ?? 0,
      );
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final equipmentStatusProvider =
    FutureProvider.autoDispose<List<EquipmentItem>>((ref) async {
  final gym = ref.watch(selectedGymProvider);
  final gymId = gym?.id;
  if (gymId == null) return [];

  final data = await Supabase.instance.client
      .from('equipment_status')
      .select()
      .eq('gym_id', gymId)
      .order('category')
      .order('name');

  return (data as List)
      .map((e) => EquipmentItem.fromMap(e as Map<String, dynamic>))
      .toList();
});

// ─── Screen ───────────────────────────────────────────────────────────────────

class EquipmentStatusScreen extends ConsumerWidget {
  const EquipmentStatusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.fitTheme;
    final equipAsync = ref.watch(equipmentStatusProvider);
    final user = ref.watch(currentUserProvider).value;
    final gymsLoading = ref.watch(userGymsProvider).isLoading;
    final gym = ref.watch(selectedGymProvider);
    final isOwner =
        user?.globalRole.name == 'gymOwner' || user?.globalRole.name == 'superAdmin';

    return Scaffold(
      backgroundColor: t.background,
      floatingActionButton: isOwner
          ? FloatingActionButton.extended(
              onPressed: () => _showAddEquipmentSheet(context, gym?.id, t),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Equipment'),
              backgroundColor: t.brand,
              foregroundColor: Colors.white,
            )
          : null,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            backgroundColor: t.surface,
            title: Text(
              'Equipment Status',
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: t.textPrimary,
              ),
            ),
            leading: IconButton(
              icon: Icon(Icons.arrow_back_rounded, color: t.textPrimary),
              onPressed: () =>
                  context.canPop() ? context.pop() : context.go('/'),
            ),
          ),

          // Show loading spinner while gym is being fetched
          if (gym == null && gymsLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else
            equipAsync.when(
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => SliverFillRemaining(
                child: Center(
                  child: Text(
                    'Could not load equipment data',
                    style: GoogleFonts.inter(color: t.textMuted),
                  ),
                ),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return SliverFillRemaining(
                    child: _EmptyState(t: t, isOwner: isOwner),
                  );
                }

                // Summary header
                final totalAvail = items.fold(0, (s, e) => s + e.available);
                final totalInUse = items.fold(0, (s, e) => s + e.inUse);
                final totalOos = items.fold(0, (s, e) => s + e.outOfService);

                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                  sliver: SliverList.list(
                    children: [
                      _SummaryRow(
                        available: totalAvail,
                        inUse: totalInUse,
                        outOfService: totalOos,
                        t: t,
                      ).animate().fadeIn(duration: 300.ms),
                      const SizedBox(height: 24),
                      ...items.asMap().entries.map((entry) {
                        final i = entry.key;
                        final item = entry.value;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _EquipmentCard(
                            item: item,
                            isOwner: isOwner,
                            onUpdate: isOwner
                                ? (inUse, oos) => _update(
                                    context, ref, item.id, inUse, oos)
                                : null,
                            t: t,
                          )
                              .animate()
                              .fadeIn(
                                duration: 300.ms,
                                delay: Duration(milliseconds: 40 * i),
                              )
                              .slideY(begin: 0.04),
                        );
                      }),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Future<void> _update(BuildContext context, WidgetRef ref, String id,
      int inUse, int oos) async {
    try {
      await Supabase.instance.client
          .from('equipment_status')
          .update({'in_use': inUse, 'out_of_service': oos})
          .eq('id', id);
      ref.invalidate(equipmentStatusProvider);
    } catch (e) {
      if (context.mounted) {
        context.showSnackBar('Update failed: $e', isError: true);
      }
    }
  }

  Future<void> _showAddEquipmentSheet(
    BuildContext context,
    String? gymId,
    FitNexoraThemeTokens t,
  ) async {
    if (gymId == null) {
      context.showSnackBar('No gym selected.', isError: true);
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: t.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _AddEquipmentSheet(gymId: gymId, t: t),
    );
  }
}

// ─── Add Equipment Sheet ───────────────────────────────────────────────────────

class _AddEquipmentSheet extends ConsumerStatefulWidget {
  final String gymId;
  final FitNexoraThemeTokens t;

  const _AddEquipmentSheet({
    required this.gymId,
    required this.t,
  });

  @override
  ConsumerState<_AddEquipmentSheet> createState() => _AddEquipmentSheetState();
}

class _AddEquipmentSheetState extends ConsumerState<_AddEquipmentSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _unitsCtrl = TextEditingController(text: '1');
  String _category = 'Cardio';
  bool _saving = false;

  static const _categories = [
    'Cardio',
    'Strength',
    'Flexibility',
    'Functional',
    'Other',
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _unitsCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await Supabase.instance.client.from('equipment_status').insert({
        'gym_id': widget.gymId,
        'name': _nameCtrl.text.trim(),
        'category': _category,
        'total_units': int.tryParse(_unitsCtrl.text.trim()) ?? 1,
        'in_use': 0,
        'out_of_service': 0,
      });
      ref.invalidate(equipmentStatusProvider);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        context.showSnackBar('Failed to add equipment: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.t;
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
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
            const SizedBox(height: 16),
            Text(
              'Add Equipment',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: t.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _nameCtrl,
              style: GoogleFonts.inter(color: t.textPrimary),
              decoration: InputDecoration(
                labelText: 'Equipment Name',
                labelStyle: GoogleFonts.inter(color: t.textMuted),
                filled: true,
                fillColor: t.surfaceMuted,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _category,
              dropdownColor: t.surface,
              style: GoogleFonts.inter(color: t.textPrimary),
              decoration: InputDecoration(
                labelText: 'Category',
                labelStyle: GoogleFonts.inter(color: t.textMuted),
                filled: true,
                fillColor: t.surfaceMuted,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              items: _categories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _category = v ?? _category),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _unitsCtrl,
              style: GoogleFonts.inter(color: t.textPrimary),
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Total Units',
                labelStyle: GoogleFonts.inter(color: t.textMuted),
                filled: true,
                fillColor: t.surfaceMuted,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              validator: (v) {
                final n = int.tryParse(v ?? '');
                return (n == null || n < 1) ? 'Enter a valid number' : null;
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: t.brand,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'Add Equipment',
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
    );
  }
}

// ─── Summary row ──────────────────────────────────────────────────────────────

class _SummaryRow extends StatelessWidget {
  final int available;
  final int inUse;
  final int outOfService;
  final FitNexoraThemeTokens t;

  const _SummaryRow({
    required this.available,
    required this.inUse,
    required this.outOfService,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Chip(label: '$available Available', color: t.success, t: t),
        const SizedBox(width: 8),
        _Chip(label: '$inUse In Use', color: t.info, t: t),
        const SizedBox(width: 8),
        _Chip(label: '$outOfService Out', color: t.danger, t: t),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  final FitNexoraThemeTokens t;

  const _Chip({required this.label, required this.color, required this.t});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

// ─── Equipment card ───────────────────────────────────────────────────────────

class _EquipmentCard extends StatelessWidget {
  final EquipmentItem item;
  final bool isOwner;
  final void Function(int inUse, int oos)? onUpdate;
  final FitNexoraThemeTokens t;

  const _EquipmentCard({
    required this.item,
    required this.isOwner,
    required this.onUpdate,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    final availColor = item.available > 0 ? t.success : t.danger;

    return GlassmorphicCard(
      borderRadius: 16,
      applyBlur: false,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: t.textPrimary,
                        ),
                      ),
                      Text(
                        item.category,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: t.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: availColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${item.available} free',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: availColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _StatusBar(item: item, t: t),
            if (isOwner) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  _CounterButton(
                    label: 'In Use',
                    value: item.inUse,
                    max: item.totalCount - item.outOfService,
                    color: t.info,
                    onChanged: (v) => onUpdate?.call(v, item.outOfService),
                    t: t,
                  ),
                  const SizedBox(width: 12),
                  _CounterButton(
                    label: 'Out of Service',
                    value: item.outOfService,
                    max: item.totalCount - item.inUse,
                    color: t.danger,
                    onChanged: (v) => onUpdate?.call(item.inUse, v),
                    t: t,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusBar extends StatelessWidget {
  final EquipmentItem item;
  final FitNexoraThemeTokens t;

  const _StatusBar({required this.item, required this.t});

  @override
  Widget build(BuildContext context) {
    final total = item.totalCount;
    if (total == 0) return const SizedBox.shrink();

    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        height: 8,
        child: Row(
          children: [
            if (item.available > 0)
              Flexible(
                flex: item.available,
                child: Container(color: t.success),
              ),
            if (item.inUse > 0)
              Flexible(
                flex: item.inUse,
                child: Container(color: t.info),
              ),
            if (item.outOfService > 0)
              Flexible(
                flex: item.outOfService,
                child: Container(color: t.danger),
              ),
          ],
        ),
      ),
    );
  }
}

class _CounterButton extends StatelessWidget {
  final String label;
  final int value;
  final int max;
  final Color color;
  final ValueChanged<int> onChanged;
  final FitNexoraThemeTokens t;

  const _CounterButton({
    required this.label,
    required this.value,
    required this.max,
    required this.color,
    required this.onChanged,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: t.surfaceMuted,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(fontSize: 11, color: t.textMuted),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                _iconBtn(
                  Icons.remove,
                  value > 0 ? () => onChanged(value - 1) : null,
                  color,
                ),
                Expanded(
                  child: Text(
                    '$value',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ),
                _iconBtn(
                  Icons.add,
                  value < max ? () => onChanged(value + 1) : null,
                  color,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback? onTap, Color c) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: c.withOpacity(onTap != null ? 0.15 : 0.05),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 16,
          color: onTap != null ? c : c.withOpacity(0.3),
        ),
      ),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final FitNexoraThemeTokens t;
  final bool isOwner;
  const _EmptyState({required this.t, required this.isOwner});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.fitness_center_rounded, size: 64, color: t.textMuted),
          const SizedBox(height: 16),
          Text(
            'No equipment listed',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: t.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isOwner
                ? 'Tap "Add Equipment" below to get started.'
                : 'Equipment will appear here once added.',
            style: GoogleFonts.inter(fontSize: 14, color: t.textMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
