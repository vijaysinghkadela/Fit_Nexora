import 'package:freezed_annotation/freezed_annotation.dart';

part 'equipment_status_model.freezed.dart';
part 'equipment_status_model.g.dart';

@freezed
class EquipmentStatus with _$EquipmentStatus {
  const factory EquipmentStatus({
    required String id,
    @JsonKey(name: 'gym_id') required String gymId,
    required String name,
    required String category,
    @JsonKey(name: 'total_units') required int totalUnits,
    @JsonKey(name: 'in_use') @Default(0) int inUse,
    @JsonKey(name: 'out_of_service') @Default(0) int outOfService,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _EquipmentStatus;

  factory EquipmentStatus.fromJson(Map<String, dynamic> json) =>
      _$EquipmentStatusFromJson(json);

  const EquipmentStatus._();

  int get available => totalUnits - inUse - outOfService;
  
  double get usageFraction => totalUnits > 0 ? inUse / totalUnits : 0.0;
  double get outOfServiceFraction => totalUnits > 0 ? outOfService / totalUnits : 0.0;
}
