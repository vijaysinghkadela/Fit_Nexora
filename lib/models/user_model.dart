import 'package:equatable/equatable.dart';
import '../core/enums.dart';

/// Application user profile — linked to Supabase auth.users.
class AppUser extends Equatable {
  final String id;
  final String fullName;
  final String email;
  final String? phone;
  final String? avatarUrl;
  final UserRole globalRole;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AppUser({
    required this.id,
    required this.fullName,
    required this.email,
    this.phone,
    this.avatarUrl,
    this.globalRole = UserRole.client,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String,
      fullName: json['full_name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      globalRole:
          UserRole.fromString(json['global_role'] as String? ?? 'client'),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'phone': phone,
      'avatar_url': avatarUrl,
      'global_role': globalRole.value,
    };
  }

  AppUser copyWith({
    String? fullName,
    String? email,
    String? phone,
    String? avatarUrl,
    UserRole? globalRole,
  }) {
    return AppUser(
      id: id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      globalRole: globalRole ?? this.globalRole,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [id, fullName, email, globalRole];
}
