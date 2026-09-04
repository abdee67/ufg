import 'package:equatable/equatable.dart';

enum InstallmentStatus {
  pending,
  partiallyPaid,
  paid,
  overdue,
  defaulted,
}

class LoanInstallmentEntity extends Equatable {
  final String id;
  final String loanId;
  final int installmentNumber;
  final DateTime dueDate;
  final double principalAmount;
  final double serviceChargeAmount;
  final double totalDue;
  final double paidAmount;
  final double paidPenaltyAmount;
  final double latePenaltyAmount;
  final InstallmentStatus status;

  const LoanInstallmentEntity({
    required this.id,
    required this.loanId,
    required this.installmentNumber,
    required this.dueDate,
    required this.principalAmount,
    required this.serviceChargeAmount,
    required this.totalDue,
    this.paidAmount = 0.0,
    this.paidPenaltyAmount = 0.0,
    this.latePenaltyAmount = 0.0,
    required this.status,
  });

  bool get isPaid => status == InstallmentStatus.paid;
  bool get isOverdue => status == InstallmentStatus.overdue;
  bool get isDefaulted => status == InstallmentStatus.defaulted;
  bool get hasLatePenalty => latePenaltyAmount > 0;

  /// Remaining base amount to be paid for this installment.
  double get remainingBaseAmount => (totalDue - paidAmount).clamp(0.0, totalDue);

  /// Remaining penalty amount to be paid for this installment.
  double get remainingPenaltyAmount => (latePenaltyAmount - paidPenaltyAmount).clamp(0.0, latePenaltyAmount);

  /// Total remaining amount due (Base remaining + Penalty remaining).
  double get totalRemainingDue => remainingBaseAmount + remainingPenaltyAmount;

  @override
  List<Object?> get props => [
        id,
        loanId,
        installmentNumber,
        dueDate,
        principalAmount,
        serviceChargeAmount,
        totalDue,
        paidAmount,
        paidPenaltyAmount,
        latePenaltyAmount,
        status,
      ];
}
