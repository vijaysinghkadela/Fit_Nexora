import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/database_values.dart';
import '../../core/extensions.dart';
import '../../providers/auth_provider.dart';
import '../../providers/gym_provider.dart';
import '../../providers/elite_member_provider.dart';


/// Elite: Real-time Trainer Chat — messages sync via Supabase Realtime.
class EliteChatScreen extends ConsumerStatefulWidget {
  const EliteChatScreen({super.key});
  @override
  ConsumerState<EliteChatScreen> createState() => _EliteChatScreenState();
}

class _EliteChatScreenState extends ConsumerState<EliteChatScreen> {
  final _ctrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _sending = false;

  static const _purple = Color(0xFF9C27B0);

  @override
  void dispose() {
    _ctrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;
    final user = ref.watch(currentUserProvider).value;
    final chatAsync = ref.watch(eliteTrainerChatProvider);

    return Scaffold(
      backgroundColor: t.background,
      appBar: AppBar(
        backgroundColor: t.surfaceAlt,
        leading: BackButton(color: t.textSecondary),
        title: Row(children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: _purple.withOpacity(0.2),
            child: const Icon(Icons.person_rounded, color: _purple, size: 20),
          ),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Your Trainer',
                style: GoogleFonts.inter(
                    fontSize: 15, fontWeight: FontWeight.w700,
                    color: t.textPrimary)),
            Row(children: [
              Container(
                width: 8, height: 8,
                decoration: BoxDecoration(
                    color: t.success, shape: BoxShape.circle),
              ),
              const SizedBox(width: 4),
              Text('Elite Support',
                  style: GoogleFonts.inter(
                      fontSize: 11, color: t.success)),
            ]),
          ]),
        ]),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: t.border),
        ),
      ),
      body: Column(
        children: [
          // ─── Messages list
          Expanded(
            child: chatAsync.when(
              loading: () => Center(
                  child: CircularProgressIndicator(color: t.brand)),
              error: (e, _) => Center(
                  child: Text('$e',
                      style: GoogleFonts.inter(color: t.danger))),
              data: (msgs) {
                if (msgs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: _purple.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.chat_rounded,
                              size: 40, color: _purple),
                        ).animate().scale(
                              duration: 500.ms,
                              curve: Curves.elasticOut),
                        const SizedBox(height: 16),
                        Text('Start the conversation!',
                            style: GoogleFonts.inter(
                                fontSize: 16, fontWeight: FontWeight.w700,
                                color: t.textPrimary)),
                        const SizedBox(height: 6),
                        Text('Your trainer will respond as soon as possible',
                            style: GoogleFonts.inter(
                                fontSize: 13,
                                color: t.textSecondary)),
                      ],
                    ),
                  );
                }

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollCtrl.hasClients) {
                    _scrollCtrl.jumpTo(
                        _scrollCtrl.position.maxScrollExtent);
                  }
                });

                return ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.all(16),
                  itemCount: msgs.length,
                  itemBuilder: (context, i) {
                    final msg = msgs[i];
                    final isMe = msg['sender_id'] == user?.id;
                    return _MessageBubble(msg: msg, isMe: isMe);
                  },
                );
              },
            ),
          ),

          // ─── Input bar
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
            decoration: BoxDecoration(
              color: t.surfaceAlt,
              border: Border(
                  top: BorderSide(color: t.border)),
            ),
            child: SafeArea(
              top: false,
              child: Row(children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    style: GoogleFonts.inter(
                        color: t.textPrimary, fontSize: 14),
                    maxLines: 4,
                    minLines: 1,
                    textInputAction: TextInputAction.newline,
                    decoration: InputDecoration(
                      hintText: 'Message your trainer...',
                      hintStyle: GoogleFonts.inter(
                          color: t.textMuted, fontSize: 13),
                      filled: true,
                      fillColor: t.surfaceMuted,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _sending ? null : _send,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 46, height: 46,
                    decoration: BoxDecoration(
                      gradient: _sending
                          ? null
                          : const LinearGradient(
                              colors: [_purple, Color(0xFF3F51B5)]),
                      color: _sending ? t.surface : null,
                      shape: BoxShape.circle,
                      boxShadow: _sending ? null : [
                        BoxShadow(
                            color: _purple.withOpacity(0.4),
                            blurRadius: 12),
                      ],
                    ),
                    child: _sending
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.send_rounded,
                            color: Colors.white, size: 20),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    final user = ref.read(currentUserProvider).value;
    final gym = ref.read(selectedGymProvider);
    if (user == null) return;

    _ctrl.clear();
    setState(() => _sending = true);
    try {
      final db = ref.read(databaseServiceProvider);
      await db.sendTrainerMessage(
        memberId: user.id,
        senderId: user.id,
        senderRole: DatabaseValues.trainerChatMemberRole,
        message: text,
        gymId: gym?.id,
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }
}

// ─── Message Bubble ───────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final Map<String, dynamic> msg;
  final bool isMe;
  const _MessageBubble({required this.msg, required this.isMe});

  static const _purple = Color(0xFF9C27B0);

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;
    final text = msg['message'] as String? ?? '';
    final createdAt = msg['created_at'] != null
        ? DateTime.tryParse(msg['created_at'] as String)
        : null;
    final timeStr = createdAt != null
        ? '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}'
        : '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: _purple.withOpacity(0.15),
              child: const Icon(Icons.person_rounded,
                  color: _purple, size: 16),
            ),
            const SizedBox(width: 8),
          ],
          Column(
            crossAxisAlignment:
                isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Container(
                constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.72),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  gradient: isMe
                      ? const LinearGradient(
                          colors: [_purple, Color(0xFF3F51B5)])
                      : null,
                  color: isMe ? null : t.surfaceAlt,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(isMe ? 16 : 4),
                    bottomRight: Radius.circular(isMe ? 4 : 16),
                  ),
                  border:
                      isMe ? null : Border.all(color: t.border),
                ),
                child: Text(text,
                    style: GoogleFonts.inter(
                        fontSize: 14,
                        color: isMe ? Colors.white : t.textPrimary,
                        height: 1.4)),
              ),
              const SizedBox(height: 3),
              Text(timeStr,
                  style: GoogleFonts.inter(
                      fontSize: 10, color: t.textMuted)),
            ],
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 14,
              backgroundColor: t.brand.withOpacity(0.15),
              child: Icon(Icons.face_rounded,
                  color: t.brand, size: 16),
            ),
          ],
        ],
      ).animate().fadeIn(duration: 200.ms),
    );
  }
}
