import 'package:dartz/dartz.dart';
import 'package:ufg/core/errors/failures.dart';
import 'package:ufg/features/savings/domain/entities/savings_summary_entity.dart';
import 'package:ufg/features/savings/domain/repositories/savings_repository.dart';

class GetSavingsSummary {
  final SavingsRepository repository;

  GetSavingsSummary(this.repository);

  Future<Either<Failures, SavingsSummaryEntity>> call() async {
    return await repository.getSavingsSummary();
  }
}
