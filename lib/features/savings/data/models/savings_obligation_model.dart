import 'package:ufg/features/savings/domain/entities/savings_obligation_entity.dart';

class SavingsObligationModel extends SavingsObligationEntity {
  const SavingsObligationModel({
    required super.id,
    required super.periodYear,
    required super.periodMonth,
    required super.requiredAmount,
    required super.dueDate,
    required super.paidAmount,
    required super.latePenaltyAmount,
    required super.status,
    required super.totalDue,
    super.createdAt,
    super.updatedAt,
  });

  factory SavingsObligationModel.fromJson(Map<String, dynamic> json) {
    SavingsObligationStatus parseStatus(String? statusStr) {
      switch (statusStr?.toLowerCase()) {
        case 'paid':
          return SavingsObligationStatus.paid;
        case 'partially_paid':
          return SavingsObligationStatus.partiallyPaid;
        case 'late':
          return SavingsObligationStatus.late;
        case 'waived':
          return SavingsObligationStatus.waived;
        case 'pending':
        default:
          return SavingsObligationStatus.pending;
      }
    }

    final reqAmount = (json['required_amount'] as num?)?.toDouble() ?? 0.0;
    final paidAmt = (json['paid_amount'] as num?)?.toDouble() ?? 0.0;
    final penaltyAmt = (json['late_penalty_amount'] as num?)?.toDouble() ?? 0.0;
    final calcTotalDue = (json['total_due'] as num?)?.toDouble() ??
        ((reqAmount - paidAmt) + penaltyAmt).clamp(0.0, double.infinity);

    return SavingsObligationModel(
      id: json['id'] as String? ?? '',
      periodYear: (json['period_year'] as num?)?.toInt() ?? DateTime.now().year,
      periodMonth: (json['period_month'] as num?)?.toInt() ?? DateTime.now().month,
      requiredAmount: reqAmount,
      dueDate: json['due_date'] != null
          ? DateTime.tryParse(json['due_date'].toString()) ?? DateTime.now()
          : DateTime.now(),
      paidAmount: paidAmt,
      latePenaltyAmount: penaltyAmt,
      status: parseStatus(json['status'] as String?),
      totalDue: calcTotalDue,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'period_year': periodYear,
      'period_month': periodMonth,
      'required_amount': requiredAmount,
      'due_date': dueDate.toIso8601String().split('T').first,
      'paid_amount': paidAmount,
      'late_penalty_amount': latePenaltyAmount,
      'status': status.name,
      'total_due': totalDue,
    };
  }
}
