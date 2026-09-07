import 'package:equatable/equatable.dart';

enum LoanStatus {
  approved,
  readyForDisbursement,
  active,
  paid,
  overdue,
  defaulted,
  cancelled,
  recovered,
}

class LoanEntity extends Equatable {
  final String id;
  final String loanNumber;
  final String? loanApplicationId;
  final String borrowerProfileId;
  final String? memberId;
  final double principal;
  final double serviceChargeRate;
  final double serviceChargeAmount;
  final double totalRepayment;
  final int termMonths;
  final LoanStatus status;
  final DateTime? disbursedAt;
  final DateTime? maturityDate;
  final double totalPaid;
  final double totalPenaltiesPaid;
  final double outstandingBase;

  const LoanEntity({
    required this.id,
    required this.loanNumber,
    this.loanApplicationId,
    required this.borrowerProfileId,
    this.memberId,
    required this.principal,
    required this.serviceChargeRate,
    required this.serviceChargeAmount,
    required this.totalRepayment,
    required this.termMonths,
    required this.status,
    this.disbursedAt,
    this.maturityDate,
    this.totalPaid = 0.0,
    this.totalPenaltiesPaid = 0.0,
    required this.outstandingBase,
  });

  bool get isActive => status == LoanStatus.active;
  bool get isPaid => status == LoanStatus.paid;
  bool get isOverdue => status == LoanStatus.overdue;
  bool get isDefaulted => status == LoanStatus.defaulted;

  /// Progress of repayment from 0.0 to 1.0.
  double get repaymentProgress {
    if (totalRepayment <= 0) return 0.0;
    return (totalPaid / totalRepayment).clamp(0.0, 1.0);
  }

  @override
  List<Object?> get props => [
    id,
    loanNumber,
    loanApplicationId,
    borrowerProfileId,
    memberId,
    principal,
    serviceChargeRate,
    serviceChargeAmount,
    totalRepayment,
    termMonths,
    status,
    disbursedAt,
    maturityDate,
    totalPaid,
    totalPenaltiesPaid,
    outstandingBase,
  ];
}
