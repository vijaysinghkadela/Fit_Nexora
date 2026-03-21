import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/extensions.dart';
import '../../providers/notes_provider.dart';
import '../../widgets/glassmorphic_card.dart';

const _allTags = ['All', 'Workout', 'Diet', 'Personal', 'Goals'];

class NotesScreen extends ConsumerStatefulWidget {
  const NotesScreen({super.key});

  @override
  ConsumerState<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends ConsumerState<NotesScreen> {
  String _selectedTag = 'All';
  bool _showSearch = false;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;
    final notes = ref.watch(notesProvider);

    // Filter notes
    List<Note> filtered = _selectedTag == 'All'
        ? notes
        : notes.where((n) => n.tags.contains(_selectedTag)).toList();
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered
          .where((n) =>
              n.title.toLowerCase().contains(q) ||
              n.body.toLowerCase().contains(q))
          .toList();
    }

    return Scaffold(
      backgroundColor: t.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            backgroundColor: t.surface,
            title: _showSearch
                ? TextField(
                    controller: _searchController,
                    autofocus: true,
                    style: GoogleFonts.inter(color: t.textPrimary, fontSize: 16),
                    decoration: InputDecoration(
                      hintText: 'Search notes...',
                      hintStyle: GoogleFonts.inter(color: t.textMuted),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: (v) => setState(() => _searchQuery = v),
                  )
                : Text(
                    'My Personal Notes',
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: t.textPrimary,
                    ),
                  ),
            leading: IconButton(
              icon: Icon(Icons.arrow_back_rounded, color: t.textPrimary),
              onPressed: () => context.pop(),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  _showSearch ? Icons.close_rounded : Icons.search_rounded,
                  color: t.textPrimary,
                ),
                onPressed: () {
                  setState(() {
                    _showSearch = !_showSearch;
                    if (!_showSearch) {
                      _searchQuery = '';
                      _searchController.clear();
                    }
                  });
                },
              ),
              IconButton(
                icon: Icon(Icons.add_rounded, color: t.brand),
                onPressed: () => _showNoteSheet(context),
              ),
            ],
          ),

          // Tag filter row
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            sliver: SliverToBoxAdapter(
              child: SizedBox(
                height: 36,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _allTags.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final tag = _allTags[i];
                    final isSelected = tag == _selectedTag;
                    return FilterChip(
                      label: Text(
                        tag,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : t.textSecondary,
                        ),
                      ),
                      selected: isSelected,
                      onSelected: (_) => setState(() => _selectedTag = tag),
                      backgroundColor: t.surfaceAlt,
                      selectedColor: t.brand,
                      checkmarkColor: Colors.white,
                      side: BorderSide(
                          color: isSelected ? t.brand : t.border),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                    );
                  },
                ),
              ),
            ),
          ),

          // Notes list or empty state
          if (filtered.isEmpty)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 40, 20, 0),
              sliver: SliverToBoxAdapter(
                child: GlassmorphicCard(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      children: [
                        Icon(Icons.edit_note_rounded,
                            size: 48, color: t.textMuted),
                        const SizedBox(height: 16),
                        Text(
                          'No notes yet',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: t.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Tap + to create your first note',
                          style: GoogleFonts.inter(
                              fontSize: 13, color: t.textMuted),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final note = filtered[index];
                    return Dismissible(
                      key: ValueKey(note.id),
                      direction: DismissDirection.endToStart,
                      onDismissed: (_) {
                        ref.read(notesProvider.notifier).deleteNote(note.id);
                      },
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        decoration: BoxDecoration(
                          color: t.danger.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(Icons.delete_outline_rounded,
                            color: t.danger),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          onTap: () => _showNoteSheet(context, note: note),
                          borderRadius: BorderRadius.circular(20),
                          child: GlassmorphicCard(
                            child: Padding(
                              padding: const EdgeInsets.all(18),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          note.title,
                                          style: GoogleFonts.inter(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: t.textPrimary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Text(
                                        note.updatedAt.dayMonth,
                                        style: GoogleFonts.inter(
                                            fontSize: 11, color: t.textMuted),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    note.body,
                                    style: GoogleFonts.inter(
                                        fontSize: 13, color: t.textSecondary),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (note.tags.isNotEmpty) ...[
                                    const SizedBox(height: 10),
                                    Wrap(
                                      spacing: 6,
                                      children: note.tags.map((tag) {
                                        return Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: t.brand.withOpacity(0.12),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            tag,
                                            style: GoogleFonts.inter(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              color: t.brand,
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  childCount: filtered.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showNoteSheet(BuildContext context, {Note? note}) {
    final t = context.fitTheme;
    final titleCtrl = TextEditingController(text: note?.title ?? '');
    final bodyCtrl = TextEditingController(text: note?.body ?? '');
    final selectedTags = <String>[...note?.tags ?? []];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setState) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: t.surface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: t.textMuted.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    note == null ? 'New Note' : 'Edit Note',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: t.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleCtrl,
                    style: GoogleFonts.inter(color: t.textPrimary),
                    decoration: const InputDecoration(labelText: 'Title'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: bodyCtrl,
                    maxLines: 8,
                    style: GoogleFonts.inter(
                        color: t.textPrimary, fontSize: 14),
                    decoration: const InputDecoration(
                      labelText: 'Write your note...',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Tags',
                      style: GoogleFonts.inter(
                          fontSize: 13, color: t.textSecondary)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _allTags
                        .where((tag) => tag != 'All')
                        .map((tag) {
                      final isSel = selectedTags.contains(tag);
                      return FilterChip(
                        label: Text(tag,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: isSel ? Colors.white : t.textSecondary,
                            )),
                        selected: isSel,
                        onSelected: (_) => setState(() {
                          if (isSel) {
                            selectedTags.remove(tag);
                          } else {
                            selectedTags.add(tag);
                          }
                        }),
                        backgroundColor: t.surfaceAlt,
                        selectedColor: t.brand,
                        checkmarkColor: Colors.white,
                        side: BorderSide(
                            color: isSel ? t.brand : t.border),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        final title = titleCtrl.text.trim();
                        final body = bodyCtrl.text.trim();
                        if (title.isEmpty) return;
                        if (note == null) {
                          ref
                              .read(notesProvider.notifier)
                              .addNote(title, body, List.from(selectedTags));
                        } else {
                          ref.read(notesProvider.notifier).updateNote(
                              note.id, title, body, List.from(selectedTags));
                        }
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: t.brand,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        note == null ? 'Save Note' : 'Update Note',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
