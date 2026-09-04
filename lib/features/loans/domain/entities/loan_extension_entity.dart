import 'package:equatable/equatable.dart';

enum ExtensionStatus {
  pending,
  approved,
  rejected,
}

class LoanExtensionEntity extends Equatable {
  final String id;
  final String loanId;
  final String requestedBy;
  final String reason;
  final DateTime? requestedNewDueDate;
  final ExtensionStatus status;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final DateTime createdAt;

  const LoanExtensionEntity({
    required this.id,
    required this.loanId,
    required this.requestedBy,
    required this.reason,
    this.requestedNewDueDate,
    required this.status,
    this.reviewedBy,
    this.reviewedAt,
    required this.createdAt,
  });

  bool get isPending => status == ExtensionStatus.pending;
  bool get isApproved => status == ExtensionStatus.approved;
  bool get isRejected => status == ExtensionStatus.rejected;

  @override
  List<Object?> get props => [
        id,
        loanId,
        requestedBy,
        reason,
        requestedNewDueDate,
        status,
        reviewedBy,
        reviewedAt,
        createdAt,
      ];
}
