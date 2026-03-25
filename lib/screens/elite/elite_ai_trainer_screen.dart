import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/enums.dart';
import '../../core/extensions.dart';
import '../../models/client_profile_model.dart';
import '../../providers/ai_agent_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/member_provider.dart';

/// Elite: Advanced AI Personal Trainer — powered by NVIDIA-hosted Kimi.
class EliteAiTrainerScreen extends ConsumerStatefulWidget {
  const EliteAiTrainerScreen({super.key});
  @override
  ConsumerState<EliteAiTrainerScreen> createState() =>
      _EliteAiTrainerScreenState();
}

class _EliteAiTrainerScreenState extends ConsumerState<EliteAiTrainerScreen> {
  static const _elitePrimary = Color(0xFF9B5DE5);
  static const _eliteSecondary = Color(0xFF6A3DFF);

  // Chat history for multi-turn conversation
  final List<_ChatMsg> _messages = [];
  final _ctrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _loading = false;

  final _quickPrompts = [
    '🏋️ Build me a 4-week strength block for muscle gain',
    '🥗 Create a personalized Indian meal plan for fat loss',
    '📊 Analyse my progress and tell me what to change',
    '💊 What supplements should I take for my goals?',
    '🩺 I have a shoulder injury — modify my push day',
    '⚡ How do I peak for a fitness competition in 8 weeks?',
  ];

  @override
  void dispose() {
    _ctrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;
    return Scaffold(
      backgroundColor: t.background,
      appBar: AppBar(
        backgroundColor: t.background,
        leading: BackButton(color: t.textSecondary),
        title: Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [_elitePrimary, _eliteSecondary]),
              borderRadius: BorderRadius.circular(6),
              boxShadow: [
                BoxShadow(color: _elitePrimary.withOpacity(0.4), blurRadius: 8)
              ],
            ),
            child: Text('ELITE AI',
                style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 1)),
          ),
          const SizedBox(width: 10),
          Text('Personal Trainer',
              style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: t.textPrimary)),
        ]),
        actions: [
          if (_messages.isNotEmpty)
            IconButton(
              icon: Icon(Icons.clear_all_rounded, color: t.textSecondary),
              tooltip: 'Clear chat',
              onPressed: () => setState(() => _messages.clear()),
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // ─── Chat area
          Expanded(
            child: _messages.isEmpty
                ? _WelcomeView(
                    prompts: _quickPrompts,
                    onTap: _send,
                  )
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length + (_loading ? 1 : 0),
                    itemBuilder: (context, i) {
                      if (i == _messages.length) {
                        return _TypingIndicator();
                      }
                      final m = _messages[i];
                      return _ChatBubble(msg: m);
                    },
                  ),
          ),

          // ─── Input bar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            decoration: BoxDecoration(
              color: t.surfaceAlt,
              border: Border(top: BorderSide(color: t.border)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    style:
                        GoogleFonts.inter(color: t.textPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Ask your AI trainer...',
                      hintStyle:
                          GoogleFonts.inter(color: t.textMuted, fontSize: 13),
                      filled: true,
                      fillColor: t.surfaceMuted,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: _send,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _send(_ctrl.text),
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [_elitePrimary, _eliteSecondary]),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                            color: _elitePrimary.withOpacity(0.4),
                            blurRadius: 12)
                      ],
                    ),
                    child: _loading
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.send_rounded,
                            color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _send(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _loading) return;
    _ctrl.clear();

    setState(() {
      _messages.add(_ChatMsg(text: trimmed, isUser: true));
      _loading = true;
    });
    _scroll();

    try {
      final user = ref.read(currentUserProvider).value;
      final membership = await ref.read(memberMembershipProvider.future);

      final now = DateTime.now();
      final profile = ClientProfile(
        id: user?.id ?? 'unknown',
        userId: user?.id,
        gymId: membership?.gymId ?? 'unknown',
        fullName: user?.fullName,
        goal: FitnessGoal.generalFitness,
        trainingLevel: TrainingLevel.intermediate,
        daysPerWeek: 4,
        equipmentType: EquipmentType.fullGym,
        trainingTime: TrainingTime.morning,
        dietType: DietType.nonVegetarian,
        languagePreference: LanguagePreference.english,
        gymPlan: 'elite',
        aiQuotaRemaining: 50,
        createdAt: now,
        updatedAt: now,
      );

      // Build conversation history for multi-turn
      final history = <Map<String, String>>[];
      for (final m in _messages.take(_messages.length - 1)) {
        history.add({
          'role': m.isUser ? 'user' : 'assistant',
          'content': m.text,
        });
      }

      final reply = await ref.read(aiAgentServiceProvider).generateChatReply(
            client: profile,
            role: UserRole.client,
            userMessage: trimmed,
            conversationHistory: history,
          );

      setState(() => _messages.add(_ChatMsg(text: reply, isUser: false)));
    } catch (e) {
      setState(() => _messages.add(
            _ChatMsg(text: '⚠️ Error: $e', isUser: false, isError: true),
          ));
    } finally {
      setState(() => _loading = false);
      _scroll();
    }
  }

  void _scroll() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
}

