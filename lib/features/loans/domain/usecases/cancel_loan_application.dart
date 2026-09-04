import 'package:dartz/dartz.dart';
import 'package:ufg/core/errors/failures.dart';
import 'package:ufg/features/loans/domain/repositories/loan_repository.dart';

class CancelLoanApplication {
  final LoanRepository repository;

  CancelLoanApplication(this.repository);

  Future<Either<Failures, void>> call(String applicationId) async {
    return await repository.cancelLoanApplication(applicationId);
  }
}
