import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/extensions.dart';
import '../../config/theme.dart';
import '../../widgets/glassmorphic_card.dart';

/// Master transformation journey screen — before/after, AI metrics, milestones.
class MasterTransformationScreen extends ConsumerWidget {
  const MasterTransformationScreen({super.key});

  static const routePath = '/master/transformation';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.fitTheme;

    return Scaffold(
      backgroundColor: t.background,
      appBar: AppBar(
        backgroundColor: t.background,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: t.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Transformation Journey',
          style: GoogleFonts.inter(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: t.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.share_outlined, color: t.textPrimary),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
        elevation: 0,
      ),
      body: CustomScrollView(
        slivers: [
          // Before / After section
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'BEFORE / AFTER',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: t.textMuted,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _BeforeAfterSection(t: t),
                ],
              )
                  .animate()
                  .fadeIn(duration: 400.ms)
                  .slideY(begin: 0.1),
            ),
          ),

          // AI Metrics section
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AI METRICS',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: t.textMuted,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _AiMetricsCard(t: t),
                ],
              )
                  .animate(delay: 80.ms)
                  .fadeIn(duration: 400.ms)
                  .slideY(begin: 0.1),
            ),
          ),

          // AI Predictor card
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            sliver: SliverToBoxAdapter(
              child: _AiPredictorCard(t: t)
                  .animate(delay: 150.ms)
                  .fadeIn(duration: 400.ms)
                  .slideY(begin: 0.1),
            ),
          ),

          // Journey milestones
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'JOURNEY MILESTONES',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: t.textMuted,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _MilestonesTimeline(t: t),
                ],
              )
                  .animate(delay: 220.ms)
                  .fadeIn(duration: 400.ms)
                  .slideY(begin: 0.1),
            ),
          ),

          const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Before / After section
// ---------------------------------------------------------------------------

