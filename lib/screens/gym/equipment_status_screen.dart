// lib/screens/gym/equipment_status_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
        totalCount: (m['total_count'] as int?) ?? 1,
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
    final isOwner =
        user?.globalRole.name == 'gymOwner' || user?.globalRole.name == 'superAdmin';

    return Scaffold(
      backgroundColor: t.background,
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
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ),

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
                  child: _EmptyState(t: t),
                );
              }

              // Summary header
              final totalAvail =
                  items.fold(0, (s, e) => s + e.available);
              final totalInUse =
                  items.fold(0, (s, e) => s + e.inUse);
              final totalOos =
                  items.fold(0, (s, e) => s + e.outOfService);

              return SliverPadding(
                padding: const EdgeInsets.all(20),
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
  const _EmptyState({required this.t});

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
            'Equipment will appear here once added.',
            style: GoogleFonts.inter(fontSize: 14, color: t.textMuted),
          ),
        ],
      ),
    );
  }
}
