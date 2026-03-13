import 'package:equatable/equatable.dart';
import '../core/enums.dart';

/// Client gym membership (subscription to the gym itself, not SaaS).
class Membership extends Equatable {
  final String id;
  final String clientId;
  final String gymId;
  final String planName;
  final double? amount;
  final String currency;
  final DateTime startDate;
  final DateTime endDate;
  final MembershipStatus status;
  final bool autoRenew;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Membership({
    required this.id,
    required this.clientId,
    required this.gymId,
    required this.planName,
    this.amount,
    this.currency = 'INR',
    required this.startDate,
    required this.endDate,
    this.status = MembershipStatus.active,
    this.autoRenew = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Membership.fromJson(Map<String, dynamic> json) {
    return Membership(
      id: json['id'] as String,
      clientId: json['client_id'] as String,
      gymId: json['gym_id'] as String,
      planName: json['plan_name'] as String,
      amount: (json['amount'] as num?)?.toDouble(),
      currency: json['currency'] as String? ?? 'INR',
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      status:
          MembershipStatus.fromString(json['status'] as String? ?? 'active'),
      autoRenew: json['auto_renew'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'client_id': clientId,
      'gym_id': gymId,
      'plan_name': planName,
      'amount': amount,
      'currency': currency,
      'start_date': startDate.toIso8601String().split('T').first,
      'end_date': endDate.toIso8601String().split('T').first,
      'status': status.value,
      'auto_renew': autoRenew,
    };
  }

  /// Whether this membership is expired.
  bool get isExpired => endDate.isBefore(DateTime.now());

  /// Days remaining before expiry. Negative if expired.
  int get daysRemaining => endDate.difference(DateTime.now()).inDays;

  /// Whether this membership expires within the given number of days.
  bool expiresWithin(int days) => !isExpired && daysRemaining <= days;

  Membership copyWith({
    String? planName,
    double? amount,
    DateTime? startDate,
    DateTime? endDate,
    MembershipStatus? status,
    bool? autoRenew,
  }) {
    return Membership(
      id: id,
      clientId: clientId,
      gymId: gymId,
      planName: planName ?? this.planName,
      amount: amount ?? this.amount,
      currency: currency,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      autoRenew: autoRenew ?? this.autoRenew,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [id, clientId, gymId, status];
}
