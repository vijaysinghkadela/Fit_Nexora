import 'package:equatable/equatable.dart';
import '../core/enums.dart';

/// Gym entity — the multi-tenant root for all gym data.
class Gym extends Equatable {
  final String id;
  final String name;
  final String ownerId;
  final String? address;
  final String? city;
  final String? phone;
  final String? logoUrl;
  final PlanTier planTier;
  final int maxClients;
  final int maxTrainers;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Gym({
    required this.id,
    required this.name,
    required this.ownerId,
    this.address,
    this.city,
    this.phone,
    this.logoUrl,
    this.planTier = PlanTier.basic,
    this.maxClients = 50,
    this.maxTrainers = 1,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Gym.fromJson(Map<String, dynamic> json) {
    return Gym(
      id: json['id'] as String,
      name: json['name'] as String,
      ownerId: json['owner_id'] as String,
      address: json['address'] as String?,
      city: json['city'] as String?,
      phone: json['phone'] as String?,
      logoUrl: json['logo_url'] as String?,
      planTier: PlanTier.fromString(json['plan_tier'] as String? ?? 'basic'),
      maxClients: json['max_clients'] as int? ?? 50,
      maxTrainers: json['max_trainers'] as int? ?? 1,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'owner_id': ownerId,
      'address': address,
      'city': city,
      'phone': phone,
      'logo_url': logoUrl,
      'plan_tier': planTier.value,
      'max_clients': maxClients,
      'max_trainers': maxTrainers,
      'is_active': isActive,
    };
  }

  Gym copyWith({
    String? name,
    String? address,
    String? city,
    String? phone,
    String? logoUrl,
    PlanTier? planTier,
    int? maxClients,
    int? maxTrainers,
    bool? isActive,
  }) {
    return Gym(
      id: id,
      name: name ?? this.name,
      ownerId: ownerId,
      address: address ?? this.address,
      city: city ?? this.city,
      phone: phone ?? this.phone,
      logoUrl: logoUrl ?? this.logoUrl,
      planTier: planTier ?? this.planTier,
      maxClients: maxClients ?? this.maxClients,
      maxTrainers: maxTrainers ?? this.maxTrainers,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [id, name, ownerId, planTier];
}
