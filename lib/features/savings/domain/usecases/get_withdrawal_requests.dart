import 'package:dartz/dartz.dart';
import 'package:ufg/core/errors/failures.dart';
import 'package:ufg/features/savings/domain/entities/withdrawal_request_entity.dart';
import 'package:ufg/features/savings/domain/repositories/savings_repository.dart';

class GetWithdrawalRequests {
  final SavingsRepository repository;

  GetWithdrawalRequests(this.repository);

  Future<Either<Failures, List<WithdrawalRequestEntity>>> call() async {
    return await repository.getWithdrawalRequests();
  }
}
