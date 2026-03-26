import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../core/extensions.dart';
import '../../widgets/glassmorphic_card.dart';

/// Master: Live Trainer Sessions — scheduling + priority support.
class MasterLiveSessionsScreen extends ConsumerWidget {
  const MasterLiveSessionsScreen({super.key});

  static const _masterPrimary = Color(0xFFE84F00);
  static const _masterSecondary = Color(0xFFFF7A2E);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.fitTheme;
    // Demo upcoming sessions
    final sessions = [
      (
        'Mon 17 Mar',
        '7:00 AM – 7:45 AM',
        'Workout Form Review',
        'Rahul Singh',
        t.brand,
        '🎥'
      ),
      (
        'Wed 19 Mar',
        '6:30 PM – 7:15 PM',
        'Nutrition Check-in',
        'Priya Mehta',
        t.success,
        '🥗'
      ),
      (
        'Sat 22 Mar',
        '10:00 AM – 11:00 AM',
        'Monthly Progress Review',
        'Rahul Singh',
        _masterPrimary,
        '📊'
      ),
    ];

    return Scaffold(
      backgroundColor: t.background,
      appBar: AppBar(
        backgroundColor: t.background,
        leading: BackButton(color: t.textSecondary),
        title: Text('Live Trainer Sessions',
            style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: t.textPrimary)),
        actions: [
          TextButton.icon(
            onPressed: () => _showBookSheet(context),
            icon: const Icon(Icons.add_rounded, size: 16),
            label: const Text('Book'),
            style: TextButton.styleFrom(foregroundColor: _masterPrimary),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // Intro card
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            sliver: SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    _masterPrimary.withOpacity(0.12),
                    _masterSecondary.withOpacity(0.06),
                  ]),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _masterPrimary.withOpacity(0.3)),
                ),
                child: Row(children: [
                  const Icon(Icons.video_call_rounded,
                      color: _masterPrimary, size: 32),
                  const SizedBox(width: 14),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text('1-on-1 Video Sessions',
                            style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: t.textPrimary)),
                        const SizedBox(height: 4),
                        Text(
                            'Schedule personalised video calls with your assigned trainer. Join via the link when it\'s time.',
                            style: GoogleFonts.inter(
                                fontSize: 12,
                                color: t.textSecondary,
                                height: 1.4)),
                      ])),
                ]),
              ).animate().fadeIn(),
            ),
          ),

          // Priority support
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            sliver: SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: t.accent.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: t.accent.withOpacity(0.25)),
                ),
                child: Row(children: [
                  Icon(Icons.support_agent_rounded, color: t.accent, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text('Priority Support Active',
                            style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: t.textPrimary)),
                        Text(
                            'Your messages to your trainer are marked PRIORITY — responses within 1 hour',
                            style: GoogleFonts.inter(
                                fontSize: 11,
                                color: t.textSecondary,
                                height: 1.4)),
                      ])),
                  Icon(Icons.verified_rounded, color: t.accent, size: 20),
                ]),
              ).animate(delay: 80.ms).fadeIn(),
            ),
          ),

          // Upcoming sessions
          _hdr('UPCOMING SESSIONS', t),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((ctx, i) {
                final (date, time, title, trainer, color, emoji) = sessions[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GlassmorphicCard(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Text(emoji, style: const TextStyle(fontSize: 26)),
                              const SizedBox(width: 12),
                              Expanded(
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                    Text(title,
                                        style: GoogleFonts.inter(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w800,
                                            color: t.textPrimary)),
                                    Text('with $trainer',
                                        style: GoogleFonts.inter(
                                            fontSize: 12,
                                            color: t.textSecondary)),
                                  ])),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text('Upcoming',
                                    style: GoogleFonts.inter(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: color)),
                              ),
                            ]),
                            const SizedBox(height: 12),
                            Divider(color: t.divider, height: 1),
                            const SizedBox(height: 10),
                            Row(children: [
                              _infoChip(
                                  Icons.calendar_today_rounded, date, color, t),
                              const SizedBox(width: 8),
                              _infoChip(
                                  Icons.access_time_rounded, time, color, t),
                            ]),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: const Text(
                                              'Session link will be sent 10 minutes before the session'),
                                          backgroundColor: t.info));
                                },
                                icon: const Icon(Icons.videocam_rounded,
                                    size: 18),
                                label: const Text('Join Session'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: color,
                                  side:
                                      BorderSide(color: color.withOpacity(0.5)),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ),
                          ]),
                    ),
                  ).animate(delay: (i * 80).ms).fadeIn(),
                );
              }, childCount: sessions.length),
            ),
          ),

          // How it works
          _hdr('HOW LIVE SESSIONS WORK', t),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
            sliver: SliverToBoxAdapter(
              child: GlassmorphicCard(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Builder(builder: (ctx) {
                    final tt = ctx.fitTheme;
                    return Column(children: [
                      _step('1', 'Tap "Book Session" to request a time',
                          tt.brand, tt),
                      _step(
                          '2', 'Trainer confirms within 2 hours', tt.info, tt),
                      _step('3', 'You get a video link 10 min before',
                          tt.accent, tt),
                      _step('4', 'Join and train with your trainer live',
                          tt.success, tt),
                    ]);
                  }),
                ),
              ).animate().fadeIn(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _hdr(String label, FitNexoraThemeTokens t) => SliverPadding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        sliver: SliverToBoxAdapter(
          child: Text(label,
              style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: t.textMuted,
                  letterSpacing: 1.2)),
        ),
      );

  Widget _infoChip(
      IconData icon, String label, Color c, FitNexoraThemeTokens t) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: c, size: 14),
      const SizedBox(width: 4),
      Text(label,
          style: GoogleFonts.inter(fontSize: 12, color: t.textSecondary)),
    ]);
  }

  Widget _step(String num, String text, Color c, FitNexoraThemeTokens t) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: c.withOpacity(0.15),
            shape: BoxShape.circle,
            border: Border.all(color: c.withOpacity(0.4)),
          ),
          child: Center(
              child: Text(num,
                  style: GoogleFonts.inter(
                      fontSize: 13, fontWeight: FontWeight.w900, color: c))),
        ),
        const SizedBox(width: 12),
        Expanded(
            child: Text(text,
                style:
                    GoogleFonts.inter(fontSize: 13, color: t.textSecondary))),
      ]),
    );
  }

  void _showBookSheet(BuildContext context) {
    final t = context.fitTheme;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: t.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Center(
              child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: t.textMuted.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 20),
          Text('Book a Session',
              style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: t.textPrimary)),
          const SizedBox(height: 16),
          Text(
              'Contact your trainer in the chat to schedule a live session. They will send you a calendar invite and video link.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  fontSize: 14, color: t.textSecondary, height: 1.5)),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              onPressed: () => Navigator.pop(context),
              style: FilledButton.styleFrom(
                backgroundColor: _masterPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.chat_rounded, size: 20),
              label: Text('Message Trainer',
                  style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.white)),
            ),
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }
}
