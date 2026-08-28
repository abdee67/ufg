import 'package:equatable/equatable.dart';

enum MembershipApplicationStatus {
  pending,
  underReview,
  approved,
  rejected,
  cancelled;

  static MembershipApplicationStatus fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'under_review':
        return MembershipApplicationStatus.underReview;
      case 'approved':
        return MembershipApplicationStatus.approved;
      case 'rejected':
        return MembershipApplicationStatus.rejected;
      case 'cancelled':
        return MembershipApplicationStatus.cancelled;
      case 'pending':
      default:
        return MembershipApplicationStatus.pending;
    }
  }

  String toDbString() {
    switch (this) {
      case MembershipApplicationStatus.underReview:
        return 'under_review';
      case MembershipApplicationStatus.approved:
        return 'approved';
      case MembershipApplicationStatus.rejected:
        return 'rejected';
      case MembershipApplicationStatus.cancelled:
        return 'cancelled';
      case MembershipApplicationStatus.pending:
        return 'pending';
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
