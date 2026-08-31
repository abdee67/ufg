import 'package:equatable/equatable.dart';

enum DocumentVerificationStatus {
  uploaded,
  underReview,
  verified,
  rejected,
  replacementRequired;

  static DocumentVerificationStatus fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'uploaded':
        return DocumentVerificationStatus.uploaded;
      case 'under_review':
        return DocumentVerificationStatus.underReview;
      case 'verified':
        return DocumentVerificationStatus.verified;
      case 'rejected':
        return DocumentVerificationStatus.rejected;
      case 'replacement_required':
        return DocumentVerificationStatus.replacementRequired;
      default:
        return DocumentVerificationStatus.uploaded;
    }
  }

  String toDbString() {
    switch (this) {
      case DocumentVerificationStatus.underReview:
        return 'under_review';
      case DocumentVerificationStatus.replacementRequired:
        return 'replacement_required';
      default:
        return name.toLowerCase();
    }
  }

  String get displayLabel {
    switch (this) {
      case DocumentVerificationStatus.uploaded:
        return 'Uploaded';
      case DocumentVerificationStatus.underReview:
        return 'Under Review';
      case DocumentVerificationStatus.verified:
        return 'Verified';
      case DocumentVerificationStatus.rejected:
        return 'Rejected';
      case DocumentVerificationStatus.replacementRequired:
        return 'Replacement Required';
    }
  }
}

class MembershipDocumentEntity extends Equatable {
  final String id;
  final String applicationId;
  final String applicantId;
  final String storagePath;
  final String fileName;
  final String mimeType;
  final int fileSizeBytes;
  final DocumentVerificationStatus verificationStatus;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MembershipDocumentEntity({
    required this.id,
    required this.applicationId,
    required this.applicantId,
    required this.storagePath,
    required this.fileName,
    required this.mimeType,
    required this.fileSizeBytes,
    required this.verificationStatus,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        applicationId,
        applicantId,
        storagePath,
        fileName,
        mimeType,
        fileSizeBytes,
        verificationStatus,
        createdAt,
        updatedAt,
      ];
}
