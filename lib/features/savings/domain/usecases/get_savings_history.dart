import 'package:dartz/dartz.dart';
import 'package:ufg/core/errors/failures.dart';
import 'package:ufg/features/savings/domain/entities/savings_history_item_entity.dart';
import 'package:ufg/features/savings/domain/repositories/savings_repository.dart';

class GetSavingsHistory {
  final SavingsRepository repository;

  GetSavingsHistory(this.repository);

  Future<Either<Failures, List<SavingsHistoryItemEntity>>> call() async {
    return await repository.getSavingsHistory();
  }
}
