import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ufg/core/errors/exceptions/auth_exceptions.dart';
import 'package:ufg/core/errors/failures.dart';
import 'package:ufg/features/savings/data/datasources/savings_remote_data_source.dart';
import 'package:ufg/features/savings/domain/entities/savings_history_item_entity.dart';
import 'package:ufg/features/savings/domain/entities/savings_obligation_entity.dart';
import 'package:ufg/features/savings/domain/entities/savings_summary_entity.dart';
import 'package:ufg/features/savings/domain/entities/withdrawal_request_entity.dart';
import 'package:ufg/features/savings/domain/repositories/savings_repository.dart';

class SavingsRepositoryImpl implements SavingsRepository {
  final SavingsRemoteDataSource remoteDataSource;

  SavingsRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failures, SavingsSummaryEntity>> getSavingsSummary() async {
    try {
      final summary = await remoteDataSource.getSavingsSummary();
      return Right(summary);
    } on AuthExceptions catch (e) {
      return Left(Failures(message: e.message));
    } on PostgrestException catch (e) {
      return Left(Failures(message: e.message));
    } catch (e) {
      return Left(Failures(message: e.toString()));
    }
  }

  @override
  Future<Either<Failures, List<SavingsObligationEntity>>> getSavingsObligations() async {
    try {
      final list = await remoteDataSource.getSavingsObligations();
      return Right(list);
    } on AuthExceptions catch (e) {
      return Left(Failures(message: e.message));
    } on PostgrestException catch (e) {
      return Left(Failures(message: e.message));
    } catch (e) {
      return Left(Failures(message: e.toString()));
    }
  }

  @override
  Future<Either<Failures, List<SavingsHistoryItemEntity>>> getSavingsHistory() async {
    try {
      final list = await remoteDataSource.getSavingsHistory();
      return Right(list);
    } on AuthExceptions catch (e) {
      return Left(Failures(message: e.message));
    } on PostgrestException catch (e) {
      return Left(Failures(message: e.message));
    } catch (e) {
      return Left(Failures(message: e.toString()));
    }
  }

  @override
  Future<Either<Failures, Map<String, dynamic>>> submitSavingsPayment({
    required double amount,
    required String paymentMethodCode,
    required String externalReference,
    String? paymentProofPath,
    String? obligationId,
  }) async {
    try {
      final result = await remoteDataSource.submitSavingsPayment(
        amount: amount,
        paymentMethodCode: paymentMethodCode,
        externalReference: externalReference,
        paymentProofPath: paymentProofPath,
        obligationId: obligationId,
      );
      return Right(result);
    } on AuthExceptions catch (e) {
      return Left(Failures(message: e.message));
    } on PostgrestException catch (e) {
      return Left(Failures(message: e.message));
    } catch (e) {
      return Left(Failures(message: e.toString()));
    }
  }

  @override
  Future<Either<Failures, WithdrawalRequestEntity>> requestSavingsWithdrawal({
    required double amount,
    String? reason,
  }) async {
    try {
      final request = await remoteDataSource.requestSavingsWithdrawal(
        amount: amount,
        reason: reason,
      );
      return Right(request);
    } on AuthExceptions catch (e) {
      return Left(Failures(message: e.message));
    } on PostgrestException catch (e) {
      return Left(Failures(message: e.message));
    } catch (e) {
      return Left(Failures(message: e.toString()));
    }
  }

  @override
  Future<Either<Failures, WithdrawalRequestEntity>> cancelWithdrawalRequest({
    required String withdrawalRequestId,
  }) async {
    try {
      final request = await remoteDataSource.cancelWithdrawalRequest(
        withdrawalRequestId: withdrawalRequestId,
      );
      return Right(request);
    } on AuthExceptions catch (e) {
      return Left(Failures(message: e.message));
    } on PostgrestException catch (e) {
      return Left(Failures(message: e.message));
    } catch (e) {
      return Left(Failures(message: e.toString()));
    }
  }

  @override
  Future<Either<Failures, List<WithdrawalRequestEntity>>> getWithdrawalRequests() async {
    try {
      final list = await remoteDataSource.getWithdrawalRequests();
      return Right(list);
    } on AuthExceptions catch (e) {
      return Left(Failures(message: e.message));
    } on PostgrestException catch (e) {
      return Left(Failures(message: e.message));
    } catch (e) {
      return Left(Failures(message: e.toString()));
    }
  }

  @override
  Future<Either<Failures, String>> uploadPaymentProof({
    required String filePath,
    required String fileName,
    required String mimeType,
    required int fileSizeBytes,
  }) async {
    try {
      final path = await remoteDataSource.uploadPaymentProof(
        filePath: filePath,
        fileName: fileName,
        mimeType: mimeType,
        fileSizeBytes: fileSizeBytes,
      );
      return Right(path);
    } on AuthExceptions catch (e) {
      return Left(Failures(message: e.message));
    } on StorageException catch (e) {
      return Left(Failures(message: e.message));
    } catch (e) {
      return Left(Failures(message: e.toString()));
    }
  }
}
