import 'package:equatable/equatable.dart';

/// Server-calculated member lending limit. Flutter displays this value only;
/// submission is always recalculated in PostgreSQL.
class MemberLoanLimitEntity extends Equatable {
  final String memberId;
  final double totalSavings;
  final double maximumLoanAmount;
  final double globalCap;

  const MemberLoanLimitEntity({
    required this.memberId,
    required this.totalSavings,
    required this.maximumLoanAmount,
    required this.globalCap,
  });

  @override
  List<Object?> get props => [
    memberId,
    totalSavings,
    maximumLoanAmount,
    globalCap,
  ];
}
