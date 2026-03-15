import 'package:equatable/equatable.dart';

/// A gym-wide announcement posted by the gym owner or trainer.
class Announcement extends Equatable {
  final String id;
  final String gymId;
  final String title;
  final String? body;
  final bool isPinned;
  final DateTime createdAt;

  const Announcement({
    required this.id,
    required this.gymId,
    required this.title,
    this.body,
    this.isPinned = false,
    required this.createdAt,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      id: json['id'] as String,
      gymId: json['gym_id'] as String,
      title: json['title'] as String,
      body: json['body'] as String?,
      isPinned: json['is_pinned'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'gym_id': gymId,
        'title': title,
        'body': body,
        'is_pinned': isPinned,
      };

  @override
  List<Object?> get props => [id, gymId, title, createdAt];
}
