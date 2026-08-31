import 'package:equatable/equatable.dart';

enum MembershipApplicationStatus {
  draft,
  submitted,
  underReview,
  approved,
  rejected,
  cancelled;

  static MembershipApplicationStatus fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'draft':
        return MembershipApplicationStatus.draft;
      case 'submitted':
        return MembershipApplicationStatus.submitted;
      case 'under_review':
        return MembershipApplicationStatus.underReview;
      case 'approved':
        return MembershipApplicationStatus.approved;
      case 'rejected':
        return MembershipApplicationStatus.rejected;
      case 'cancelled':
        return MembershipApplicationStatus.cancelled;
      default:
        return MembershipApplicationStatus.draft;
    }
  }

  String toDbString() {
    switch (this) {
      case MembershipApplicationStatus.underReview:
        return 'under_review';
      default:
        return name.toLowerCase();
    }
  }

  String get displayLabel {
    switch (this) {
      case MembershipApplicationStatus.draft:
        return 'Draft';
      case MembershipApplicationStatus.submitted:
        return 'Submitted';
      case MembershipApplicationStatus.underReview:
        return 'Under Review';
      case MembershipApplicationStatus.approved:
        return 'Approved';
      case MembershipApplicationStatus.rejected:
        return 'Rejected';
      case MembershipApplicationStatus.cancelled:
        return 'Cancelled';
    }
  }
}

class MembershipApplicationEntity extends Equatable {
  final String id;
  final String applicationNumber;
  final String applicantId;
  final MembershipApplicationStatus status;
  final DateTime submittedAt;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final String? rejectionReason;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MembershipApplicationEntity({
    required this.id,
    required this.applicationNumber,
    required this.applicantId,
    required this.status,
    required this.submittedAt,
    this.reviewedBy,
    this.reviewedAt,
    this.rejectionReason,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isPending =>
      status == MembershipApplicationStatus.submitted ||
      status == MembershipApplicationStatus.underReview;
  bool get isApproved => status == MembershipApplicationStatus.approved;
  bool get isRejected => status == MembershipApplicationStatus.rejected;
  bool get isCancellable =>
      status == MembershipApplicationStatus.draft ||
      status == MembershipApplicationStatus.submitted;

  @override
  List<Object?> get props => [
        id,
        applicationNumber,
        applicantId,
        status,
        submittedAt,
        reviewedBy,
        reviewedAt,
        rejectionReason,
        createdAt,
        updatedAt,
      ];
}
