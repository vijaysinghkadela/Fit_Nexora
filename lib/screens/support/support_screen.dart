import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/extensions.dart';
import '../../config/theme.dart';
import '../../widgets/glassmorphic_card.dart';

/// Help & Support screen.
class SupportScreen extends ConsumerStatefulWidget {
  const SupportScreen({super.key});

  static const routePath = '/support';

  @override
  ConsumerState<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends ConsumerState<SupportScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  static const _faqs = [
    _FaqItem(
      question: 'How do I reset my password?',
      answer:
          'Go to the login screen and tap "Forgot Password". Enter your registered email address and we will send you a reset link within a few minutes.',
    ),
    _FaqItem(
      question: 'How to cancel subscription?',
      answer:
          'Navigate to Profile > Billing > Manage Subscription. From there you can cancel your active plan. Cancellation takes effect at the end of the current billing period.',
    ),
    _FaqItem(
      question: 'How to export my workout data?',
      answer:
          'Go to Profile > Settings > Export Data. You can export your workout history, nutrition logs, and progress photos as a CSV or PDF report.',
    ),
    _FaqItem(
      question: 'Why is AI not responding?',
      answer:
          'AI features require an active internet connection. If the issue persists, check your plan limits — free tier users have limited AI queries per month. Try restarting the app.',
    ),
    _FaqItem(
      question: 'How to add gym members?',
      answer:
          'From the gym dashboard, navigate to Clients > Add Client. Fill in the member details and select a membership plan. The member will receive an invite via email.',
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_FaqItem> get _filteredFaqs {
    if (_query.isEmpty) return _faqs;
    final q = _query.toLowerCase();
    return _faqs
        .where((f) =>
            f.question.toLowerCase().contains(q) ||
            f.answer.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
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
          'Help & Support',
          style: GoogleFonts.inter(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: t.textPrimary,
          ),
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                // Contact options row
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  sliver: SliverToBoxAdapter(
                    child: _ContactOptionsRow(t: t)
                        .animate()
                        .fadeIn(duration: 400.ms)
                        .slideY(begin: 0.1),
                  ),
                ),

                // FAQ search bar
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  sliver: SliverToBoxAdapter(
                    child: _SearchBar(
                      controller: _searchController,
                      t: t,
                      onChanged: (v) => setState(() => _query = v),
                    )
                        .animate(delay: 80.ms)
                        .fadeIn(duration: 400.ms)
                        .slideY(begin: 0.1),
                  ),
                ),

                // FAQ header
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                  sliver: SliverToBoxAdapter(
                    child: Text(
                      'FREQUENTLY ASKED QUESTIONS',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: t.textMuted,
                        letterSpacing: 1.2,
                      ),
                    ).animate(delay: 120.ms).fadeIn(duration: 400.ms),
                  ),
                ),

                // FAQ list
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  sliver: SliverToBoxAdapter(
                    child: _FaqList(faqs: _filteredFaqs, t: t)
                        .animate(delay: 160.ms)
                        .fadeIn(duration: 400.ms),
                  ),
                ),
              ],
            ),
          ),

          // Submit ticket button
          _SubmitTicketButton(t: t)
              .animate(delay: 400.ms)
              .fadeIn(duration: 400.ms)
              .slideY(begin: 0.15),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Contact options row
// ---------------------------------------------------------------------------

class _ContactOption {
  final IconData icon;
  final String label;
  final Color color;
  const _ContactOption({
    required this.icon,
    required this.label,
    required this.color,
  });
}

class _ContactOptionsRow extends StatelessWidget {
  final FitNexoraThemeTokens t;
  const _ContactOptionsRow({required this.t});

  @override
  Widget build(BuildContext context) {
    final options = [
      _ContactOption(icon: Icons.chat_bubble_outline_rounded, label: 'Chat', color: t.accent),
      _ContactOption(icon: Icons.email_outlined, label: 'Email', color: t.info),
      _ContactOption(icon: Icons.phone_outlined, label: 'Call', color: t.brand),
    ];

    return Row(
      children: options.asMap().entries.map((entry) {
        final i = entry.key;
        final opt = entry.value;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              left: i == 0 ? 0 : 6,
              right: i == options.length - 1 ? 0 : 6,
            ),
            child: GlassmorphicCard(
              onTap: () {},
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    vertical: 16, horizontal: 8),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: opt.color.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(opt.icon, color: opt.color, size: 22),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      opt.label,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: t.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Available',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: t.accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ---------------------------------------------------------------------------
// Search bar
// ---------------------------------------------------------------------------

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final FitNexoraThemeTokens t;
  final ValueChanged<String> onChanged;
  const _SearchBar({
    required this.controller,
    required this.t,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: t.border),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: GoogleFonts.inter(fontSize: 14, color: t.textPrimary),
        decoration: InputDecoration(
          hintText: 'Search FAQs...',
          hintStyle: GoogleFonts.inter(
            fontSize: 14,
            color: t.textMuted,
          ),
          prefixIcon: Icon(Icons.search_rounded, color: t.textMuted, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
              vertical: 14, horizontal: 16),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// FAQ list
// ---------------------------------------------------------------------------

class _FaqItem {
  final String question;
  final String answer;
  const _FaqItem({required this.question, required this.answer});
}

class _FaqList extends StatelessWidget {
  final List<_FaqItem> faqs;
  final FitNexoraThemeTokens t;
  const _FaqList({required this.faqs, required this.t});

  @override
  Widget build(BuildContext context) {
    if (faqs.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Text(
            'No results found',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: t.textMuted,
            ),
          ),
        ),
      );
    }

    return GlassmorphicCard(
      child: Column(
        children: faqs.asMap().entries.map((entry) {
          final i = entry.key;
          final faq = entry.value;
          return Column(
            children: [
              Theme(
                data: Theme.of(context).copyWith(
                  dividerColor: Colors.transparent,
                ),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 4),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                  title: Text(
                    faq.question,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: t.textPrimary,
                    ),
                  ),
                  iconColor: t.brand,
                  collapsedIconColor: t.textMuted,
                  expandedCrossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      faq.answer,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: t.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              if (i < faqs.length - 1)
                Divider(
                  height: 1,
                  thickness: 1,
                  indent: 16,
                  endIndent: 16,
                  color: t.divider,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Submit ticket button
// ---------------------------------------------------------------------------

class _SubmitTicketButton extends StatelessWidget {
  final FitNexoraThemeTokens t;
  const _SubmitTicketButton({required this.t});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      color: t.background,
      child: OutlinedButton.icon(
        onPressed: () {},
        icon: Icon(Icons.confirmation_number_outlined, color: t.brand),
        label: Text(
          'Submit a Ticket',
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: t.brand,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: t.brand, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}
