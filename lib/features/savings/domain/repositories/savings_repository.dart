import 'package:dartz/dartz.dart';
import 'package:ufg/core/errors/failures.dart';
import 'package:ufg/features/savings/domain/entities/savings_history_item_entity.dart';
import 'package:ufg/features/savings/domain/entities/savings_obligation_entity.dart';
import 'package:ufg/features/savings/domain/entities/savings_summary_entity.dart';
import 'package:ufg/features/savings/domain/entities/withdrawal_request_entity.dart';

abstract class SavingsRepository {
  Future<Either<Failures, SavingsSummaryEntity>> getSavingsSummary();

  Future<Either<Failures, List<SavingsObligationEntity>>> getSavingsObligations();

  Future<Either<Failures, List<SavingsHistoryItemEntity>>> getSavingsHistory();

  Future<Either<Failures, Map<String, dynamic>>> submitSavingsPayment({
    required double amount,
    required String paymentMethodCode,
    required String externalReference,
    String? paymentProofPath,
    String? obligationId,
  });

  Future<Either<Failures, WithdrawalRequestEntity>> requestSavingsWithdrawal({
    required double amount,
    String? reason,
  });

  Future<Either<Failures, WithdrawalRequestEntity>> cancelWithdrawalRequest({
    required String withdrawalRequestId,
  });

  Future<Either<Failures, List<WithdrawalRequestEntity>>> getWithdrawalRequests();

  Future<Either<Failures, String>> uploadPaymentProof({
    required String filePath,
    required String fileName,
    required String mimeType,
    required int fileSizeBytes,
  });
}
