import 'package:ufg/features/savings/domain/entities/withdrawal_request_entity.dart';

class WithdrawalRequestModel extends WithdrawalRequestEntity {
  const WithdrawalRequestModel({
    required super.id,
    required super.memberId,
    required super.amount,
    required super.status,
    super.reason,
    required super.requestedAt,
    super.reviewedAt,
    super.paidAt,
    super.createdAt,
    super.updatedAt,
  });

  factory WithdrawalRequestModel.fromJson(Map<String, dynamic> json) {
    WithdrawalStatus parseStatus(String? statusStr) {
      switch (statusStr?.toLowerCase()) {
        case 'approved':
          return WithdrawalStatus.approved;
        case 'delayed':
          return WithdrawalStatus.delayed;
        case 'rejected':
          return WithdrawalStatus.rejected;
        case 'paid':
          return WithdrawalStatus.paid;
        case 'cancelled':
          return WithdrawalStatus.cancelled;
        case 'pending':
        default:
          return WithdrawalStatus.pending;
      }
    }

    return WithdrawalRequestModel(
      id: json['id'] as String? ?? '',
      memberId: json['member_id'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      status: parseStatus(json['status'] as String?),
      reason: json['reason'] as String?,
      requestedAt: json['requested_at'] != null
          ? DateTime.tryParse(json['requested_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      reviewedAt: json['reviewed_at'] != null
          ? DateTime.tryParse(json['reviewed_at'].toString())
          : null,
      paidAt: json['paid_at'] != null
          ? DateTime.tryParse(json['paid_at'].toString())
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }
}
