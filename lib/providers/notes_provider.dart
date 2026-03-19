import 'package:flutter_riverpod/flutter_riverpod.dart';

class Note {
  final String id;
  final String title;
  final String body;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Note({
    required this.id,
    required this.title,
    required this.body,
    required this.tags,
    required this.createdAt,
    required this.updatedAt,
  });

  Note copyWith({
    String? title,
    String? body,
    List<String>? tags,
    DateTime? updatedAt,
  }) =>
      Note(
        id: id,
        title: title ?? this.title,
        body: body ?? this.body,
        tags: tags ?? this.tags,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}

class NotesNotifier extends StateNotifier<List<Note>> {
  NotesNotifier() : super(_seedNotes());

  static List<Note> _seedNotes() {
    final now = DateTime.now();
    return [
      Note(
        id: '1',
        title: 'Leg Day Notes',
        body: 'Focus on form for squats today. Keep back straight, knees tracking over toes. Try 4×8 at 80kg.',
        tags: ['Workout'],
        createdAt: now.subtract(const Duration(days: 3)),
        updatedAt: now.subtract(const Duration(days: 3)),
      ),
      Note(
        id: '2',
        title: 'Weekly Nutrition Goal',
        body: 'Target 160g protein daily. Prep meals on Sunday. Include more leafy greens and reduce processed carbs.',
        tags: ['Diet'],
        createdAt: now.subtract(const Duration(days: 7)),
        updatedAt: now.subtract(const Duration(days: 1)),
      ),
      Note(
        id: '3',
        title: 'Q2 Fitness Goals',
        body: 'Bench press 100kg, run 5km under 25 minutes, lose 3kg body fat by June. Track weekly progress.',
        tags: ['Goals', 'Personal'],
        createdAt: now.subtract(const Duration(days: 14)),
        updatedAt: now.subtract(const Duration(days: 5)),
      ),
    ];
  }

  void addNote(String title, String body, List<String> tags) {
    final now = DateTime.now();
    final note = Note(
      id: now.millisecondsSinceEpoch.toString(),
      title: title,
      body: body,
      tags: tags,
      createdAt: now,
      updatedAt: now,
    );
    state = [note, ...state];
  }

  void updateNote(String id, String title, String body, List<String> tags) {
    state = state.map((n) {
      if (n.id == id) {
        return n.copyWith(
            title: title, body: body, tags: tags, updatedAt: DateTime.now());
      }
      return n;
    }).toList();
  }

  void deleteNote(String id) {
    state = state.where((n) => n.id != id).toList();
  }

  List<Note> filterByTag(String tag) {
    if (tag == 'All') return state;
    return state.where((n) => n.tags.contains(tag)).toList();
  }
}

final notesProvider = StateNotifierProvider.autoDispose<NotesNotifier, List<Note>>(
  (ref) => NotesNotifier(),
);
