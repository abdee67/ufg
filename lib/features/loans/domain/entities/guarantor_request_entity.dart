import 'package:equatable/equatable.dart';

enum GuarantorStatus {
  requested,
  accepted,
  rejected,
  replaced,
  released,
}

class GuarantorRequestEntity extends Equatable {
  final String id;
  final String loanApplicationId;
  final String guarantorMemberId;
  final String? guarantorName;
  final String? borrowerName;
  final String? borrowerPhone;
  final double guaranteedAmount;
  final double potentialResponsibility;
  final GuarantorStatus status;
  final DateTime? requestedAt;
  final DateTime? approvedAt;
  final DateTime? rejectedAt;
  final DateTime? releasedAt;
  final double requestedLoanAmount;
  final double serviceChargeAmount;
  final double totalRepayment;
  final int termMonths;

  const GuarantorRequestEntity({
    required this.id,
    required this.loanApplicationId,
    required this.guarantorMemberId,
    this.guarantorName,
    this.borrowerName,
    this.borrowerPhone,
    required this.guaranteedAmount,
    required this.potentialResponsibility,
    required this.status,
    this.requestedAt,
    this.approvedAt,
    this.rejectedAt,
    this.releasedAt,
    this.requestedLoanAmount = 0.0,
    this.serviceChargeAmount = 0.0,
    this.totalRepayment = 0.0,
    this.termMonths = 3,
  });

  bool get isPending => status == GuarantorStatus.requested;
  bool get isAccepted => status == GuarantorStatus.accepted;
  bool get isRejected => status == GuarantorStatus.rejected;
  bool get isReleased => status == GuarantorStatus.released;

  @override
  List<Object?> get props => [
        id,
        loanApplicationId,
        guarantorMemberId,
        guarantorName,
        borrowerName,
        borrowerPhone,
        guaranteedAmount,
        potentialResponsibility,
        status,
        requestedAt,
        approvedAt,
        rejectedAt,
        releasedAt,
        requestedLoanAmount,
        serviceChargeAmount,
        totalRepayment,
        termMonths,
      ];
}
