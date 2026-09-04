import 'package:dartz/dartz.dart';
import 'package:ufg/core/errors/failures.dart';
import 'package:ufg/features/loans/domain/entities/loan_application_entity.dart';
import 'package:ufg/features/loans/domain/repositories/loan_repository.dart';

class GetMyLoanApplications {
  final LoanRepository repository;

  GetMyLoanApplications(this.repository);

  Future<Either<Failures, List<LoanApplicationEntity>>> call() async {
    return await repository.getMyLoanApplications();
  }
}