// ─── Data model ───────────────────────────────────────────────────────────────
class _ChatMsg {
  final String text;
  final bool isUser;
  final bool isError;
  const _ChatMsg(
      {required this.text, required this.isUser, this.isError = false});
}

// ─── Widgets ──────────────────────────────────────────────────────────────────

class _WelcomeView extends StatelessWidget {
  final List<String> prompts;
  final void Function(String) onTap;
  const _WelcomeView({required this.prompts, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF9B5DE5), Color(0xFF6A3DFF)],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.psychology_rounded,
                color: Colors.white, size: 40),
          ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
          const SizedBox(height: 16),
          Text('Your Elite AI Trainer',
              style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: t.textPrimary)),
          const SizedBox(height: 6),
          Text(
            'Powered by NVIDIA-hosted Kimi — your dedicated fitness intelligence',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
                fontSize: 13, color: t.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 28),
          Text('QUICK STARTS',
              style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: t.textMuted,
                  letterSpacing: 1.2)),
          const SizedBox(height: 12),
          ...prompts.asMap().entries.map((e) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () => onTap(e.value),
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: t.surfaceAlt,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: t.border),
                  ),
                  child: Row(children: [
                    const Icon(Icons.bolt_rounded,
                        color: Color(0xFF9B5DE5), size: 16),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(e.value,
                          style: GoogleFonts.inter(
                              fontSize: 13, color: t.textSecondary)),
                    ),
                    Icon(Icons.play_arrow_rounded,
                        color: t.textMuted, size: 18),
                  ]),
                ).animate(delay: (e.key * 60).ms).fadeIn(),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final _ChatMsg msg;
  const _ChatBubble({required this.msg});

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;
    final isUser = msg.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: isUser
              ? const LinearGradient(
                  colors: [Color(0xFF9B5DE5), Color(0xFF6A3DFF)])
              : null,
          color: isUser ? null : t.surfaceAlt,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
          border: isUser ? null : Border.all(color: t.border),
        ),
        child: Text(msg.text,
            style: GoogleFonts.inter(
                fontSize: 14,
                color: isUser
                    ? Colors.white
                    : msg.isError
                        ? t.danger
                        : t.textPrimary,
                height: 1.5)),
      ).animate().fadeIn(duration: 200.ms).slideY(begin: 0.03),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: t.surfaceAlt,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: t.border),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                  color: Color(0xFF9B5DE5), strokeWidth: 2)),
          const SizedBox(width: 10),
          Text('AI is thinking...',
              style: GoogleFonts.inter(fontSize: 12, color: t.textMuted)),
        ]),
      ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 1200.ms),
    );
  }
}
