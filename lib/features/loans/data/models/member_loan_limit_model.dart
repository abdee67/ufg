import 'package:ufg/features/loans/domain/entities/member_loan_limit_entity.dart';

class MemberLoanLimitModel extends MemberLoanLimitEntity {
  const MemberLoanLimitModel({
    required super.memberId,
    required super.totalSavings,
    required super.maximumLoanAmount,
    required super.globalCap,
  });

  factory MemberLoanLimitModel.fromJson(Map<String, dynamic> json) {
    return MemberLoanLimitModel(
      memberId: json['member_id'] as String? ?? '',
      totalSavings: (json['total_savings'] as num?)?.toDouble() ?? 0,
      maximumLoanAmount: (json['maximum_loan_amount'] as num?)?.toDouble() ?? 0,
      globalCap: (json['global_cap'] as num?)?.toDouble() ?? 20000,
    );
  }
}
