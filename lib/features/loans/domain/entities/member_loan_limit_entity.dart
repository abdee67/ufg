import 'package:equatable/equatable.dart';

/// Server-calculated member lending limit. Flutter displays this value only;
/// submission is always recalculated in PostgreSQL.
class MemberLoanLimitEntity extends Equatable {
  final String memberId;
  final double totalSavings;
  final double maximumLoanAmount;
  final double globalCap;
  final int paidSavingMonths;
  final int requiredSavingMonths;
  final bool hasActiveLoan;
  final bool hasPendingApplication;
  final String? activeLoanId;
  final String? pendingApplicationId;
  final String? blockReason;
  final bool canApply;

  const MemberLoanLimitEntity({
    required this.memberId,
    required this.totalSavings,
    required this.maximumLoanAmount,
    required this.globalCap,
    this.paidSavingMonths = 0,
    this.requiredSavingMonths = 2,
    this.hasActiveLoan = false,
    this.hasPendingApplication = false,
    this.activeLoanId,
    this.pendingApplicationId,
    this.blockReason,
    this.canApply = true,
  });

  bool get meetsMinimumSavingHistory =>
      paidSavingMonths >= requiredSavingMonths;

  @override
  List<Object?> get props => [
    memberId,
    totalSavings,
    maximumLoanAmount,
    globalCap,
    paidSavingMonths,
    requiredSavingMonths,
    hasActiveLoan,
    hasPendingApplication,
    activeLoanId,
    pendingApplicationId,
    blockReason,
    canApply,
  ];
}
