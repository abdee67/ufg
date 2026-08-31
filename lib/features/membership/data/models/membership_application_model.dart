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

  /// Factory for parsing the JSONB result from the RPC submit function.
  factory MembershipApplicationModel.fromRpcJson(Map<String, dynamic> json) {
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
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.parse(json['created_at'] as String),
    );
  }
}
