import 'package:equatable/equatable.dart';

/// A gym-wide or app-wide announcement.
class Announcement extends Equatable {
  final String id;
  final String? gymId;
  final String title;
  final String? body;
  final bool isPinned;
  final String type; // 'gym' or 'app'
  final DateTime createdAt;

  const Announcement({
    required this.id,
    this.gymId,
    required this.title,
    this.body,
    this.isPinned = false,
    this.type = 'gym',
    required this.createdAt,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      id: json['id'] as String,
      gymId: json['gym_id'] as String?,
      title: json['title'] as String,
      body: json['body'] as String?,
      isPinned: json['is_pinned'] as bool? ?? false,
      type: json['announcement_type'] as String? ?? 'gym',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'gym_id': gymId,
        'title': title,
        'body': body,
        'is_pinned': isPinned,
        'announcement_type': type,
      };

  @override
  List<Object?> get props => [id, gymId, title, type, createdAt];
}
