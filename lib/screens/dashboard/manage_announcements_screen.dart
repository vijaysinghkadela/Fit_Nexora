import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/extensions.dart';
import '../../core/enums.dart';
import '../../models/announcement_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/gym_provider.dart';
import '../../widgets/glassmorphic_card.dart';
import '../../widgets/shared_management_wrapper.dart';

class ManageAnnouncementsScreen extends ConsumerStatefulWidget {
  const ManageAnnouncementsScreen({super.key});

  @override
  ConsumerState<ManageAnnouncementsScreen> createState() =>
      _ManageAnnouncementsScreenState();
}

class _ManageAnnouncementsScreenState
    extends ConsumerState<ManageAnnouncementsScreen> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  bool _isPinned = false;
  bool _isAppUpdate = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  void _showCreateDialog(BuildContext context, {bool isSuperAdmin = false}) {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          final t = context.fitTheme;
          return AlertDialog(
            backgroundColor: t.surfaceAlt,
            title: Text('New Announcement',
                style: GoogleFonts.inter(color: t.textPrimary)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _titleController,
                    style: GoogleFonts.inter(color: t.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Title',
                      labelStyle: GoogleFonts.inter(color: t.textSecondary),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _bodyController,
                    maxLines: 4,
                    style: GoogleFonts.inter(color: t.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Message (Optional)',
                      labelStyle: GoogleFonts.inter(color: t.textSecondary),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: Text('Pin to top',
                        style: GoogleFonts.inter(color: t.textPrimary)),
                    value: _isPinned,
                    onChanged: (v) => setState(() => _isPinned = v),
                    activeColor: t.brand,
                  ),
                  if (isSuperAdmin)
                    SwitchListTile(
                      title: Text('App Update (Global)',
                          style: GoogleFonts.inter(color: t.brand)),
                      subtitle: Text('Visible to ALL users',
                          style: GoogleFonts.inter(
                              color: t.textSecondary, fontSize: 12)),
                      value: _isAppUpdate,
                      onChanged: (v) => setState(() => _isAppUpdate = v),
                      activeColor: t.brand,
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Cancel',
                    style: GoogleFonts.inter(color: t.textSecondary)),
              ),
              FilledButton(
                onPressed: _isLoading
                    ? null
                    : () async {
                        if (_titleController.text.trim().isEmpty) return;
                        setState(() => _isLoading = true);
                        try {
                          final gym = ref.read(selectedGymProvider);
                          final client = Supabase.instance.client;

                          // Type defaults to gym, unless superAdmin checked App Update
                          final String type = _isAppUpdate ? 'app' : 'gym';
                          // If it's an app update, gymId should be null
                          final String? targetGymId =
                              type == 'app' ? null : gym?.id;

                          await client.from('gym_announcements').insert({
                            'gym_id': targetGymId,
                            'title': _titleController.text.trim(),
                            'body': _bodyController.text.trim(),
                            'is_pinned': _isPinned,
                            'announcement_type': type,
                          });
                          if (ctx.mounted) {
                            Navigator.pop(ctx);
                          }
                          if (mounted) {
                            _titleController.clear();
                            _bodyController.clear();
                            _isPinned = false;
                            this.setState(() {}); // refresh the list
                          }
                        } finally {
                          if (mounted) {
                            setState(() => _isLoading = false);
                          }
                        }
                      },
                child: _isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Publish'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;
    final user = ref.watch(currentUserProvider).value;
    final isSuperAdmin = user?.globalRole == UserRole.superAdmin;
    final gym = ref.watch(selectedGymProvider);

    // Fallback if no gym and not superadmin
    if (gym == null && !isSuperAdmin) {
      return Scaffold(
        backgroundColor: t.background,
        appBar: AppBar(
            title: const Text('Announcements'), backgroundColor: t.background),
        body: Center(
            child: Text('No gym selected.',
                style: GoogleFonts.inter(color: t.textMuted))),
      );
    }

    return SharedManagementWrapper(
      currentRoute: '/manage-announcements',
      child: Scaffold(
        backgroundColor: Colors.transparent,
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () =>
              _showCreateDialog(context, isSuperAdmin: isSuperAdmin),
          backgroundColor: t.brand,
          icon: const Icon(Icons.add_rounded, color: Colors.white),
          label: Text('Create',
              style: GoogleFonts.inter(
                  color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Announcements',
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: t.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isSuperAdmin
                        ? 'Manage global app updates and gym announcements'
                        : 'Manage your gym announcements',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: t.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _AnnouncementList(
                gymId: gym?.id,
                isSuperAdmin: isSuperAdmin,
                onDelete: () => setState(() {}),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnnouncementList extends ConsumerWidget {
  const _AnnouncementList({
    this.gymId,
    required this.isSuperAdmin,
    required this.onDelete,
  });

  final String? gymId;
  final bool isSuperAdmin;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final client = Supabase.instance.client;
    final t = context.fitTheme;

    // Fetch stream of relevant announcements
    final stream = isSuperAdmin
        // Super admin sees all, or maybe just app ones? Let's show app ones + their own gym ones
        ? client
            .from('gym_announcements')
            .stream(primaryKey: ['id']).order('created_at', ascending: false)
        // Gym owner sees their gym + app ones (but they can't delete app ones)
        : client
            .from('gym_announcements')
            .stream(primaryKey: ['id']).order('created_at', ascending: false);

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
              child: Text('Error loading announcements',
                  style: GoogleFonts.inter(color: t.danger)));
        }

        final items = snapshot.data ?? [];

        // Filter locally just to be safe if RLS doesn't catch it correctly in streams
        final filteredItems = items.where((i) {
          if (isSuperAdmin) return true; // super admin sees everything
          return i['gym_id'] == gymId || i['announcement_type'] == 'app';
        }).toList();

        if (filteredItems.isEmpty) {
          return Center(
            child: Text('No announcements found.',
                style: GoogleFonts.inter(color: t.textMuted)),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8)
              .copyWith(bottom: 100),
          itemCount: filteredItems.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final data = filteredItems[index];
            final item = Announcement.fromJson(data);
            final isAppUpdate = item.type == 'app';
            final canDelete =
                isSuperAdmin || (!isAppUpdate && item.gymId == gymId);

            return GlassmorphicCard(
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isAppUpdate
                        ? t.brand.withOpacity(0.12)
                        : (item.isPinned
                            ? t.warning.withOpacity(0.12)
                            : t.info.withOpacity(0.12)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isAppUpdate
                        ? Icons.system_update_rounded
                        : (item.isPinned
                            ? Icons.push_pin_rounded
                            : Icons.campaign_rounded),
                    color: isAppUpdate
                        ? t.brand
                        : (item.isPinned ? t.warning : t.info),
                  ),
                ),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700, color: t.textPrimary),
                      ),
                    ),
                    if (isAppUpdate)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                            color: t.brand,
                            borderRadius: BorderRadius.circular(4)),
                        child: Text('APP',
                            style: GoogleFonts.inter(
                                fontSize: 10,
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                      )
                    else if (item.isPinned)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                            color: t.warning.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4)),
                        child: Text('PINNED',
                            style: GoogleFonts.inter(
                                fontSize: 10,
                                color: t.warning,
                                fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
                subtitle: item.body != null && item.body!.isNotEmpty
                    ? Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(item.body!,
                            style: GoogleFonts.inter(color: t.textSecondary)),
                      )
                    : null,
                trailing: canDelete
                    ? IconButton(
                        icon:
                            Icon(Icons.delete_outline_rounded, color: t.danger),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              backgroundColor: t.surfaceAlt,
                              title: Text('Delete Announcement?',
                                  style:
                                      GoogleFonts.inter(color: t.textPrimary)),
                              actions: [
                                TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text('Cancel')),
                                TextButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: Text('Delete',
                                        style: TextStyle(color: t.danger))),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            await client
                                .from('gym_announcements')
                                .delete()
                                .eq('id', item.id);
                            onDelete();
                          }
                        },
                      )
                    : const SizedBox.shrink(),
              ),
            );
          },
        );
      },
    );
  }
}
