import 'package:ufg/features/loans/domain/entities/loan_extension_entity.dart';

class LoanExtensionModel extends LoanExtensionEntity {
  const LoanExtensionModel({
    required super.id,
    required super.loanId,
    required super.requestedBy,
    required super.reason,
    super.requestedNewDueDate,
    required super.status,
    super.reviewedBy,
    super.reviewedAt,
    required super.createdAt,
  });

  static ExtensionStatus _parseStatus(String? raw) {
    switch (raw?.toLowerCase()) {
      case 'approved':
        return ExtensionStatus.approved;
      case 'rejected':
        return ExtensionStatus.rejected;
      case 'pending':
      default:
        return ExtensionStatus.pending;
    }
  }

  factory LoanExtensionModel.fromJson(Map<String, dynamic> json) {
    return LoanExtensionModel(
      id: json['id'] as String,
      loanId: json['loan_id'] as String? ?? '',
      requestedBy: json['requested_by'] as String? ?? '',
      reason: json['reason'] as String? ?? '',
      requestedNewDueDate: json['requested_new_due_date'] != null
          ? DateTime.tryParse(json['requested_new_due_date'] as String)
          : null,
      status: _parseStatus(json['status'] as String?),
      reviewedBy: json['reviewed_by'] as String?,
      reviewedAt: json['reviewed_at'] != null ? DateTime.tryParse(json['reviewed_at'] as String) : null,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'loan_id': loanId,
      'requested_by': requestedBy,
      'reason': reason,
      'requested_new_due_date': requestedNewDueDate?.toIso8601String().split('T').first,
      'status': status.name,
      'reviewed_by': reviewedBy,
      'reviewed_at': reviewedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}
