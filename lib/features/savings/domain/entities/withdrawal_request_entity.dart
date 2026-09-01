import 'package:equatable/equatable.dart';

enum WithdrawalStatus {
  pending,
  approved,
  delayed,
  rejected,
  paid,
  cancelled,
}

class WithdrawalRequestEntity extends Equatable {
  final String id;
  final String memberId;
  final double amount;
  final WithdrawalStatus status;
  final String? reason;
  final DateTime requestedAt;
  final DateTime? reviewedAt;
  final DateTime? paidAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const WithdrawalRequestEntity({
    required this.id,
    required this.memberId,
    required this.amount,
    required this.status,
    this.reason,
    required this.requestedAt,
    this.reviewedAt,
    this.paidAt,
    this.createdAt,
    this.updatedAt,
  });

  bool get isPending => status == WithdrawalStatus.pending;
  bool get isApproved => status == WithdrawalStatus.approved;
  bool get isDelayed => status == WithdrawalStatus.delayed;
  bool get isRejected => status == WithdrawalStatus.rejected;
  bool get isPaid => status == WithdrawalStatus.paid;
  bool get isCancelled => status == WithdrawalStatus.cancelled;

  @override
  List<Object?> get props => [
        id,
        memberId,
        amount,
        status,
        reason,
        requestedAt,
        reviewedAt,
        paidAt,
        createdAt,
        updatedAt,
      ];
}
