import 'package:dartz/dartz.dart';
import 'package:ufg/core/errors/failures.dart';
import 'package:ufg/features/savings/domain/entities/savings_obligation_entity.dart';
import 'package:ufg/features/savings/domain/repositories/savings_repository.dart';

class GetSavingsObligations {
  final SavingsRepository repository;

  GetSavingsObligations(this.repository);

  Future<Either<Failures, List<SavingsObligationEntity>>> call() async {
    return await repository.getSavingsObligations();
  }
}
