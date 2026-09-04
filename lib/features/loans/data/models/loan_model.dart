import 'package:ufg/features/loans/domain/entities/loan_entity.dart';

class LoanModel extends LoanEntity {
  const LoanModel({
    required super.id,
    required super.loanNumber,
    super.loanApplicationId,
    required super.borrowerProfileId,
    super.memberId,
    required super.principal,
    required super.serviceChargeRate,
    required super.serviceChargeAmount,
    required super.totalRepayment,
    required super.termMonths,
    required super.status,
    super.disbursedAt,
    super.maturityDate,
    super.totalPaid,
    super.totalPenaltiesPaid,
    required super.outstandingBase,
  });

  static LoanStatus _parseStatus(String? raw) {
    switch (raw?.toLowerCase()) {
      case 'ready_for_disbursement':
        return LoanStatus.readyForDisbursement;
      case 'active':
        return LoanStatus.active;
      case 'paid':
        return LoanStatus.paid;
      case 'overdue':
        return LoanStatus.overdue;
      case 'defaulted':
        return LoanStatus.defaulted;
      case 'cancelled':
        return LoanStatus.cancelled;
      case 'recovered':
        return LoanStatus.recovered;
      case 'approved':
      default:
        return LoanStatus.approved;
    }
  }

  factory LoanModel.fromJson(Map<String, dynamic> json) {
    final principal = (json['principal'] as num?)?.toDouble() ?? 0.0;
    final totalRepayment = (json['total_repayment'] as num?)?.toDouble() ?? principal;
    final totalPaid = (json['total_paid'] as num?)?.toDouble() ?? 0.0;
    final totalPenaltiesPaid = (json['total_penalties_paid'] as num?)?.toDouble() ?? 0.0;

    double outstanding = (json['outstanding_base'] as num?)?.toDouble() ?? (totalRepayment - totalPaid);
    if (outstanding < 0) outstanding = 0.0;

    return LoanModel(
      id: json['id'] as String,
      loanNumber: json['loan_number'] as String? ?? '',
      loanApplicationId: json['loan_application_id'] as String?,
      borrowerProfileId: json['borrower_profile_id'] as String? ?? '',
      memberId: json['member_id'] as String?,
      principal: principal,
      serviceChargeRate: (json['service_charge_rate'] as num?)?.toDouble() ?? 0.10,
      serviceChargeAmount: (json['service_charge_amount'] as num?)?.toDouble() ?? 0.0,
      totalRepayment: totalRepayment,
      termMonths: (json['term_months'] as num?)?.toInt() ?? 3,
      status: _parseStatus(json['status'] as String?),
      disbursedAt: json['disbursed_at'] != null ? DateTime.tryParse(json['disbursed_at'] as String) : null,
      maturityDate: json['maturity_date'] != null ? DateTime.tryParse(json['maturity_date'] as String) : null,
      totalPaid: totalPaid,
      totalPenaltiesPaid: totalPenaltiesPaid,
      outstandingBase: outstanding,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'loan_number': loanNumber,
      'loan_application_id': loanApplicationId,
      'borrower_profile_id': borrowerProfileId,
      'member_id': memberId,
      'principal': principal,
      'service_charge_rate': serviceChargeRate,
      'service_charge_amount': serviceChargeAmount,
      'total_repayment': totalRepayment,
      'term_months': termMonths,
      'status': status.name,
      'disbursed_at': disbursedAt?.toIso8601String(),
      'maturity_date': maturityDate?.toIso8601String(),
      'total_paid': totalPaid,
      'total_penalties_paid': totalPenaltiesPaid,
      'outstanding_base': outstandingBase,
    };
  }
}
