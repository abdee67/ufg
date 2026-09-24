import 'package:ufg/features/loans/domain/entities/member_loan_limit_entity.dart';

class MemberLoanLimitModel extends MemberLoanLimitEntity {
  const MemberLoanLimitModel({
    required super.memberId,
    required super.totalSavings,
    required super.maximumLoanAmount,
    required super.globalCap,
    super.paidSavingMonths,
    super.requiredSavingMonths,
    super.hasActiveLoan = false,
    super.hasPendingApplication = false,
    super.activeLoanId,
    super.pendingApplicationId,
    super.blockReason,
    super.canApply = true,
  });

  factory MemberLoanLimitModel.fromJson(Map<String, dynamic> json) {
    return MemberLoanLimitModel(
      memberId: json['member_id'] as String? ?? '',
      totalSavings: (json['total_savings'] as num?)?.toDouble() ?? 0,
      maximumLoanAmount: (json['maximum_loan_amount'] as num?)?.toDouble() ?? 0,
      globalCap: (json['global_cap'] as num?)?.toDouble() ?? 20000,
      paidSavingMonths: (json['paid_saving_months'] as num?)?.toInt() ?? 0,
      requiredSavingMonths: (json['required_saving_months'] as num?)?.toInt() ?? 2,
      hasActiveLoan: json['has_active_loan'] as bool? ?? false,
      hasPendingApplication: json['has_pending_application'] as bool? ?? false,
      activeLoanId: json['active_loan_id'] as String?,
      pendingApplicationId: json['pending_application_id'] as String?,
      blockReason: json['block_reason'] as String?,
      canApply: json['can_apply'] as bool? ?? true,
    );
  }
}
