import 'package:equatable/equatable.dart';

abstract class LoanEvent extends Equatable {
  const LoanEvent();

  @override
  List<Object?> get props => [];
}

class LoadLoansDashboardRequested extends LoanEvent {}

class LoadLoanProductsRequested extends LoanEvent {}

class SubmitLoanApplicationRequested extends LoanEvent {
  final String loanProductId;
  final double requestedAmount;
  final String? purpose;
  final String? guarantorMemberId;

  const SubmitLoanApplicationRequested({
    required this.loanProductId,
    required this.requestedAmount,
    this.purpose,
    this.guarantorMemberId,
  });

  @override
  List<Object?> get props => [
        loanProductId,
        requestedAmount,
        purpose,
        guarantorMemberId,
      ];
}

class CancelLoanApplicationRequested extends LoanEvent {
  final String applicationId;

  const CancelLoanApplicationRequested(this.applicationId);

  @override
  List<Object?> get props => [applicationId];
}

class LoadLoanApplicationDetailRequested extends LoanEvent {
  final String applicationId;

  const LoadLoanApplicationDetailRequested(this.applicationId);

  @override
  List<Object?> get props => [applicationId];
}

class EvaluateLoanEligibilityRequested extends LoanEvent {
  final String applicationId;

  const EvaluateLoanEligibilityRequested(this.applicationId);

  @override
  List<Object?> get props => [applicationId];
}

class RequestLoanGuarantorRequested extends LoanEvent {
  final String loanApplicationId;
  final String guarantorMemberId;

  const RequestLoanGuarantorRequested({
    required this.loanApplicationId,
    required this.guarantorMemberId,
  });

  @override
  List<Object?> get props => [loanApplicationId, guarantorMemberId];
}

class LoadGuarantorRequestsRequested extends LoanEvent {}

class RespondToGuarantorRequestEvent extends LoanEvent {
  final String guarantorRequestId;
  final bool accept;

  const RespondToGuarantorRequestEvent({
    required this.guarantorRequestId,
    required this.accept,
  });

  @override
  List<Object?> get props => [guarantorRequestId, accept];
}

class LoadLoanDetailsRequested extends LoanEvent {
  final String loanId;

  const LoadLoanDetailsRequested(this.loanId);

  @override
  List<Object?> get props => [loanId];
}

class RequestLoanExtensionRequested extends LoanEvent {
  final String loanId;
  final String reason;
  final DateTime? requestedNewDueDate;

  const RequestLoanExtensionRequested({
    required this.loanId,
    required this.reason,
    this.requestedNewDueDate,
  });

  @override
  List<Object?> get props => [loanId, reason, requestedNewDueDate];
}

class SubmitLoanRepaymentRequested extends LoanEvent {
  final String loanId;
  final double amount;
  final String paymentMethodCode;
  final String externalReference;
  final String? filePath;
  final String? fileName;
  final String? mimeType;
  final int? fileSizeBytes;
  final List<Map<String, dynamic>>? allocations;

  const SubmitLoanRepaymentRequested({
    required this.loanId,
    required this.amount,
    required this.paymentMethodCode,
    required this.externalReference,
    this.filePath,
    this.fileName,
    this.mimeType,
    this.fileSizeBytes,
    this.allocations,
  });

  @override
  List<Object?> get props => [
        loanId,
        amount,
        paymentMethodCode,
        externalReference,
        filePath,
        fileName,
        mimeType,
        fileSizeBytes,
        allocations,
      ];
}
