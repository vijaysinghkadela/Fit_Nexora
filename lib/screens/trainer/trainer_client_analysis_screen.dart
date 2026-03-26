// lib/screens/trainer/trainer_client_analysis_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../core/extensions.dart';
import '../../models/client_profile_model.dart';
import '../../models/trainer_analysis_model.dart';
import '../../providers/gym_provider.dart';
import '../../providers/trainer_analysis_provider.dart';
import '../../widgets/glassmorphic_card.dart';

/// Screen for trainers to view and generate AI analysis reports for a client.
/// Shows historical reports and allows generating new comprehensive analyses.
class TrainerClientAnalysisScreen extends ConsumerStatefulWidget {
  final String clientId;

  const TrainerClientAnalysisScreen({
    super.key,
    required this.clientId,
  });

  @override
  ConsumerState<TrainerClientAnalysisScreen> createState() =>
      _TrainerClientAnalysisScreenState();
}

class _TrainerClientAnalysisScreenState
    extends ConsumerState<TrainerClientAnalysisScreen> {
  @override
  Widget build(BuildContext context) {
    final colors = context.fitTheme;
    final clientAsync = ref.watch(trainerClientByIdProvider(widget.clientId));
    final reportsAsync =
        ref.watch(clientAnalysisReportsProvider(widget.clientId));
    final analysisState = ref.watch(trainerAnalysisNotifierProvider);
    final gym = ref.watch(selectedGymProvider);

    return Scaffold(
      backgroundColor: colors.background,
      body: CustomScrollView(
        slivers: [
          // App bar
          SliverAppBar(
            pinned: true,
            backgroundColor: colors.surface,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_rounded, color: colors.textPrimary),
              onPressed: () => context.pop(),
            ),
            title: Text(
              'AI Analysis',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.help_outline_rounded, color: colors.textMuted),
                onPressed: () => _showHelpDialog(context),
              ),
            ],
          ),

          // Content
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverToBoxAdapter(
              child: clientAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (e, _) => _ErrorCard(
                  message: 'Failed to load client: $e',
                  onRetry: () => ref
                      .invalidate(trainerClientByIdProvider(widget.clientId)),
                ),
                data: (client) {
                  if (client == null) {
                    return _ErrorCard(
                      message: 'Client not found',
                      onRetry: () => context.pop(),
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Client header card
                      _ClientHeaderCard(client: client),
                      const SizedBox(height: 20),

                      // Generate new analysis button
                      _GenerateAnalysisCard(
                        client: client,
                        gymId: gym?.id ?? '',
                        isLoading: analysisState.isLoading,
                        onGenerate: () =>
                            _generateAnalysis(client, gym?.id ?? ''),
                      ),
                      const SizedBox(height: 24),

                      // Latest report (if analysis just generated)
                      if (analysisState.hasValue && analysisState.value != null)
                        _ReportDetailCard(
                          report: analysisState.value!,
                          isLatest: true,
                        ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),

                      // Historical reports
                      Text(
                        'Report History',
                        style: GoogleFonts.inter(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),

                      reportsAsync.when(
                        loading: () => const Padding(
                          padding: EdgeInsets.all(20),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                        error: (e, _) => _ErrorCard(
                          message: 'Failed to load reports: $e',
                          onRetry: () => ref.invalidate(
                              clientAnalysisReportsProvider(widget.clientId)),
                        ),
                        data: (reports) {
                          if (reports.isEmpty) {
                            return _EmptyReportsCard();
                          }

                          return Column(
                            children: [
                              for (var i = 0; i < reports.length; i++) ...[
                                _ReportSummaryCard(
                                  report: reports[i],
                                  onTap: () {
                                    _showReportBottomSheet(context, reports[i]);
                                  },
                                )
                                    .animate(delay: (i * 100).ms)
                                    .fadeIn()
                                    .slideX(begin: 0.05),
                                if (i < reports.length - 1)
                                  const SizedBox(height: 12),
                              ],
                            ],
                          );
                        },
                      ),

                      const SizedBox(height: 100), // Bottom padding
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _generateAnalysis(ClientProfile client, String gymId) async {
    final notifier = ref.read(trainerAnalysisNotifierProvider.notifier);
    final report = await notifier.generateAnalysis(
      client: client,
      gymId: gymId,
    );

    if (report != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Analysis generated! Score: ${report.overallScore}/100'),
          backgroundColor: context.fitTheme.accent,
        ),
      );
    }
  }

  void _showHelpDialog(BuildContext context) {
    final colors = context.fitTheme;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surface,
        title: Text(
          'About AI Analysis',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
        content: Text(
          'The AI Analysis generates a comprehensive report based on:\n\n'
          '• Assigned workout & diet plans\n'
          '• Gym check-in attendance\n'
          '• Body measurements\n'
          '• Personal records achieved\n'
          '• Hydration tracking\n'
          '• Sleep & activity data\n\n'
          'Reports are visible to both you and the client.',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: colors.textSecondary,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Got it',
              style: TextStyle(color: colors.brand),
            ),
          ),
        ],
      ),
    );
  }

  void _showReportBottomSheet(
      BuildContext context, TrainerAnalysisReport report) {
    final colors = context.fitTheme;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, scrollController) => Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(20),
            child: _ReportDetailCard(report: report, isLatest: false),
          ),
        ),
      ),
    );
  }
}

