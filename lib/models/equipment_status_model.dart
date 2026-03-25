// lib/models/equipment_status_model.dart
//
// Plain-Dart model for gym equipment status.
// Avoids freezed/build_runner so no generated files are required.

class EquipmentStatus {
  const EquipmentStatus({
    required this.id,
    required this.gymId,
    required this.name,
    required this.category,
    required this.totalUnits,
    this.inUse = 0,
    this.outOfService = 0,
    this.updatedAt,
  });

  final String id;
  final String gymId;
  final String name;
  final String category;
  final int totalUnits;
  final int inUse;
  final int outOfService;
  final DateTime? updatedAt;

  // ── Derived getters ──────────────────────────────────────────────────────────
  int get available => totalUnits - inUse - outOfService;
  double get usageFraction =>
      totalUnits > 0 ? inUse / totalUnits : 0.0;
  double get outOfServiceFraction =>
      totalUnits > 0 ? outOfService / totalUnits : 0.0;

  // ── JSON ─────────────────────────────────────────────────────────────────────
  factory EquipmentStatus.fromJson(Map<String, dynamic> json) => EquipmentStatus(
        id: json['id'] as String,
        gymId: json['gym_id'] as String,
        name: json['name'] as String,
        category: json['category'] as String,
        totalUnits: json['total_units'] as int,
        inUse: (json['in_use'] as int?) ?? 0,
        outOfService: (json['out_of_service'] as int?) ?? 0,
        updatedAt: json['updated_at'] != null
            ? DateTime.parse(json['updated_at'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'gym_id': gymId,
        'name': name,
        'category': category,
        'total_units': totalUnits,
        'in_use': inUse,
        'out_of_service': outOfService,
        'updated_at': updatedAt?.toIso8601String(),
      };

  // ── copyWith ─────────────────────────────────────────────────────────────────
  EquipmentStatus copyWith({
    String? id,
    String? gymId,
    String? name,
    String? category,
    int? totalUnits,
    int? inUse,
    int? outOfService,
    DateTime? updatedAt,
  }) =>
      EquipmentStatus(
        id: id ?? this.id,
        gymId: gymId ?? this.gymId,
        name: name ?? this.name,
        category: category ?? this.category,
        totalUnits: totalUnits ?? this.totalUnits,
        inUse: inUse ?? this.inUse,
        outOfService: outOfService ?? this.outOfService,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EquipmentStatus &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          inUse == other.inUse &&
          outOfService == other.outOfService &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hash(id, inUse, outOfService, updatedAt);
}
