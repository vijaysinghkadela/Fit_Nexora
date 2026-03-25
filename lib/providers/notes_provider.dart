import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Note {
  final String id;
  final String title;
  final String body;
  final List<String> tags;
  final String? color; // hex string e.g. '#FF5733'
  final bool isPinned;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Note({
    required this.id,
    required this.title,
    required this.body,
    required this.tags,
    this.color,
    this.isPinned = false,
    required this.createdAt,
    required this.updatedAt,
  });

  Note copyWith({
    String? title,
    String? body,
    List<String>? tags,
    String? color,
    bool? isPinned,
    DateTime? updatedAt,
  }) =>
      Note(
        id: id,
        title: title ?? this.title,
        body: body ?? this.body,
        tags: tags ?? this.tags,
        color: color ?? this.color,
        isPinned: isPinned ?? this.isPinned,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'],
      title: map['title'],
      body: map['body'],
      tags: List<String>.from(map['tags'] ?? []),
      color: map['color'],
      isPinned: map['is_pinned'] ?? false,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }
}

class NotesState {
  final List<Note> notes;
  final bool isLoading;

  const NotesState({
    required this.notes,
    this.isLoading = false,
  });

  NotesState copyWith({List<Note>? notes, bool? isLoading}) {
    return NotesState(
      notes: notes ?? this.notes,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class NotesNotifier extends StateNotifier<NotesState> {
  final SupabaseClient _supabase;

  NotesNotifier(this._supabase)
      : super(const NotesState(notes: [], isLoading: true)) {
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        state = state.copyWith(isLoading: false);
        return;
      }

      final response = await _supabase
          .from('user_notes')
          .select()
          .eq('user_id', user.id)
          .order('is_pinned', ascending: false)
          .order('updated_at', ascending: false);

      final notes = response.map((data) => Note.fromMap(data)).toList();
      state = state.copyWith(notes: notes, isLoading: false);
    } catch (e) {
      // In case of error, just stop loading
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> addNote(String title, String body, List<String> tags,
      {String? color, bool isPinned = false}) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final now = DateTime.now();
    // Temporary ID for optimistic update
    final tempId = 'temp_${now.millisecondsSinceEpoch}';

    final newNote = Note(
      id: tempId,
      title: title,
      body: body,
      tags: tags,
      color: color,
      isPinned: isPinned,
      createdAt: now,
      updatedAt: now,
    );

    // Optimistic update
    final currentNotes = List<Note>.from(state.notes);
    currentNotes.insert(0, newNote);
    _sortNotes(currentNotes);
    state = state.copyWith(notes: currentNotes);

    try {
      final response = await _supabase
          .from('user_notes')
          .insert({
            'user_id': user.id,
            'title': title,
            'body': body,
            'tags': tags,
            'color': color,
            'is_pinned': isPinned,
          })
          .select()
          .single();

      final savedNote = Note.fromMap(response);

      // Replace temp note with saved note
      final index = state.notes.indexWhere((n) => n.id == tempId);
      if (index != -1) {
        final updatedNotes = List<Note>.from(state.notes);
        updatedNotes[index] = savedNote;
        _sortNotes(updatedNotes);
        state = state.copyWith(notes: updatedNotes);
      }
    } catch (e) {
      // Revert optimistic update on failure
      state = state.copyWith(
          notes: state.notes.where((n) => n.id != tempId).toList());
    }
  }

  Future<void> updateNote(
      String id, String title, String body, List<String> tags,
      {String? color, bool? isPinned}) async {
    final existingIndex = state.notes.indexWhere((n) => n.id == id);
    if (existingIndex == -1) return;

    final existingNote = state.notes[existingIndex];
    final updatedNote = existingNote.copyWith(
      title: title,
      body: body,
      tags: tags,
      color: color,
      isPinned: isPinned,
      updatedAt: DateTime.now(),
    );

    // Optimistic update
    final updatedNotes = List<Note>.from(state.notes);
    updatedNotes[existingIndex] = updatedNote;
    _sortNotes(updatedNotes);
    state = state.copyWith(notes: updatedNotes);

    try {
      await _supabase.from('user_notes').update({
        'title': title,
        'body': body,
        'tags': tags,
        'color': color,
        'is_pinned': isPinned ?? existingNote.isPinned,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', id);
    } catch (e) {
      // Refresh to get actual server state on failure
      _loadNotes();
    }
  }

  Future<void> togglePin(String id) async {
    final existingNote = state.notes.firstWhere((n) => n.id == id);
    await updateNote(
      id,
      existingNote.title,
      existingNote.body,
      existingNote.tags,
      color: existingNote.color,
      isPinned: !existingNote.isPinned,
    );
  }

  Future<void> deleteNote(String id) async {
    // Optimistic update
    final previousNotes = state.notes;
    state =
        state.copyWith(notes: state.notes.where((n) => n.id != id).toList());

    try {
      await _supabase.from('user_notes').delete().eq('id', id);
    } catch (e) {
      // Revert on failure
      state = state.copyWith(notes: previousNotes);
    }
  }

  void _sortNotes(List<Note> notes) {
    notes.sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      return b.updatedAt.compareTo(a.updatedAt);
    });
  }

  List<Note> filterByTag(String tag) {
    if (tag == 'All') return state.notes;
    return state.notes.where((n) => n.tags.contains(tag)).toList();
  }
}

final notesProvider =
    StateNotifierProvider.autoDispose<NotesNotifier, NotesState>(
  (ref) => NotesNotifier(Supabase.instance.client),
);
