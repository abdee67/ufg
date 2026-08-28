import 'package:ufg/features/membership/domain/entities/membership_application_entity.dart';

class MembershipApplicationModel extends MembershipApplicationEntity {
  const MembershipApplicationModel({
    required super.id,
    required super.applicationNumber,
    required super.applicantId,
    required super.status,
    required super.submittedAt,
    super.reviewedBy,
    super.reviewedAt,
    super.rejectionReason,
    required super.createdAt,
    required super.updatedAt,
  });

  factory MembershipApplicationModel.fromJson(Map<String, dynamic> json) {
    return MembershipApplicationModel(
      id: json['id'] as String,
      applicationNumber: json['application_number'] as String,
      applicantId: json['applicant_id'] as String,
      status: MembershipApplicationStatus.fromString(json['status'] as String?),
      submittedAt: DateTime.parse(json['submitted_at'] as String),
      reviewedBy: json['reviewed_by'] as String?,
      reviewedAt: json['reviewed_at'] != null
          ? DateTime.parse(json['reviewed_at'] as String)
          : null,
      rejectionReason: json['rejection_reason'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'application_number': applicationNumber,
      'applicant_id': applicantId,
      'status': status.toDbString(),
      'submitted_at': submittedAt.toIso8601String(),
      'reviewed_by': reviewedBy,
      'reviewed_at': reviewedAt?.toIso8601String(),
      'rejection_reason': rejectionReason,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
