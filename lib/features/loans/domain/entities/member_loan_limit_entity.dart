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

  const MemberLoanLimitEntity({
    required this.memberId,
    required this.totalSavings,
    required this.maximumLoanAmount,
    required this.globalCap,
    this.paidSavingMonths = 0,
    this.requiredSavingMonths = 2,
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
  ];
}
