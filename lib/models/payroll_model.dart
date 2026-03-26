// lib/models/payroll_model.dart
import 'package:equatable/equatable.dart';

class TrainerContract extends Equatable {
  final String id;
  final String gymId;
  final String trainerId;
  final double baseSalary;
  final bool isActive;
  final DateTime startDate;
  final DateTime? endDate;
  final DateTime createdAt;

  // Joined from profiles
  final String? trainerName;
  final String? trainerEmail;

  const TrainerContract({
    required this.id,
    required this.gymId,
    required this.trainerId,
    required this.baseSalary,
    required this.isActive,
    required this.startDate,
    this.endDate,
    required this.createdAt,
    this.trainerName,
    this.trainerEmail,
  });

  factory TrainerContract.fromMap(Map<String, dynamic> map) {
    return TrainerContract(
      id: map['id'] as String,
      gymId: map['gym_id'] as String,
      trainerId: map['trainer_id'] as String,
      baseSalary: (map['base_salary'] as num).toDouble(),
      isActive: map['is_active'] as bool? ?? true,
      startDate: DateTime.parse(map['start_date'].toString()),
      endDate: map['end_date'] != null
          ? DateTime.parse(map['end_date'].toString())
          : null,
      createdAt: DateTime.parse(map['created_at'].toString()),
      trainerName: map['profiles']?['full_name'] as String?,
      trainerEmail: map['profiles']?['email'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'gym_id': gymId,
        'trainer_id': trainerId,
        'base_salary': baseSalary,
        'is_active': isActive,
        'start_date': startDate.toIso8601String().split('T')[0],
        if (endDate != null)
          'end_date': endDate!.toIso8601String().split('T')[0],
      };

  @override
  List<Object?> get props =>
      [id, gymId, trainerId, baseSalary, isActive, startDate, endDate];
}

class PayrollRun extends Equatable {
  final String id;
  final String gymId;
  final int month;
  final int year;
  final String status; // 'draft', 'processed', 'paid'
  final double totalPayout;
  final DateTime? processedAt;
  final DateTime createdAt;

  const PayrollRun({
    required this.id,
    required this.gymId,
    required this.month,
    required this.year,
    required this.status,
    required this.totalPayout,
    this.processedAt,
    required this.createdAt,
  });

  factory PayrollRun.fromMap(Map<String, dynamic> map) {
    return PayrollRun(
      id: map['id'] as String,
      gymId: map['gym_id'] as String,
      month: map['month'] as int,
      year: map['year'] as int,
      status: map['status'] as String,
      totalPayout: (map['total_payout'] as num).toDouble(),
      processedAt: map['processed_at'] != null
          ? DateTime.parse(map['processed_at'].toString())
          : null,
      createdAt: DateTime.parse(map['created_at'].toString()),
    );
  }

  Map<String, dynamic> toMap() => {
        'gym_id': gymId,
        'month': month,
        'year': year,
        'status': status,
        'total_payout': totalPayout,
        if (processedAt != null) 'processed_at': processedAt!.toIso8601String(),
      };

  @override
  List<Object?> get props =>
      [id, gymId, month, year, status, totalPayout, processedAt];
}

class SalarySlip extends Equatable {
  final String id;
  final String payrollRunId;
  final String trainerId;
  final String gymId;
  final double baseAmount;
  final double bonuses;
  final double deductions;
  final double taxDeductions;
  final double netPayable;
  final String status; // 'pending', 'paid'
  final String? notes;
  final DateTime createdAt;

  // Joined fields
  final String? trainerName;
  final PayrollRun? payrollRun;

  const SalarySlip({
    required this.id,
    required this.payrollRunId,
    required this.trainerId,
    required this.gymId,
    required this.baseAmount,
    required this.bonuses,
    required this.deductions,
    required this.taxDeductions,
    required this.netPayable,
    required this.status,
    this.notes,
    required this.createdAt,
    this.trainerName,
    this.payrollRun,
  });

  factory SalarySlip.fromMap(Map<String, dynamic> map) {
    return SalarySlip(
      id: map['id'] as String,
      payrollRunId: map['payroll_run_id'] as String,
      trainerId: map['trainer_id'] as String,
      gymId: map['gym_id'] as String,
      baseAmount: (map['base_amount'] as num).toDouble(),
      bonuses: (map['bonuses'] as num).toDouble(),
      deductions: (map['deductions'] as num).toDouble(),
      taxDeductions: (map['tax_deductions'] as num).toDouble(),
      netPayable:
          (map['net_payable'] as num? ?? 0).toDouble(), // Generated column
      status: map['status'] as String,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'].toString()),
      trainerName: map['profiles']?['full_name'] as String?,
      payrollRun: map['payroll_runs'] != null
          ? PayrollRun.fromMap(map['payroll_runs'])
          : null,
    );
  }

  Map<String, dynamic> toMap() => {
        'payroll_run_id': payrollRunId,
        'trainer_id': trainerId,
        'gym_id': gymId,
        'base_amount': baseAmount,
        'bonuses': bonuses,
        'deductions': deductions,
        'tax_deductions': taxDeductions,
        'status': status,
        'notes': notes,
      };

  SalarySlip copyWith({
    double? bonuses,
    double? deductions,
    double? taxDeductions,
    String? notes,
  }) {
    return SalarySlip(
      id: id,
      payrollRunId: payrollRunId,
      trainerId: trainerId,
      gymId: gymId,
      baseAmount: baseAmount,
      bonuses: bonuses ?? this.bonuses,
      deductions: deductions ?? this.deductions,
      taxDeductions: taxDeductions ?? this.taxDeductions,
      netPayable: baseAmount +
          (bonuses ?? this.bonuses) -
          (deductions ?? this.deductions) -
          (taxDeductions ?? this.taxDeductions),
      status: status,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      trainerName: trainerName,
      payrollRun: payrollRun,
    );
  }

  @override
  List<Object?> get props => [
        id,
        payrollRunId,
        trainerId,
        gymId,
        baseAmount,
        bonuses,
        deductions,
        taxDeductions,
        netPayable,
        status,
        notes
      ];
}
