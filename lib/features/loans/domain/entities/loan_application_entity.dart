import 'package:equatable/equatable.dart';
import 'package:ufg/features/loans/domain/entities/loan_product_entity.dart';

enum LoanApplicationStatus {
  draft,
  submitted,
  eligible,
  ineligible,
  underReview,
  approved,
  rejected,
  cancelled,
  expired,
}

class LoanApplicationEntity extends Equatable {
  final String id;
  final String applicationNumber;
  final String applicantProfileId;
  final String? memberId;
  final String loanProductId;
  final double requestedAmount;
  final double? approvedAmount;
  final String? purpose;
  final LoanApplicationStatus status;
  final String? eligibilityStatus;
  final Map<String, dynamic> eligibilitySnapshot;
  final DateTime? submittedAt;
  final DateTime? reviewedAt;
  final DateTime? approvedAt;
  final LoanProductEntity? product;
  final int approvalCount;

  const LoanApplicationEntity({
    required this.id,
    required this.applicationNumber,
    required this.applicantProfileId,
    this.memberId,
    required this.loanProductId,
    required this.requestedAmount,
    this.approvedAmount,
    this.purpose,
    required this.status,
    this.eligibilityStatus,
    this.eligibilitySnapshot = const {},
    this.submittedAt,
    this.reviewedAt,
    this.approvedAt,
    this.product,
    this.approvalCount = 0,
  });

  bool get isApproved => status == LoanApplicationStatus.approved;
  bool get isUnderReview => status == LoanApplicationStatus.underReview;
  bool get isSubmitted => status == LoanApplicationStatus.submitted;
  bool get isRejected => status == LoanApplicationStatus.rejected;
  bool get isCancelled => status == LoanApplicationStatus.cancelled;
  bool get isEligible => eligibilityStatus == 'eligible';

  /// Whether the two-person approval threshold has been met.
  bool get hasTwoApprovals => approvalCount >= 2;

  @override
  List<Object?> get props => [
        id,
        applicationNumber,
        applicantProfileId,
        memberId,
        loanProductId,
        requestedAmount,
        approvedAmount,
        purpose,
        status,
        eligibilityStatus,
        eligibilitySnapshot,
        submittedAt,
        reviewedAt,
        approvedAt,
        product,
        approvalCount,
      ];
}
