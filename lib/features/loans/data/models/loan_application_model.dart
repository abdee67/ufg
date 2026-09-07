import 'package:ufg/features/loans/data/models/loan_product_model.dart';
import 'package:ufg/features/loans/domain/entities/loan_application_entity.dart';

class LoanApplicationModel extends LoanApplicationEntity {
  const LoanApplicationModel({
    required super.id,
    required super.applicationNumber,
    required super.applicantProfileId,
    super.memberId,
    required super.loanProductId,
    required super.requestedAmount,
    super.approvedAmount,
    super.purpose,
    required super.status,
    super.eligibilityStatus,
    super.eligibilitySnapshot,
    super.createdAt,
    super.submittedAt,
    super.reviewedAt,
    super.approvedAt,
    super.product,
    super.approvalCount,
  });

  static LoanApplicationStatus _parseStatus(String? raw) {
    switch (raw?.toLowerCase()) {
      case 'submitted':
        return LoanApplicationStatus.submitted;
      case 'eligible':
        return LoanApplicationStatus.eligible;
      case 'ineligible':
        return LoanApplicationStatus.ineligible;
      case 'under_review':
        return LoanApplicationStatus.underReview;
      case 'approved':
        return LoanApplicationStatus.approved;
      case 'rejected':
        return LoanApplicationStatus.rejected;
      case 'cancelled':
        return LoanApplicationStatus.cancelled;
      case 'expired':
        return LoanApplicationStatus.expired;
      case 'draft':
      default:
        return LoanApplicationStatus.draft;
    }
  }

  factory LoanApplicationModel.fromJson(Map<String, dynamic> json) {
    LoanProductModel? product;
    if (json['product'] != null && json['product'] is Map) {
      product = LoanProductModel.fromJson(Map<String, dynamic>.from(json['product'] as Map));
    }

    int approvalCount = 0;
    if (json['approvals'] != null && json['approvals'] is List) {
      final list = json['approvals'] as List;
      approvalCount = list.where((a) => a is Map && a['decision'] == 'approved').length;
    } else if (json['approved_count'] != null) {
      approvalCount = (json['approved_count'] as num).toInt();
    }

    return LoanApplicationModel(
      id: json['id'] as String,
      applicationNumber: json['application_number'] as String? ?? '',
      applicantProfileId: json['applicant_profile_id'] as String? ?? '',
      memberId: json['member_id'] as String?,
      loanProductId: json['loan_product_id'] as String? ?? '',
      requestedAmount: (json['requested_amount'] as num?)?.toDouble() ?? 0.0,
      approvedAmount: (json['approved_amount'] as num?)?.toDouble(),
      purpose: json['purpose'] as String?,
      status: _parseStatus(json['status'] as String?),
      eligibilityStatus: json['eligibility_status'] as String?,
      eligibilitySnapshot: json['eligibility_snapshot'] is Map
          ? Map<String, dynamic>.from(json['eligibility_snapshot'] as Map)
          : const {},
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      submittedAt: json['submitted_at'] != null ? DateTime.tryParse(json['submitted_at'] as String) : null,
      reviewedAt: json['reviewed_at'] != null ? DateTime.tryParse(json['reviewed_at'] as String) : null,
      approvedAt: json['approved_at'] != null ? DateTime.tryParse(json['approved_at'] as String) : null,
      product: product,
      approvalCount: approvalCount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'application_number': applicationNumber,
      'applicant_profile_id': applicantProfileId,
      'member_id': memberId,
      'loan_product_id': loanProductId,
      'requested_amount': requestedAmount,
      'approved_amount': approvedAmount,
      'purpose': purpose,
      'status': status.name,
      'eligibility_status': eligibilityStatus,
      'eligibility_snapshot': eligibilitySnapshot,
      'created_at': createdAt?.toIso8601String(),
      'submitted_at': submittedAt?.toIso8601String(),
      'reviewed_at': reviewedAt?.toIso8601String(),
      'approved_at': approvedAt?.toIso8601String(),
    };
  }
}
