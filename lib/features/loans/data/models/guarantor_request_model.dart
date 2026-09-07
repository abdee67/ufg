import 'package:ufg/features/loans/domain/entities/guarantor_request_entity.dart';
import 'package:ufg/features/loans/domain/entities/loan_product_entity.dart';

class GuarantorRequestModel extends GuarantorRequestEntity {
  const GuarantorRequestModel({
    required super.id,
    super.borrowerType,
    required super.loanApplicationId,
    required super.guarantorMemberId,
    super.guarantorName,
    super.borrowerName,
    super.borrowerPhone,
    required super.guaranteedAmount,
    required super.potentialResponsibility,
    required super.status,
    super.requestedAt,
    super.respondedAt,
    super.approvedAt,
    super.rejectedAt,
    super.releasedAt,
    super.requestedLoanAmount,
    super.serviceChargeAmount,
    super.totalRepayment,
    super.termMonths,
  });

  static GuarantorStatus _parseStatus(String? raw) {
    switch (raw?.toLowerCase()) {
      case 'accepted':
        return GuarantorStatus.accepted;
      case 'rejected':
        return GuarantorStatus.rejected;
      case 'replaced':
        return GuarantorStatus.replaced;
      case 'released':
        return GuarantorStatus.released;
      case 'requested':
      default:
        return GuarantorStatus.requested;
    }
  }

  factory GuarantorRequestModel.fromJson(Map<String, dynamic> json) {
    final borrowerType = (json['borrower_type'] as String?)?.toLowerCase() == 'outsider'
        ? BorrowerType.outsider
        : BorrowerType.member;
    final requestedAmount = (json['requested_amount'] as num?)?.toDouble() ??
        (json['requested_loan_amount'] as num?)?.toDouble() ??
        0.0;
    final serviceRate = (json['service_charge_rate'] as num?)?.toDouble();
    final totalRepayment = (json['total_repayment'] as num?)?.toDouble() ?? 0.0;
    return GuarantorRequestModel(
      id: json['id'] as String,
      borrowerType: borrowerType,
      loanApplicationId: json['application_id'] as String? ?? json['loan_application_id'] as String? ?? '',
      guarantorMemberId: json['guarantor_member_id'] as String? ?? '',
      guarantorName: json['guarantor_name'] as String?,
      borrowerName: json['applicant_name'] as String? ?? json['borrower_name'] as String?,
      borrowerPhone: json['applicant_phone'] as String? ?? json['borrower_phone'] as String?,
      guaranteedAmount: (json['guaranteed_amount'] as num?)?.toDouble() ?? requestedAmount,
      potentialResponsibility: (json['potential_responsibility'] as num?)?.toDouble() ?? totalRepayment,
      status: _parseStatus(json['status'] as String?),
      requestedAt: json['requested_at'] != null ? DateTime.tryParse(json['requested_at'] as String) : null,
      respondedAt: json['responded_at'] != null ? DateTime.tryParse(json['responded_at'] as String) : null,
      approvedAt: json['approved_at'] != null ? DateTime.tryParse(json['approved_at'] as String) : null,
      rejectedAt: json['rejected_at'] != null ? DateTime.tryParse(json['rejected_at'] as String) : null,
      releasedAt: json['released_at'] != null ? DateTime.tryParse(json['released_at'] as String) : null,
      requestedLoanAmount: requestedAmount,
      serviceChargeAmount: (json['service_charge_amount'] as num?)?.toDouble() ??
          (serviceRate == null ? 0.0 : requestedAmount * serviceRate),
      totalRepayment: totalRepayment,
      termMonths: (json['term_months'] as num?)?.toInt() ?? 3,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'borrower_type': borrowerType.name,
      'loan_application_id': loanApplicationId,
      'guarantor_member_id': guarantorMemberId,
      'guarantor_name': guarantorName,
      'borrower_name': borrowerName,
      'borrower_phone': borrowerPhone,
      'guaranteed_amount': guaranteedAmount,
      'potential_responsibility': potentialResponsibility,
      'status': status.name,
      'requested_at': requestedAt?.toIso8601String(),
      'responded_at': respondedAt?.toIso8601String(),
      'approved_at': approvedAt?.toIso8601String(),
      'rejected_at': rejectedAt?.toIso8601String(),
      'released_at': releasedAt?.toIso8601String(),
      'requested_loan_amount': requestedLoanAmount,
      'service_charge_amount': serviceChargeAmount,
      'total_repayment': totalRepayment,
      'term_months': termMonths,
    };
  }
}
