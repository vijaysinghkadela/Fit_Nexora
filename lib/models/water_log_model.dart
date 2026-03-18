// lib/models/water_log_model.dart
import 'package:equatable/equatable.dart';

class WaterLog extends Equatable {
  final String id;
  final String userId;
  final int amountMl;
  final DateTime loggedAt;

  const WaterLog({
    required this.id,
    required this.userId,
    required this.amountMl,
    required this.loggedAt,
  });

  factory WaterLog.fromMap(Map<String, dynamic> map) => WaterLog(
        id: map['id'] as String,
        userId: map['user_id'] as String,
        amountMl: (map['amount_ml'] as num).toInt(),
        loggedAt: DateTime.parse(map['logged_at'] as String),
      );

  Map<String, dynamic> toMap() => {
        'user_id': userId,
        'amount_ml': amountMl,
        'logged_at': loggedAt.toIso8601String(),
      };

  @override
  List<Object?> get props => [id, userId, loggedAt];
}

class WaterTrackerState {
  final List<WaterLog> todayLogs;
  final int dailyGoalMl;
  final bool isLoading;

  const WaterTrackerState({
    this.todayLogs = const [],
    this.dailyGoalMl = 2500,
    this.isLoading = false,
  });

  int get totalTodayMl =>
      todayLogs.fold(0, (sum, log) => sum + log.amountMl);

  double get progressFraction =>
      (totalTodayMl / dailyGoalMl).clamp(0.0, 1.0);

  int get remainingMl => (dailyGoalMl - totalTodayMl).clamp(0, dailyGoalMl);

  int get glassesConsumed => (totalTodayMl / 250).floor();

  WaterTrackerState copyWith({
    List<WaterLog>? todayLogs,
    int? dailyGoalMl,
    bool? isLoading,
  }) =>
      WaterTrackerState(
        todayLogs: todayLogs ?? this.todayLogs,
        dailyGoalMl: dailyGoalMl ?? this.dailyGoalMl,
        isLoading: isLoading ?? this.isLoading,
      );
}
