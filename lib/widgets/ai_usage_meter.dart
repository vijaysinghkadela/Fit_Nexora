import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/extensions.dart';

/// Displays AI usage meter on the dashboard.
class AiUsageMeter extends StatelessWidget {
  final Map<String, dynamic> usage;

  const AiUsageMeter({super.key, required this.usage});

  @override
  Widget build(BuildContext context) {
    final colors = context.fitTheme;
    final hasAccess = usage['has_ai_access'] as bool? ?? false;
    final hasOpus = usage['has_opus_access'] as bool? ?? false;

    if (!hasAccess) {
      return _buildNoAccessCard(context);
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: colors.warning, size: 20),
              const SizedBox(width: 8),
              Text(
                'AI Usage This Month',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (hasOpus) ...[
            _buildUsageBar(
              context: context,
              label: 'Opus Calls',
              used: usage['opus_used'] as int? ?? 0,
              limit: usage['opus_limit'] as int? ?? 0,
              percent: (usage['opus_percent'] as num?)?.toDouble() ?? 0,
              color: colors.brand,
            ),
            const SizedBox(height: 14),
          ],
          _buildUsageBar(
            context: context,
            label: 'Haiku Calls',
            used: usage['haiku_used'] as int? ?? 0,
            limit: usage['haiku_limit'] as int? ?? 0,
            percent: _haikuPercent,
            color: colors.accent,
            isUnlimited: (usage['haiku_limit'] as int? ?? 0) == -1,
          ),
          const SizedBox(height: 14),
          _buildUsageBar(
            context: context,
            label: 'Token Budget',
            used: usage['tokens_used'] as int? ?? 0,
            limit: usage['token_limit'] as int? ?? 0,
            percent: (usage['token_percent'] as num?)?.toDouble() ?? 0,
            color: colors.info,
            formatUsed: _formatTokens,
          ),
          if ((usage['overage_charges'] as num?)?.toDouble() != null &&
              (usage['overage_charges'] as num).toDouble() > 0) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.warning.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: colors.warning.withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 16,
                    color: colors.warning,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Overage: \$${(usage['overage_charges'] as num).toStringAsFixed(2)}',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: colors.warning,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    ).animate(delay: 500.ms).fadeIn().slideY(begin: 0.05, end: 0);
  }

  double get _haikuPercent {
    final limit = usage['haiku_limit'] as int? ?? 0;
    if (limit == -1 || limit == 0) return 0;
    return ((usage['haiku_used'] as int? ?? 0) / limit * 100).clamp(0, 100);
  }

  Widget _buildNoAccessCard(BuildContext context) {
    final colors = context.fitTheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.textMuted.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.lock_outline_rounded,
              color: colors.textMuted,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Features Locked',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Upgrade to Pro for AI-powered plan generation',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: colors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate(delay: 500.ms).fadeIn();
  }

  Widget _buildUsageBar({
    required BuildContext context,
    required String label,
    required int used,
    required int limit,
    required double percent,
    required Color color,
    bool isUnlimited = false,
    String Function(int)? formatUsed,
  }) {
    final colors = context.fitTheme;
    final displayUsed = formatUsed?.call(used) ?? '$used';
    final displayLimit =
        isUnlimited ? 'INF' : (formatUsed?.call(limit) ?? '$limit');
    final barPercent = isUnlimited ? 0.0 : percent / 100;
    final isWarning = percent > 80;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: colors.textSecondary,
              ),
            ),
            Text(
              '$displayUsed / $displayLimit',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isWarning ? colors.warning : colors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: barPercent.clamp(0, 1),
            minHeight: 6,
            backgroundColor: colors.ringTrack,
            valueColor: AlwaysStoppedAnimation<Color>(
              isWarning ? colors.warning : color,
            ),
          ),
        ),
      ],
    );
  }

  String _formatTokens(int tokens) {
    if (tokens >= 1000000) {
      return '${(tokens / 1000000).toStringAsFixed(1)}M';
    }
    if (tokens >= 1000) {
      return '${(tokens / 1000).toStringAsFixed(0)}K';
    }
    return '$tokens';
  }
}