// ─── CLIENT HEADER CARD ─────────────────────────────────────────────────────

class _ClientHeaderCard extends StatelessWidget {
  final ClientProfile client;

  const _ClientHeaderCard({required this.client});

  @override
  Widget build(BuildContext context) {
    final colors = context.fitTheme;
    return GlassmorphicCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: colors.brand.withOpacity(0.2),
              child: Text(
                (client.fullName?.isNotEmpty ?? false)
                    ? client.fullName![0].toUpperCase()
                    : 'C',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: colors.brand,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    client.fullName ?? 'Client',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    client.email ?? '',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: colors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _InfoChip(
                        icon: Icons.fitness_center_rounded,
                        label: client.goal.label,
                      ),
                      const SizedBox(width: 8),
                      _InfoChip(
                        icon: Icons.calendar_today_rounded,
                        label: '${client.daysPerWeek}x/week',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final colors = context.fitTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: colors.surfaceAlt,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: colors.textMuted),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── GENERATE ANALYSIS CARD ─────────────────────────────────────────────────

class _GenerateAnalysisCard extends StatelessWidget {
  final ClientProfile client;
  final String gymId;
  final bool isLoading;
  final VoidCallback onGenerate;

  const _GenerateAnalysisCard({
    required this.client,
    required this.gymId,
    required this.isLoading,
    required this.onGenerate,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.fitTheme;
    return GlassmorphicCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: colors.brandGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Generate AI Analysis',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Comprehensive progress report',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: colors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Analyzes last 30 days of gym activity, body measurements, personal records, and plan adherence.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: colors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : onGenerate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.brand,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: isLoading
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Analyzing...',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.psychology_rounded, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Generate Report',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── REPORT SUMMARY CARD ────────────────────────────────────────────────────

class _ReportSummaryCard extends StatelessWidget {
  final TrainerAnalysisReport report;
  final VoidCallback onTap;

  const _ReportSummaryCard({
    required this.report,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.fitTheme;
    final dateStr = DateFormat('MMM d, yyyy').format(report.createdAt);
    final scoreColor = _getScoreColor(report.overallScore, colors);

    return GlassmorphicCard(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Score circle
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: scoreColor, width: 3),
              ),
              child: Center(
                child: Text(
                  '${report.overallScore}',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: scoreColor,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        report.scoreCategory,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: scoreColor,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        dateStr,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: colors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    report.summary ?? 'View full report',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: colors.textSecondary,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Mini score bars
                  Row(
                    children: [
                      _MiniScoreBar(
                        label: 'Workout',
                        value: report.workoutAdherenceScore,
                        color: colors.brand,
                      ),
                      const SizedBox(width: 12),
                      _MiniScoreBar(
                        label: 'Diet',
                        value: report.dietAdherenceScore,
                        color: colors.accent,
                      ),
                      const SizedBox(width: 12),
                      _MiniScoreBar(
                        label: 'Progress',
                        value: report.progressScore,
                        color: colors.warning,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              color: colors.textMuted,
            ),
          ],
        ),
      ),
    );
  }

  Color _getScoreColor(int score, dynamic colors) {
    if (score >= 80) return colors.accent as Color;
    if (score >= 60) return colors.brand as Color;
    if (score >= 40) return colors.warning as Color;
    return colors.danger as Color;
  }
}

class _MiniScoreBar extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _MiniScoreBar({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.fitTheme;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: colors.textMuted,
            ),
          ),
          const SizedBox(height: 3),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value / 100,
              minHeight: 4,
              backgroundColor: colors.ringTrack,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── REPORT DETAIL CARD ─────────────────────────────────────────────────────

class _ReportDetailCard extends StatelessWidget {
  final TrainerAnalysisReport report;
  final bool isLatest;

  const _ReportDetailCard({
    required this.report,
    this.isLatest = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.fitTheme;
    final dateStr =
        DateFormat('MMMM d, yyyy · h:mm a').format(report.createdAt);
    final scoreColor = _getScoreColor(report.overallScore, colors);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isLatest) ...[
          Row(
            children: [
              Icon(Icons.auto_awesome_rounded, color: colors.brand, size: 18),
              const SizedBox(width: 8),
              Text(
                'New Analysis Generated',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: colors.brand,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],

        // Header with score
        GlassmorphicCard(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Big score circle
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: scoreColor, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: scoreColor.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${report.overallScore}',
                          style: GoogleFonts.inter(
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                            color: scoreColor,
                          ),
                        ),
                        Text(
                          'SCORE',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: colors.textMuted,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  report.scoreCategory,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: scoreColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  dateStr,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: colors.textMuted,
                  ),
                ),
                const SizedBox(height: 20),

                // Score breakdown
                Row(
                  children: [
                    _ScoreBreakdownItem(
                      label: 'Workout',
                      value: report.workoutAdherenceScore,
                      color: colors.brand,
                    ),
                    _ScoreBreakdownItem(
                      label: 'Diet',
                      value: report.dietAdherenceScore,
                      color: colors.accent,
                    ),
                    _ScoreBreakdownItem(
                      label: 'Progress',
                      value: report.progressScore,
                      color: colors.warning,
                    ),
                    _ScoreBreakdownItem(
                      label: 'Consistency',
                      value: report.consistencyScore,
                      color: colors.info,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Summary
        if (report.summary != null && report.summary!.isNotEmpty) ...[
          _SectionCard(
            icon: Icons.summarize_rounded,
            title: 'Summary',
            content: report.summary!,
          ),
          const SizedBox(height: 12),
        ],

        // Client message
        if (report.clientMessage != null &&
            report.clientMessage!.isNotEmpty) ...[
          _SectionCard(
            icon: Icons.message_rounded,
            title: 'Message for Client',
            content: report.clientMessage!,
            highlight: true,
          ),
          const SizedBox(height: 12),
        ],

        // Achievements
        if (report.achievements.isNotEmpty) ...[
          _ListSectionCard(
            icon: Icons.emoji_events_rounded,
            title: 'Achievements',
            items: report.achievements,
            itemIcon: Icons.star_rounded,
            itemColor: colors.warning,
          ),
          const SizedBox(height: 12),
        ],

        // Risk flags
        if (report.riskFlags.isNotEmpty) ...[
          _RiskFlagsCard(flags: report.riskFlags),
          const SizedBox(height: 12),
        ],

        // Immediate actions
        if (report.immediateActions.isNotEmpty) ...[
          _ListSectionCard(
            icon: Icons.priority_high_rounded,
            title: 'Immediate Actions',
            items: report.immediateActions,
            itemIcon: Icons.arrow_forward_rounded,
            itemColor: colors.brand,
          ),
          const SizedBox(height: 12),
        ],

        // Workout adjustments
        if (report.workoutAdjustments.isNotEmpty) ...[
          _ListSectionCard(
            icon: Icons.fitness_center_rounded,
            title: 'Workout Adjustments',
            items: report.workoutAdjustments,
            itemIcon: Icons.tune_rounded,
            itemColor: colors.brand,
          ),
          const SizedBox(height: 12),
        ],

        // Diet adjustments
        if (report.dietAdjustments.isNotEmpty) ...[
          _ListSectionCard(
            icon: Icons.restaurant_rounded,
            title: 'Diet Adjustments',
            items: report.dietAdjustments,
            itemIcon: Icons.tune_rounded,
            itemColor: colors.accent,
          ),
          const SizedBox(height: 12),
        ],

        // Next month priorities
        if (report.nextMonthPriorities.isNotEmpty) ...[
          _ListSectionCard(
            icon: Icons.calendar_month_rounded,
            title: 'Next Month Priorities',
            items: report.nextMonthPriorities,
            itemIcon: Icons.flag_rounded,
            itemColor: colors.info,
          ),
          const SizedBox(height: 12),
        ],

        // Generation metadata
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            'Generated using ${report.tokensUsed} tokens in ${report.generationMs}ms',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: colors.textMuted,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Color _getScoreColor(int score, dynamic colors) {
    if (score >= 80) return colors.accent as Color;
    if (score >= 60) return colors.brand as Color;
    if (score >= 40) return colors.warning as Color;
    return colors.danger as Color;
  }
}

class _ScoreBreakdownItem extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _ScoreBreakdownItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.fitTheme;
    return Expanded(
      child: Column(
        children: [
          Text(
            '$value',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: colors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String content;
  final bool highlight;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.content,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.fitTheme;
    return GlassmorphicCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon,
                    size: 18,
                    color: highlight ? colors.brand : colors.textMuted),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: highlight ? const EdgeInsets.all(12) : null,
              decoration: highlight
                  ? BoxDecoration(
                      color: colors.brand.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: colors.brand.withOpacity(0.2)),
                    )
                  : null,
              child: Text(
                content,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: colors.textSecondary,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ListSectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<String> items;
  final IconData itemIcon;
  final Color itemColor;

  const _ListSectionCard({
    required this.icon,
    required this.title,
    required this.items,
    required this.itemIcon,
    required this.itemColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.fitTheme;
    return GlassmorphicCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: itemColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            for (final item in items) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(itemIcon, size: 16, color: itemColor),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: colors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
              if (item != items.last) const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }
}

class _RiskFlagsCard extends StatelessWidget {
  final List<Map<String, dynamic>> flags;

  const _RiskFlagsCard({required this.flags});

  @override
  Widget build(BuildContext context) {
    final colors = context.fitTheme;
    return GlassmorphicCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber_rounded,
                    size: 18, color: colors.warning),
                const SizedBox(width: 8),
                Text(
                  'Risk Flags',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            for (final flag in flags) ...[
              _RiskFlagItem(flag: flag),
              if (flag != flags.last) const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}

class _RiskFlagItem extends StatelessWidget {
  final Map<String, dynamic> flag;

  const _RiskFlagItem({required this.flag});

  @override
  Widget build(BuildContext context) {
    final colors = context.fitTheme;
    final severity = flag['severity'] as String? ?? 'medium';
    final color = severity == 'high'
        ? colors.danger
        : severity == 'medium'
            ? colors.warning
            : colors.textMuted;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  severity.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: color,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  flag['category'] as String? ?? 'General',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            flag['message'] as String? ?? '',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: colors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── EMPTY & ERROR CARDS ────────────────────────────────────────────────────

class _EmptyReportsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.fitTheme;
    return GlassmorphicCard(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 48,
              color: colors.textMuted,
            ),
            const SizedBox(height: 16),
            Text(
              'No Reports Yet',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Generate your first AI analysis above to see insights about this client.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: colors.textMuted,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorCard({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.fitTheme;
    return GlassmorphicCard(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: colors.danger,
            ),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: colors.textMuted,
              ),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
              style: TextButton.styleFrom(foregroundColor: colors.brand),
            ),
          ],
        ),
      ),
    );
  }
}