class _BeforeAfterSection extends StatelessWidget {
  final FitNexoraThemeTokens t;
  const _BeforeAfterSection({required this.t});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // BEFORE
        Expanded(
          child: Stack(
            children: [
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: t.surfaceMuted,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: t.border),
                ),
                child: Center(
                  child: Icon(
                    Icons.person_outline_rounded,
                    size: 64,
                    color: t.textMuted,
                  ),
                ),
              ),
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'BEFORE',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 10,
                left: 10,
                child: Text(
                  'Jan 2025',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: t.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        // AFTER
        Expanded(
          child: Stack(
            children: [
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: t.brand.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: t.brand.withValues(alpha: 0.40),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: t.brand.withValues(alpha: 0.15),
                      blurRadius: 16,
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    Icons.person_rounded,
                    size: 64,
                    color: t.brand.withValues(alpha: 0.7),
                  ),
                ),
              ),
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: t.brand.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'AFTER',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: t.accent,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Now',
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 10,
                left: 10,
                child: Text(
                  'Mar 2026',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: t.brand,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// AI Metrics card
// ---------------------------------------------------------------------------

class _AiMetricsCard extends StatelessWidget {
  final FitNexoraThemeTokens t;
  const _AiMetricsCard({required this.t});

  @override
  Widget build(BuildContext context) {
    return GlassmorphicCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _MetricRow(
              label: 'Muscle Density',
              value: '+14.2%',
              color: t.accent,
              t: t,
            ),
            Divider(height: 20, color: t.divider),
            _MetricRow(
              label: 'Symmetry Score',
              value: '96.8%',
              color: t.info,
              t: t,
            ),
            Divider(height: 20, color: t.divider),
            _MetricRow(
              label: 'Body Fat Reduction',
              value: '-8.3%',
              color: t.accent,
              t: t,
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final FitNexoraThemeTokens t;
  const _MetricRow({
    required this.label,
    required this.value,
    required this.color,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: t.textPrimary,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// AI Predictor card
// ---------------------------------------------------------------------------

class _AiPredictorCard extends StatelessWidget {
  final FitNexoraThemeTokens t;
  const _AiPredictorCard({required this.t});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: t.brand.withValues(alpha: 0.10),
        border: Border.all(color: t.brand.withValues(alpha: 0.30)),
        boxShadow: [
          BoxShadow(
            color: t.brand.withValues(alpha: 0.10),
            blurRadius: 16,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: t.brand.withValues(alpha: 0.20),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome, color: t.brand, size: 12),
                    const SizedBox(width: 5),
                    Text(
                      'AI PREDICTOR',
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: t.brand,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'In 60 days...',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: t.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Based on current trajectory and recovery data',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: t.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          _PredictorBar(
            label: 'Muscle gain',
            predicted: '+6.8%',
            progress: 0.68,
            color: t.accent,
            t: t,
          ),
          const SizedBox(height: 14),
          _PredictorBar(
            label: 'Strength increase',
            predicted: '+22%',
            progress: 0.78,
            color: t.brand,
            t: t,
          ),
          const SizedBox(height: 14),
          _PredictorBar(
            label: 'Fat loss',
            predicted: '-4.1%',
            progress: 0.55,
            color: t.info,
            t: t,
          ),
        ],
      ),
    );
  }
}

class _PredictorBar extends StatelessWidget {
  final String label;
  final String predicted;
  final double progress;
  final Color color;
  final FitNexoraThemeTokens t;
  const _PredictorBar({
    required this.label,
    required this.predicted,
    required this.progress,
    required this.color,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: t.textSecondary,
              ),
            ),
            Text(
              predicted,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: t.ringTrack,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Milestones timeline
// ---------------------------------------------------------------------------

enum _MilestoneStatus { completed, current, locked }

class _Milestone {
  final String month;
  final String title;
  final _MilestoneStatus status;
  const _Milestone({
    required this.month,
    required this.title,
    required this.status,
  });
}

class _MilestonesTimeline extends StatelessWidget {
  final FitNexoraThemeTokens t;
  const _MilestonesTimeline({required this.t});

  static const _milestones = [
    _Milestone(month: 'Month 1', title: 'Foundation Built', status: _MilestoneStatus.completed),
    _Milestone(month: 'Month 2', title: 'Strength Gains', status: _MilestoneStatus.completed),
    _Milestone(month: 'Month 3', title: 'Body Recomp Phase', status: _MilestoneStatus.current),
    _Milestone(month: 'Month 4', title: 'Peak Performance', status: _MilestoneStatus.locked),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: _milestones.asMap().entries.map((entry) {
        final i = entry.key;
        final m = entry.value;
        final isLast = i == _milestones.length - 1;
        return _MilestoneRow(
          milestone: m,
          t: t,
          isLast: isLast,
        )
            .animate(delay: (i * 70).ms)
            .fadeIn(duration: 380.ms)
            .slideX(begin: -0.04);
      }).toList(),
    );
  }
}

class _MilestoneRow extends StatefulWidget {
  final _Milestone milestone;
  final FitNexoraThemeTokens t;
  final bool isLast;
  const _MilestoneRow({
    required this.milestone,
    required this.t,
    required this.isLast,
  });

  @override
  State<_MilestoneRow> createState() => _MilestoneRowState();
}

class _MilestoneRowState extends State<_MilestoneRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    if (widget.milestone.status == _MilestoneStatus.current) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.t;
    final m = widget.milestone;

    Color dotColor;
    Widget dotWidget;

    switch (m.status) {
      case _MilestoneStatus.completed:
        dotColor = t.accent;
        dotWidget = Icon(Icons.check_rounded, color: Colors.white, size: 12);
        break;
      case _MilestoneStatus.current:
        dotColor = t.brand;
        dotWidget = AnimatedBuilder(
          animation: _pulse,
          builder: (context, _) => Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.85 + _pulse.value * 0.15),
            ),
          ),
        );
        break;
      case _MilestoneStatus.locked:
        dotColor = t.surfaceMuted;
        dotWidget = Icon(Icons.lock_outline_rounded,
            color: t.textMuted, size: 12);
        break;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline column
        Column(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: dotColor,
                boxShadow: m.status == _MilestoneStatus.current
                    ? [
                        BoxShadow(
                          color: t.brand.withValues(alpha: 0.4),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: Center(child: dotWidget),
            ),
            if (!widget.isLast)
              Container(
                width: 2,
                height: 44,
                color: m.status == _MilestoneStatus.completed
                    ? t.accent.withValues(alpha: 0.4)
                    : t.border,
              ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 5, bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  m.month,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: m.status == _MilestoneStatus.locked
                        ? t.textMuted
                        : t.textMuted,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  m.title,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: m.status == _MilestoneStatus.locked
                        ? t.textMuted
                        : t.textPrimary,
                  ),
                ),
                if (m.status == _MilestoneStatus.current) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: t.brand.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'In Progress',
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: t.brand,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
