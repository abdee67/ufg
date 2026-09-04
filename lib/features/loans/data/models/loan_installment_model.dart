import 'package:ufg/features/loans/domain/entities/loan_installment_entity.dart';

class LoanInstallmentModel extends LoanInstallmentEntity {
  const LoanInstallmentModel({
    required super.id,
    required super.loanId,
    required super.installmentNumber,
    required super.dueDate,
    required super.principalAmount,
    required super.serviceChargeAmount,
    required super.totalDue,
    super.paidAmount,
    super.paidPenaltyAmount,
    super.latePenaltyAmount,
    required super.status,
  });

  static InstallmentStatus _parseStatus(String? raw) {
    switch (raw?.toLowerCase()) {
      case 'partially_paid':
        return InstallmentStatus.partiallyPaid;
      case 'paid':
        return InstallmentStatus.paid;
      case 'overdue':
        return InstallmentStatus.overdue;
      case 'defaulted':
        return InstallmentStatus.defaulted;
      case 'pending':
      default:
        return InstallmentStatus.pending;
    }
  }

  factory LoanInstallmentModel.fromJson(Map<String, dynamic> json) {
    return LoanInstallmentModel(
      id: json['id'] as String,
      loanId: json['loan_id'] as String? ?? '',
      installmentNumber: (json['installment_number'] as num?)?.toInt() ?? 1,
      dueDate: json['due_date'] != null ? DateTime.parse(json['due_date'] as String) : DateTime.now(),
      principalAmount: (json['principal_amount'] as num?)?.toDouble() ?? 0.0,
      serviceChargeAmount: (json['service_charge_amount'] as num?)?.toDouble() ?? 0.0,
      totalDue: (json['total_due'] as num?)?.toDouble() ?? 0.0,
      paidAmount: (json['paid_amount'] as num?)?.toDouble() ?? 0.0,
      paidPenaltyAmount: (json['paid_penalty_amount'] as num?)?.toDouble() ?? 0.0,
      latePenaltyAmount: (json['late_penalty_amount'] as num?)?.toDouble() ?? 0.0,
      status: _parseStatus(json['status'] as String?),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'loan_id': loanId,
      'installment_number': installmentNumber,
      'due_date': dueDate.toIso8601String().split('T').first,
      'principal_amount': principalAmount,
      'service_charge_amount': serviceChargeAmount,
      'total_due': totalDue,
      'paid_amount': paidAmount,
      'paid_penalty_amount': paidPenaltyAmount,
      'late_penalty_amount': latePenaltyAmount,
      'status': status.name,
    };
  }
}
