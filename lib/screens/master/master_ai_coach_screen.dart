import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/enums.dart';
import '../../core/extensions.dart';
import '../../models/client_profile_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/member_provider.dart';
import '../../services/claude_service.dart';
import '../../widgets/glassmorphic_card.dart';

/// Master: Full AI Fitness Coach — multi-turn chat + daily adaptive plan.
class MasterAiCoachScreen extends ConsumerStatefulWidget {
  const MasterAiCoachScreen({super.key});
  @override
  ConsumerState<MasterAiCoachScreen> createState() => _MasterAiCoachState();
}

class _MasterAiCoachState extends ConsumerState<MasterAiCoachScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  final List<_Msg> _chat = [];
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  bool _loading = false;
  String? _dailyPlan;
  bool _planLoading = false;

  static const _masterPrimary   = Color(0xFFFF3D5E);
  static const _masterSecondary = Color(0xFFFF8C00);

  final _quickStarts = [
    '🏆 Give me today\'s optimal workout based on my goals',
    '🍱 What should I eat for all meals today to hit my macros?',
    '📈 Analyse my progress and tell me what needs to change',
    '💪 I feel sore today — what\'s my modified training plan?',
    '🔥 Create an 8-week body recomposition program for me',
    '😴 How should I improve my sleep for better recovery?',
  ];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    _ctrl.dispose();
    _scroll.dispose();
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
              gradient: const LinearGradient(colors: [_masterPrimary, _masterSecondary]),
              borderRadius: BorderRadius.circular(6),
              boxShadow: [BoxShadow(
                  color: _masterPrimary.withOpacity(0.5), blurRadius: 10)],
            ),
            child: Text('MASTER AI', style: GoogleFonts.inter(
                fontSize: 9, fontWeight: FontWeight.w900,
                color: Colors.white, letterSpacing: 1.2)),
          ),
          const SizedBox(width: 10),
          Text('Fitness Coach', style: GoogleFonts.inter(
              fontSize: 18, fontWeight: FontWeight.w800,
              color: t.textPrimary)),
        ]),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: _masterPrimary,
          labelColor: _masterPrimary,
          unselectedLabelColor: t.textMuted,
          tabs: const [
            Tab(text: '💬 Coach Chat'),
            Tab(text: '📅 Daily Plan'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          // ─── Coach Chat
          Column(children: [
            Expanded(
              child: _chat.isEmpty
                  ? _WelcomeView(
                      prompts: _quickStarts,
                      onTap: _sendChat)
                  : ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.all(16),
                      itemCount: _chat.length + (_loading ? 1 : 0),
                      itemBuilder: (ctx, i) {
                        if (i == _chat.length) return _TypingBubble();
                        final m = _chat[i];
                        return _ChatBubble(msg: m);
                      },
                    ),
            ),
            _InputBar(
              ctrl: _ctrl,
              loading: _loading,
              onSend: _sendChat,
            ),
          ]),

          // ─── Daily Adaptive Plan
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              GlassmorphicCard(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      const Icon(Icons.bolt_rounded, color: _masterPrimary, size: 22),
                      const SizedBox(width: 10),
                      Text('Today\'s Adaptive Plan',
                          style: GoogleFonts.inter(fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: t.textPrimary)),
                    ]),
                    const SizedBox(height: 8),
                    Text('AI generates a fresh plan every day based on your fatigue, goals, and progress.',
                        style: GoogleFonts.inter(fontSize: 13,
                            color: t.textSecondary, height: 1.5)),
                  ]),
                ),
              ).animate().fadeIn(),
              const SizedBox(height: 16),
              if (_dailyPlan == null && !_planLoading)
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: _generateDailyPlan,
                    style: FilledButton.styleFrom(
                      backgroundColor: _masterPrimary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.auto_awesome_rounded, size: 20),
                    label: Text('Generate Today\'s Plan',
                        style: GoogleFonts.inter(
                            fontSize: 15, fontWeight: FontWeight.w800,
                            color: Colors.white)),
                  ).animate().fadeIn(),
                ),
              if (_planLoading)
                const Center(child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(color: _masterPrimary),
                )),
              if (_dailyPlan != null) ...[
                GlassmorphicCard(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                                colors: [_masterPrimary, _masterSecondary]),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.smart_toy_rounded,
                              color: Colors.white, size: 16),
                        ),
                        const SizedBox(width: 10),
                        Text('Your Adaptive Plan',
                            style: GoogleFonts.inter(fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: t.textPrimary)),
                        const Spacer(),
                        TextButton(
                          onPressed: () =>
                              setState(() => _dailyPlan = null),
                          child: Text('Regenerate',
                              style: GoogleFonts.inter(
                                  fontSize: 12, color: _masterPrimary)),
                        ),
                      ]),
                      Divider(color: t.divider),
                      Text(_dailyPlan!,
                          style: GoogleFonts.inter(fontSize: 14,
                              color: t.textSecondary, height: 1.6)),
                    ]),
                  ),
                ).animate().fadeIn().slideY(begin: 0.04),
              ],
            ]),
          ),
        ],
      ),
    );
  }

  Future<void> _sendChat(String text) async {
    final t = text.trim();
    if (t.isEmpty || _loading) return;
    _ctrl.clear();
    setState(() { _chat.add(_Msg(t, true)); _loading = true; });
    _scrollToBottom();
    try {
      final reply = await _callAI(t, asMaster: true);
      setState(() => _chat.add(_Msg(reply, false)));
    } catch (e) {
      setState(() => _chat.add(_Msg('⚠️ Error: $e', false, isError: true)));
    } finally {
      setState(() => _loading = false);
      _scrollToBottom();
    }
  }

  Future<void> _generateDailyPlan() async {
    setState(() => _planLoading = true);
    try {
      final plan = await _callAI(
        'Generate my complete adaptive workout and nutrition plan for today. '
        'Structure it clearly: Morning routine, Workout (with sets/reps), '
        'Meals (breakfast/lunch/snack/dinner with calories), and Evening recovery tips.',
        asMaster: true,
      );
      setState(() => _dailyPlan = plan);
    } catch (e) {
      setState(() => _dailyPlan = '⚠️ $e');
    } finally {
      setState(() => _planLoading = false);
    }
  }

  Future<String> _callAI(String message, {bool asMaster = false}) async {
    final user = ref.read(currentUserProvider).value;
    final membership = await ref.read(memberMembershipProvider.future);
    final now = DateTime.now();
    final profile = ClientProfile(
      id: user?.id ?? 'unknown',
      userId: user?.id,
      gymId: membership?.gymId ?? 'unknown',
      fullName: user?.fullName,
      goal: FitnessGoal.muscleGain,
      trainingLevel: TrainingLevel.advanced,
      daysPerWeek: 5,
      equipmentType: EquipmentType.fullGym,
      trainingTime: TrainingTime.morning,
      dietType: DietType.nonVegetarian,
      languagePreference: LanguagePreference.english,
      gymPlan: 'master',
      aiQuotaRemaining: 100,
      createdAt: now,
      updatedAt: now,
    );
    final history = asMaster
        ? _chat.take(_chat.length - 1).map((m) =>
            {'role': m.isUser ? 'user' : 'assistant', 'content': m.text}).toList()
        : <Map<String, String>>[];
    return gymOSAI(
      client: profile,
      userRole: 'Master Member',
      userMessage: message,
      conversationHistory: history,
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut);
      }
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _Msg {
  final String text;
  final bool isUser;
  final bool isError;
  _Msg(this.text, this.isUser, {this.isError = false});
}

