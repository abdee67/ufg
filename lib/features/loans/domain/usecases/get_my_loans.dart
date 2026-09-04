import 'package:dartz/dartz.dart';
import 'package:ufg/core/errors/failures.dart';
import 'package:ufg/features/loans/domain/entities/loan_entity.dart';
import 'package:ufg/features/loans/domain/repositories/loan_repository.dart';

class GetMyLoans {
  final LoanRepository repository;

  GetMyLoans(this.repository);

  Future<Either<Failures, List<LoanEntity>>> call() async {
    return await repository.getMyLoans();
  }
}
