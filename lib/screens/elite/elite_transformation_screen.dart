import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../providers/elite_member_provider.dart';
import '../../widgets/glassmorphic_card.dart';

/// Elite: Transformation Photo Comparison — before/after progress photos.
class EliteTransformationScreen extends ConsumerWidget {
  const EliteTransformationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photosAsync = ref.watch(eliteTransformationPhotosProvider);

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.bgDark,
        leading: BackButton(color: AppColors.textSecondary),
        title: Text('Transformation Photos',
            style: GoogleFonts.inter(
                fontSize: 19, fontWeight: FontWeight.w800,
                color: AppColors.textPrimary)),
      ),
      body: photosAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(
            child: Text('$e',
                style: GoogleFonts.inter(color: AppColors.error))),
        data: (entries) {
          if (entries.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.compare_rounded,
                      size: 56, color: AppColors.textMuted),
                  const SizedBox(height: 16),
                  Text('No transformation photos yet',
                      style: GoogleFonts.inter(
                          color: AppColors.textSecondary, fontSize: 16)),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      'Your trainer can upload your progress photos.\nThey will appear here for comparison.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                          color: AppColors.textMuted,
                          fontSize: 13, height: 1.5),
                    ),
                  ),
                  const SizedBox(height: 30),
                  GlassmorphicCard(
                    margin: const EdgeInsets.symmetric(horizontal: 40),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(children: [
                        const Icon(Icons.info_outline_rounded,
                            color: AppColors.info, size: 28),
                        const SizedBox(height: 10),
                        Text('How it works',
                            style: GoogleFonts.inter(
                                fontSize: 14, fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary)),
                        const SizedBox(height: 8),
                        Text(
                          '1. Take front, side, and back photos\n'
                          '2. Share with your trainer via chat\n'
                          '3. Trainer uploads to your profile\n'
                          '4. Compare before vs after here',
                          style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              height: 1.6),
                        ),
                      ]),
                    ),
                  ).animate().fadeIn(),
                ],
              ),
            );
          }

          // Show before/after comparison
          final latest = entries.first;
          final oldest = entries.last;
          final hasMultiple = entries.length > 1;

          return CustomScrollView(
            slivers: [
              if (hasMultiple) ...[
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  sliver: SliverToBoxAdapter(
                    child: Text('BEFORE vs AFTER',
                        style: GoogleFonts.inter(
                            fontSize: 11, fontWeight: FontWeight.w700,
                            color: AppColors.textMuted, letterSpacing: 1.2)),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverToBoxAdapter(
                    child: _ComparisonCard(
                        before: oldest, after: latest),
                  ),
                ),
              ],

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                sliver: SliverToBoxAdapter(
                  child: Text('ALL PHOTOS',
                      style: GoogleFonts.inter(
                          fontSize: 11, fontWeight: FontWeight.w700,
                          color: AppColors.textMuted, letterSpacing: 1.2)),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((ctx, i) {
                    final m = entries[i];
                    return _PhotoCard(checkIn: m)
                        .animate(delay: (i * 60).ms)
                        .fadeIn();
                  }, childCount: entries.length),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ComparisonCard extends StatelessWidget {
  final dynamic before;
  final dynamic after;
  const _ComparisonCard({required this.before, required this.after});

  @override
  Widget build(BuildContext context) {
    return GlassmorphicCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(children: [
              Expanded(child: _PhotoColumn(label: 'BEFORE',
                  date: before.checkInDate as DateTime,
                  photoUrl: before.frontPhotoUrl as String?,
                  weight: before.weightKg as double?)),
              const SizedBox(width: 12),
              Container(width: 1, height: 120, color: AppColors.divider),
              const SizedBox(width: 12),
              Expanded(child: _PhotoColumn(label: 'AFTER',
                  date: after.checkInDate as DateTime,
                  photoUrl: after.frontPhotoUrl as String?,
                  weight: after.weightKg as double?)),
            ]),
            if (before.weightKg != null && after.weightKg != null)
              Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppColors.success.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    'Total change: ${((after.weightKg as double) - (before.weightKg as double)).toStringAsFixed(1)} kg',
                    style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.success),
                  ),
                ),
              ),
          ],
        ),
      ),
    ).animate().fadeIn();
  }
}

class _PhotoColumn extends StatelessWidget {
  final String label;
  final DateTime date;
  final String? photoUrl;
  final double? weight;
  const _PhotoColumn(
      {required this.label, required this.date,
      this.photoUrl, this.weight});

  @override
  Widget build(BuildContext context) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun',
        'Jul','Aug','Sep','Oct','Nov','Dec'];
    return Column(children: [
      Text(label,
          style: GoogleFonts.inter(
              fontSize: 10, fontWeight: FontWeight.w800,
              color: AppColors.textMuted, letterSpacing: 1.2)),
      const SizedBox(height: 8),
      Container(
        height: 100, width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.bgElevated,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: photoUrl != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(photoUrl!, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                        Icons.broken_image_rounded,
                        color: AppColors.textMuted)),
              )
            : const Center(
                child: Icon(Icons.person_rounded,
                    size: 40, color: AppColors.textMuted)),
      ),
      const SizedBox(height: 6),
      Text('${date.day} ${months[date.month - 1]}',
          style: GoogleFonts.inter(
              fontSize: 11, color: AppColors.textSecondary)),
      if (weight != null)
        Text('${weight!.toStringAsFixed(1)} kg',
            style: GoogleFonts.inter(
                fontSize: 12, fontWeight: FontWeight.w700,
                color: AppColors.primary)),
    ]);
  }
}

class _PhotoCard extends StatelessWidget {
  final dynamic checkIn;
  const _PhotoCard({required this.checkIn});

  @override
  Widget build(BuildContext context) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun',
        'Jul','Aug','Sep','Oct','Nov','Dec'];
    final dt = checkIn.checkInDate as DateTime;
    final dateStr = '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    final photos = [
      ('Front', checkIn.frontPhotoUrl as String?),
      ('Side', checkIn.sidePhotoUrl as String?),
      ('Back', checkIn.backPhotoUrl as String?),
    ].where((p) => p.$2 != null).toList();

    return GlassmorphicCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.calendar_today_rounded,
                size: 14, color: AppColors.textMuted),
            const SizedBox(width: 6),
            Text(dateStr,
                style: GoogleFonts.inter(
                    fontSize: 13, fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
            if (checkIn.weightKg != null) ...[
              const Spacer(),
              Text('${(checkIn.weightKg as double).toStringAsFixed(1)} kg',
                  style: GoogleFonts.inter(
                      fontSize: 13, fontWeight: FontWeight.w800,
                      color: AppColors.primary)),
            ],
          ]),
          if (photos.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              children: photos.map((p) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Column(children: [
                    Container(
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.bgElevated,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(p.$2!, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Center(
                                child: Icon(Icons.broken_image_rounded,
                                    color: AppColors.textMuted))),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(p.$1,
                        style: GoogleFonts.inter(
                            fontSize: 9, color: AppColors.textMuted)),
                  ]),
                ),
              )).toList(),
            ),
          ],
        ]),
      ),
    );
  }
}
