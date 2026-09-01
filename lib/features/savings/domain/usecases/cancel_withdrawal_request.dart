import 'package:dartz/dartz.dart';
import 'package:ufg/core/errors/failures.dart';
import 'package:ufg/features/savings/domain/entities/withdrawal_request_entity.dart';
import 'package:ufg/features/savings/domain/repositories/savings_repository.dart';

class CancelWithdrawalRequest {
  final SavingsRepository repository;

  CancelWithdrawalRequest(this.repository);

  Future<Either<Failures, WithdrawalRequestEntity>> call({
    required String withdrawalRequestId,
  }) async {
    return await repository.cancelWithdrawalRequest(
      withdrawalRequestId: withdrawalRequestId,
    );
  }
}
