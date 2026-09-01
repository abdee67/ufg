import 'package:equatable/equatable.dart';

abstract class SavingsEvent extends Equatable {
  const SavingsEvent();

  @override
  List<Object?> get props => [];
}

class LoadSavingsSummaryRequested extends SavingsEvent {}

class LoadSavingsObligationsRequested extends SavingsEvent {}

class LoadSavingsHistoryRequested extends SavingsEvent {}

class LoadWithdrawalRequestsRequested extends SavingsEvent {}

class SubmitSavingsPaymentRequested extends SavingsEvent {
  final double amount;
  final String paymentMethodCode;
  final String externalReference;
  final String? filePath;
  final String? fileName;
  final String? mimeType;
  final int? fileSizeBytes;
  final String? obligationId;

  const SubmitSavingsPaymentRequested({
    required this.amount,
    required this.paymentMethodCode,
    required this.externalReference,
    this.filePath,
    this.fileName,
    this.mimeType,
    this.fileSizeBytes,
    this.obligationId,
  });

  @override
  List<Object?> get props => [
        amount,
        paymentMethodCode,
        externalReference,
        filePath,
        fileName,
        mimeType,
        fileSizeBytes,
        obligationId,
      ];
}

class RequestSavingsWithdrawalRequested extends SavingsEvent {
  final double amount;
  final String? reason;

  const RequestSavingsWithdrawalRequested({
    required this.amount,
    this.reason,
  });

  @override
  List<Object?> get props => [amount, reason];
}

class CancelWithdrawalRequested extends SavingsEvent {
  final String withdrawalRequestId;

  const CancelWithdrawalRequested({required this.withdrawalRequestId});

  @override
  List<Object?> get props => [withdrawalRequestId];
}
