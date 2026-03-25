import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/extensions.dart';
import '../../providers/notes_provider.dart';
import '../../widgets/glassmorphic_card.dart';

const _allTags = ['All', 'Workout', 'Diet', 'Personal', 'Goals'];

// Simple color palette for notes
const _noteColors = [
  null, // Default (no color)
  '#FF5252', // Red
  '#4CAF50', // Green
  '#2196F3', // Blue
  '#FFC107', // Yellow
  '#9C27B0', // Purple
];

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

  Color? _getColorFromHex(String? hexColor) {
    if (hexColor == null || hexColor.isEmpty) return null;
    hexColor = hexColor.toUpperCase().replaceAll("#", "");
    if (hexColor.length == 6) {
      hexColor = "FF$hexColor";
    }
    return Color(int.parse(hexColor, radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;
    final notesState = ref.watch(notesProvider);

    // Filter notes
    List<Note> filtered = _selectedTag == 'All'
        ? notesState.notes
        : notesState.notes.where((n) => n.tags.contains(_selectedTag)).toList();

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
                    style:
                        GoogleFonts.inter(color: t.textPrimary, fontSize: 16),
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
                      side: BorderSide(color: isSelected ? t.brand : t.border),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                    );
                  },
                ),
              ),
            ),
          ),

          // Loading state
          if (notesState.isLoading)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        height: 120,
                        decoration: BoxDecoration(
                          color: t.surfaceAlt,
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ).animate(onPlay: (c) => c.repeat()).shimmer(
                          duration: 1200.ms, color: t.surface.withOpacity(0.5)),
                    );
                  },
                  childCount: 3,
                ),
              ),
            )
          // Empty state
          else if (filtered.isEmpty)
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
                          _searchQuery.isNotEmpty
                              ? 'No notes found'
                              : 'No notes yet',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: t.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        if (_searchQuery.isEmpty)
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
          // Notes List
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final note = filtered[index];
                    final noteColor = _getColorFromHex(note.color);

                    return Dismissible(
                      key: ValueKey(note.id),
                      direction: DismissDirection.endToStart,
                      onDismissed: (_) {
                        ref.read(notesProvider.notifier).deleteNote(note.id);
                      },
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: t.danger.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(Icons.delete_outline_rounded,
                            color: Colors.white),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          onTap: () => _showNoteSheet(context, note: note),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            decoration: BoxDecoration(
                              color: noteColor != null
                                  ? noteColor.withOpacity(0.15)
                                  : t.surfaceAlt.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: noteColor != null
                                      ? noteColor.withOpacity(0.3)
                                      : t.border.withOpacity(0.5)),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(18),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          note.title,
                                          style: GoogleFonts.inter(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: t.textPrimary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (note.isPinned)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(left: 8),
                                          child: Icon(Icons.push_pin_rounded,
                                              size: 16, color: t.brand),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    note.body,
                                    style: GoogleFonts.inter(
                                        fontSize: 14,
                                        color: t.textSecondary,
                                        height: 1.4),
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      if (note.tags.isNotEmpty)
                                        Expanded(
                                          child: Wrap(
                                            spacing: 6,
                                            children:
                                                note.tags.take(3).map((tag) {
                                              return Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: noteColor != null
                                                      ? noteColor
                                                          .withOpacity(0.2)
                                                      : t.brand
                                                          .withOpacity(0.12),
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  tag,
                                                  style: GoogleFonts.inter(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w600,
                                                    color: noteColor ?? t.brand,
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                        )
                                      else
                                        const Spacer(),
                                      Text(
                                        note.updatedAt.dayMonth,
                                        style: GoogleFonts.inter(
                                            fontSize: 11, color: t.textMuted),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                        .animate(delay: Duration(milliseconds: 50 * index))
                        .fadeIn()
                        .slideX(begin: 0.05);
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
    String? selectedColor = note?.color;
    bool isPinned = note?.isPinned ?? false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          final keyboardHeight = MediaQuery.of(ctx).viewInsets.bottom;
          return Padding(
            padding: EdgeInsets.only(bottom: keyboardHeight),
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(ctx).size.height * 0.88,
              ),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: t.surface,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle bar
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

                    // Title row with Pin & Delete buttons
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            note == null ? 'New Note' : 'Edit Note',
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: t.textPrimary,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: isPinned ? 'Unpin note' : 'Pin note',
                          icon: Icon(
                            isPinned
                                ? Icons.push_pin_rounded
                                : Icons.push_pin_outlined,
                            color: isPinned ? t.brand : t.textMuted,
                          ),
                          onPressed: () => setState(() => isPinned = !isPinned),
                        ),
                        if (note != null)
                          IconButton(
                            tooltip: 'Delete note',
                            icon: Icon(Icons.delete_outline_rounded,
                                color: t.danger),
                            onPressed: () {
                              ref
                                  .read(notesProvider.notifier)
                                  .deleteNote(note.id);
                              Navigator.pop(ctx);
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Inputs
                    TextField(
                      controller: titleCtrl,
                      style: GoogleFonts.inter(
                          color: t.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w600),
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        hintText: 'Note Title',
                        hintStyle: GoogleFonts.inter(color: t.textMuted),
                        border: InputBorder.none,
                      ),
                    ),
                    Divider(color: t.divider),
                    TextField(
                      controller: bodyCtrl,
                      maxLines: 8,
                      minLines: 5,
                      style: GoogleFonts.inter(
                          color: t.textPrimary, fontSize: 15, height: 1.5),
                      decoration: InputDecoration(
                        hintText: 'Write your note...',
                        hintStyle: GoogleFonts.inter(color: t.textMuted),
                        border: InputBorder.none,
                      ),
                    ),

                    // Color Picker
                    const SizedBox(height: 16),
                    Text('Color',
                        style: GoogleFonts.inter(
                            fontSize: 13,
                            color: t.textSecondary,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: _noteColors.map((colorHex) {
                        final isSelected = selectedColor == colorHex;
                        final colorValue =
                            _getColorFromHex(colorHex) ?? t.surfaceAlt;

                        return GestureDetector(
                          onTap: () => setState(() => selectedColor = colorHex),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: colorValue,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? t.textPrimary
                                    : (colorHex == null
                                        ? t.border
                                        : Colors.transparent),
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: isSelected
                                ? Icon(Icons.check_rounded,
                                    size: 18,
                                    color: colorHex == null
                                        ? t.textPrimary
                                        : Colors.white)
                                : (colorHex == null
                                    ? Icon(Icons.format_color_reset_rounded,
                                        size: 16, color: t.textMuted)
                                    : null),
                          ),
                        );
                      }).toList(),
                    ),

                    // Tags
                    const SizedBox(height: 24),
                    Text('Tags',
                        style: GoogleFonts.inter(
                            fontSize: 13,
                            color: t.textSecondary,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          _allTags.where((tag) => tag != 'All').map((tag) {
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
                          side: BorderSide(color: isSel ? t.brand : t.border),
                        );
                      }).toList(),
                    ),

                    // Save Button
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: () {
                          final title = titleCtrl.text.trim();
                          final body = bodyCtrl.text.trim();

                          // Default title if empty
                          final finalTitle =
                              title.isEmpty ? 'Untitled Note' : title;

                          if (body.isEmpty && title.isEmpty)
                            return; // Don't save empty notes

                          if (note == null) {
                            ref.read(notesProvider.notifier).addNote(
                                  finalTitle,
                                  body,
                                  List.from(selectedTags),
                                  color: selectedColor,
                                  isPinned: isPinned,
                                );
                          } else {
                            ref.read(notesProvider.notifier).updateNote(
                                  note.id,
                                  finalTitle,
                                  body,
                                  List.from(selectedTags),
                                  color: selectedColor,
                                  isPinned: isPinned,
                                );
                          }
                          Navigator.pop(ctx);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: t.brand,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
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
          );
        },
      ),
    );
  }
}