class _WelcomeView extends StatelessWidget {
  final List<String> prompts;
  final void Function(String) onTap;
  const _WelcomeView({required this.prompts, required this.onTap});
  static const _masterPrimary = Color(0xFFFF3D5E);
  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
              gradient: RadialGradient(
                  colors: [Color(0xFFFF3D5E), Color(0xFFFF8C00),
                      Color(0xFFB71C1C)]),
              shape: BoxShape.circle),
          child: const Icon(Icons.smart_toy_rounded,
              color: Colors.white, size: 40),
        ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
        const SizedBox(height: 14),
        Text('Master AI Fitness Coach',
            style: GoogleFonts.inter(fontSize: 20,
                fontWeight: FontWeight.w800,
                color: t.textPrimary)),
        const SizedBox(height: 6),
        Text('Your 24/7 AI coach — powered by the most advanced AI model',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 13,
                color: t.textSecondary, height: 1.5)),
        const SizedBox(height: 28),
        Text('QUICK STARTS', style: GoogleFonts.inter(
            fontSize: 11, fontWeight: FontWeight.w700,
            color: t.textMuted, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        ...prompts.asMap().entries.map((e) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: GestureDetector(
            onTap: () => onTap(e.value),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              decoration: BoxDecoration(
                color: t.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: t.border),
              ),
              child: Row(children: [
                const Icon(Icons.bolt_rounded, color: _masterPrimary, size: 16),
                const SizedBox(width: 10),
                Expanded(child: Text(e.value,
                    style: GoogleFonts.inter(fontSize: 13,
                        color: t.textSecondary))),
                Icon(Icons.play_arrow_rounded,
                    color: t.textMuted, size: 18),
              ]),
            ).animate(delay: (e.key * 60).ms).fadeIn(),
          ),
        )),
      ]),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final _Msg msg;
  const _ChatBubble({required this.msg});
  static const _masterPrimary = Color(0xFFFF3D5E);
  static const _masterSecondary = Color(0xFFFF8C00);
  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;
    final isUser = msg.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.82),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: isUser ? const LinearGradient(
              colors: [_masterPrimary, _masterSecondary]) : null,
          color: isUser ? null : t.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
          border: isUser ? null : Border.all(color: t.border),
        ),
        child: Text(msg.text,
            style: GoogleFonts.inter(fontSize: 14,
                color: isUser ? Colors.white
                    : msg.isError ? t.danger
                    : t.textPrimary,
                height: 1.5)),
      ).animate().fadeIn(duration: 200.ms),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: t.border),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(width: 18, height: 18,
              child: CircularProgressIndicator(
                  color: Color(0xFFFF3D5E), strokeWidth: 2)),
          const SizedBox(width: 10),
          Text('Coach is thinking...',
              style: GoogleFonts.inter(fontSize: 12,
                  color: t.textMuted)),
        ]),
      ).animate(onPlay: (c) => c.repeat())
          .shimmer(duration: 1200.ms),
    );
  }
}

class _InputBar extends StatelessWidget {
  final TextEditingController ctrl;
  final bool loading;
  final void Function(String) onSend;
  const _InputBar({required this.ctrl, required this.loading, required this.onSend});
  static const _masterPrimary = Color(0xFFFF3D5E);
  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      decoration: BoxDecoration(
        color: t.surface,
        border: Border(top: BorderSide(color: t.border)),
      ),
      child: Row(children: [
        Expanded(
          child: TextField(
            controller: ctrl,
            style: GoogleFonts.inter(
                color: t.textPrimary, fontSize: 14),
            onSubmitted: onSend,
            decoration: InputDecoration(
              hintText: 'Ask your Master AI coach...',
              hintStyle: GoogleFonts.inter(
                  color: t.textMuted, fontSize: 13),
              filled: true,
              fillColor: t.surfaceMuted,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 10),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none),
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => onSend(ctrl.text),
          child: Container(
            width: 46, height: 46,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [_masterPrimary, Color(0xFFFF8C00)]),
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(
                  color: _masterPrimary.withOpacity(0.5), blurRadius: 12)],
            ),
            child: loading
                ? const Padding(padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.send_rounded,
                    color: Colors.white, size: 20),
          ),
        ),
      ]),
    );
  }
}
