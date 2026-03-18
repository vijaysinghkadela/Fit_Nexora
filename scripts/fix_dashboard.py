import os

def main():
    path = r'lib\screens\dashboard\dashboard_screen.dart'
    with open(path, 'r', encoding='utf-8') as f:
        lines = f.readlines()
        
    start_idx = -1
    end_idx = -1
    for i, line in enumerate(lines):
        if 'static String _formatRevenue(int amount) {' in line:
            start_idx = i
            break
            
    for i in range(start_idx, len(lines)):
        if "class _GymOccupancyCard extends StatelessWidget {" in lines[i]:
            # we want to delete up to here and replace it
            end_idx = i - 1
            break
            
    if start_idx == -1 or end_idx == -1:
        print(f"Indices missing: {start_idx}, {end_idx}")
        return
        
    correct_block = """  static String _formatRevenue(int amount) {
    if (amount >= 100000) return '₹${(amount / 100000).toStringAsFixed(1)}L';
    if (amount >= 1000) return '₹${(amount / 1000).toStringAsFixed(1)}K';
    return '₹$amount';
  }
}

enum _CardTone { brand, success, warning, muted }
enum _FootnoteColor { success, muted }

class _StatCardData {
  const _StatCardData({
    required this.label,
    required this.value,
    required this.footnote,
    required this.footnoteColor,
    required this.tone,
    required this.icon,
  });

  final String label;
  final String value;
  final String footnote;
  final _FootnoteColor footnoteColor;
  final _CardTone tone;
  final IconData icon;
}

class _DashboardStatCard extends StatelessWidget {
  const _DashboardStatCard({required this.card});

  final _StatCardData card;

  @override
  Widget build(BuildContext context) {
    final colors = context.fitTheme;
    final accent = switch (card.tone) {
      _CardTone.brand => colors.brand,
      _CardTone.success => colors.accent,
      _CardTone.warning => colors.warning,
      _CardTone.muted => colors.textSecondary,
    };
    final noteColor = switch (card.footnoteColor) {
      _FootnoteColor.success => colors.accent,
      _FootnoteColor.muted => colors.textMuted,
    };

    return GlassmorphicCard(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(card.icon, size: 18, color: accent),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        card.label,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: colors.textMuted,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                card.value,
                style: GoogleFonts.inter(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: colors.textPrimary,
                  letterSpacing: -0.8,
                ),
              ),
            ),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                card.footnote,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: noteColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
"""
    # Replace the chunk
    new_lines = lines[:start_idx] + [correct_block] + lines[end_idx:]
    with open(path, 'w', encoding='utf-8') as f:
        f.writelines(new_lines)
    print("Fixed!")

if __name__ == '__main__':
    main()
