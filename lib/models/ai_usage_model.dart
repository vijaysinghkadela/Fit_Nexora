import 'package:equatable/equatable.dart';

/// Tracks a gym's AI usage for the current billing period.
class AiUsage extends Equatable {
  final String id;
  final String gymId;

  /// Billing period start (typically 1st of month or subscription start).
  final DateTime periodStart;
  final DateTime periodEnd;

  /// Opus calls used this period.
  final int opusCallsUsed;

  /// Haiku calls used this period.
  final int haikuCallsUsed;

  /// Total tokens consumed (input + output combined).
  final int totalTokensUsed;

  /// Overage charges accrued this period (in dollars).
  final double overageCharges;

  final DateTime updatedAt;

  const AiUsage({
    required this.id,
    required this.gymId,
    required this.periodStart,
    required this.periodEnd,
    this.opusCallsUsed = 0,
    this.haikuCallsUsed = 0,
    this.totalTokensUsed = 0,
    this.overageCharges = 0.0,
    required this.updatedAt,
  });

  /// Total AI calls this period.
  int get totalCalls => opusCallsUsed + haikuCallsUsed;

  /// Whether we're in the current billing period.
  bool get isCurrentPeriod {
    final now = DateTime.now();
    return now.isAfter(periodStart) && now.isBefore(periodEnd);
  }

  AiUsage copyWith({
    int? opusCallsUsed,
    int? haikuCallsUsed,
    int? totalTokensUsed,
    double? overageCharges,
  }) {
    return AiUsage(
      id: id,
      gymId: gymId,
      periodStart: periodStart,
      periodEnd: periodEnd,
      opusCallsUsed: opusCallsUsed ?? this.opusCallsUsed,
      haikuCallsUsed: haikuCallsUsed ?? this.haikuCallsUsed,
      totalTokensUsed: totalTokensUsed ?? this.totalTokensUsed,
      overageCharges: overageCharges ?? this.overageCharges,
      updatedAt: DateTime.now(),
    );
  }

  factory AiUsage.fromJson(Map<String, dynamic> json) {
    return AiUsage(
      id: json['id'] as String,
      gymId: json['gym_id'] as String,
      periodStart: DateTime.parse(json['period_start'] as String),
      periodEnd: DateTime.parse(json['period_end'] as String),
      opusCallsUsed: json['opus_calls_used'] as int? ?? 0,
      haikuCallsUsed: json['haiku_calls_used'] as int? ?? 0,
      totalTokensUsed: json['total_tokens_used'] as int? ?? 0,
      overageCharges: (json['overage_charges'] as num?)?.toDouble() ?? 0.0,
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'gym_id': gymId,
        'period_start': periodStart.toIso8601String(),
        'period_end': periodEnd.toIso8601String(),
        'opus_calls_used': opusCallsUsed,
        'haiku_calls_used': haikuCallsUsed,
        'total_tokens_used': totalTokensUsed,
        'overage_charges': overageCharges,
        'updated_at': updatedAt.toIso8601String(),
      };

  @override
  List<Object?> get props =>
      [id, gymId, periodStart, opusCallsUsed, haikuCallsUsed];
}
