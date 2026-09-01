import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ufg/core/errors/failures.dart';
import 'package:ufg/features/savings/domain/entities/savings_history_item_entity.dart';
import 'package:ufg/features/savings/domain/entities/savings_obligation_entity.dart';
import 'package:ufg/features/savings/domain/entities/savings_summary_entity.dart';
import 'package:ufg/features/savings/domain/entities/withdrawal_request_entity.dart';
import 'package:ufg/features/savings/domain/repositories/savings_repository.dart';
import 'package:ufg/features/savings/domain/usecases/cancel_withdrawal_request.dart';
import 'package:ufg/features/savings/domain/usecases/get_savings_history.dart';
import 'package:ufg/features/savings/domain/usecases/get_savings_obligations.dart';
import 'package:ufg/features/savings/domain/usecases/get_savings_summary.dart';
import 'package:ufg/features/savings/domain/usecases/get_withdrawal_requests.dart';
import 'package:ufg/features/savings/domain/usecases/request_savings_withdrawal.dart';
import 'package:ufg/features/savings/domain/usecases/submit_savings_payment.dart';
import 'package:ufg/features/savings/domain/usecases/upload_payment_proof.dart';
import 'package:ufg/features/savings/presentation/bloc/savings_bloc.dart';
import 'package:ufg/features/savings/presentation/bloc/savings_event.dart';
import 'package:ufg/features/savings/presentation/bloc/savings_state.dart';

class FakeSavingsRepository implements SavingsRepository {
  SavingsSummaryEntity? summaryToReturn;
  List<SavingsObligationEntity> obligationsToReturn = [];
  List<SavingsHistoryItemEntity> historyToReturn = [];
  List<WithdrawalRequestEntity> withdrawalRequestsToReturn = [];
  Failures? failureToReturn;

  @override
  Future<Either<Failures, SavingsSummaryEntity>> getSavingsSummary() async {
    if (failureToReturn != null) return Left(failureToReturn!);
    return Right(summaryToReturn ??
        const SavingsSummaryEntity(
          memberId: 'mem-1',
          totalSavings: 10000,
          securedSavings: 2000,
          availableToWithdraw: 8000,
          savingsAccountStatus: 'active',
        ));
  }

  @override
  Future<Either<Failures, List<SavingsObligationEntity>>> getSavingsObligations() async {
    if (failureToReturn != null) return Left(failureToReturn!);
    return Right(obligationsToReturn);
  }

  @override
  Future<Either<Failures, List<SavingsHistoryItemEntity>>> getSavingsHistory() async {
    if (failureToReturn != null) return Left(failureToReturn!);
    return Right(historyToReturn);
  }

  @override
  Future<Either<Failures, Map<String, dynamic>>> submitSavingsPayment({
    required double amount,
    required String paymentMethodCode,
    required String externalReference,
    String? paymentProofPath,
    String? obligationId,
  }) async {
    if (failureToReturn != null) return Left(failureToReturn!);
    return Right({'payment_id': 'pay-123', 'status': 'pending'});
  }

  @override
  Future<Either<Failures, WithdrawalRequestEntity>> requestSavingsWithdrawal({
    required double amount,
    String? reason,
  }) async {
    if (failureToReturn != null) return Left(failureToReturn!);
    return Right(WithdrawalRequestEntity(
      id: 'wdr-1',
      memberId: 'mem-1',
      amount: amount,
      status: WithdrawalStatus.pending,
      requestedAt: DateTime.now(),
    ));
  }

  @override
  Future<Either<Failures, WithdrawalRequestEntity>> cancelWithdrawalRequest({
    required String withdrawalRequestId,
  }) async {
    if (failureToReturn != null) return Left(failureToReturn!);
    return Right(WithdrawalRequestEntity(
      id: withdrawalRequestId,
      memberId: 'mem-1',
      amount: 1000,
      status: WithdrawalStatus.cancelled,
      requestedAt: DateTime.now(),
    ));
  }

  @override
  Future<Either<Failures, List<WithdrawalRequestEntity>>> getWithdrawalRequests() async {
    if (failureToReturn != null) return Left(failureToReturn!);
    return Right(withdrawalRequestsToReturn);
  }

  @override
  Future<Either<Failures, String>> uploadPaymentProof({
    required String filePath,
    required String fileName,
    required String mimeType,
    required int fileSizeBytes,
  }) async {
    if (failureToReturn != null) return Left(failureToReturn!);
    return const Right('storage/path/proof.jpg');
  }
}

void main() {
  late FakeSavingsRepository repository;
  late SavingsBloc bloc;

  setUp(() {
    repository = FakeSavingsRepository();
    bloc = SavingsBloc(
      getSavingsSummary: GetSavingsSummary(repository),
      getSavingsObligations: GetSavingsObligations(repository),
      getSavingsHistory: GetSavingsHistory(repository),
      submitSavingsPayment: SubmitSavingsPayment(repository),
      requestSavingsWithdrawal: RequestSavingsWithdrawal(repository),
      cancelWithdrawalRequest: CancelWithdrawalRequest(repository),
      getWithdrawalRequests: GetWithdrawalRequests(repository),
      uploadPaymentProof: UploadPaymentProof(repository),
    );
  });

  tearDown(() {
    bloc.close();
  });

  group('SavingsBloc Tests', () {
    test('initial state is SavingsInitial', () {
      expect(bloc.state, isA<SavingsInitial>());
    });

    test('emits [SavingsLoading, SavingsSummaryLoaded] when LoadSavingsSummaryRequested is added', () async {
      final expected = [
        isA<SavingsLoading>(),
        isA<SavingsSummaryLoaded>(),
      ];

      expectLater(bloc.stream, emitsInOrder(expected));
      bloc.add(LoadSavingsSummaryRequested());
    });

    test('emits [SavingsLoading, SavingsObligationsLoaded] when LoadSavingsObligationsRequested is added', () async {
      final expected = [
        isA<SavingsLoading>(),
        isA<SavingsObligationsLoaded>(),
      ];

      expectLater(bloc.stream, emitsInOrder(expected));
      bloc.add(LoadSavingsObligationsRequested());
    });

    test('emits [SavingsActionInProgress, SavingsActionInProgress, SavingsActionSuccess] on SubmitSavingsPaymentRequested', () async {
      final expected = [
        isA<SavingsActionInProgress>(),
        isA<SavingsActionInProgress>(),
        isA<SavingsActionSuccess>(),
      ];

      expectLater(bloc.stream, emitsInOrder(expected));
      bloc.add(const SubmitSavingsPaymentRequested(
        amount: 2000,
        paymentMethodCode: 'bank_transfer',
        externalReference: 'TXN123456',
      ));
    });

    test('emits [SavingsActionInProgress, SavingsActionSuccess] on RequestSavingsWithdrawalRequested', () async {
      final expected = [
        isA<SavingsActionInProgress>(),
        isA<SavingsActionSuccess>(),
      ];

      expectLater(bloc.stream, emitsInOrder(expected));
      bloc.add(const RequestSavingsWithdrawalRequested(
        amount: 3000,
        reason: 'Emergency fund',
      ));
    });

    test('emits [SavingsLoading, SavingsFailure] when repository returns a failure', () async {
      repository.failureToReturn = const Failures(message: 'Server error');

      final expected = [
        isA<SavingsLoading>(),
        const SavingsFailure(message: 'Server error'),
      ];

      expectLater(bloc.stream, emitsInOrder(expected));
      bloc.add(LoadSavingsSummaryRequested());
    });
  });
}
