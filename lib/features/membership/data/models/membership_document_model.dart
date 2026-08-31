import 'package:ufg/features/membership/domain/entities/membership_document_entity.dart';

class MembershipDocumentModel extends MembershipDocumentEntity {
  const MembershipDocumentModel({
    required super.id,
    required super.applicationId,
    required super.applicantId,
    required super.storagePath,
    required super.fileName,
    required super.mimeType,
    required super.fileSizeBytes,
    required super.verificationStatus,
    required super.createdAt,
    required super.updatedAt,
  });

  factory MembershipDocumentModel.fromJson(Map<String, dynamic> json) {
    return MembershipDocumentModel(
      id: json['id'] as String,
      applicationId: json['application_id'] as String,
      applicantId: json['applicant_id'] as String,
      storagePath: json['storage_path'] as String,
      fileName: json['file_name'] as String,
      mimeType: json['mime_type'] as String,
      fileSizeBytes: (json['file_size_bytes'] as num).toInt(),
      verificationStatus: DocumentVerificationStatus.fromString(
        json['verification_status'] as String?,
      ),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}
