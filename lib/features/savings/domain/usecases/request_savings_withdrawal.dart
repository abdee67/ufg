import 'package:dartz/dartz.dart';
import 'package:ufg/core/errors/failures.dart';
import 'package:ufg/features/savings/domain/entities/withdrawal_request_entity.dart';
import 'package:ufg/features/savings/domain/repositories/savings_repository.dart';

class RequestSavingsWithdrawal {
  final SavingsRepository repository;

  RequestSavingsWithdrawal(this.repository);

  Future<Either<Failures, WithdrawalRequestEntity>> call({
    required double amount,
    String? reason,
  }) async {
    return await repository.requestSavingsWithdrawal(
      amount: amount,
      reason: reason,
    );
  }
}
