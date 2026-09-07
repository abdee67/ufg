import 'package:dartz/dartz.dart';
import 'package:ufg/core/errors/failures.dart';
import 'package:ufg/features/loans/domain/repositories/loan_repository.dart';

class GetLoanApplicationDetail {
  final LoanRepository repository;

  GetLoanApplicationDetail(this.repository);

  Future<Either<Failures, Map<String, dynamic>>> call(
    String applicationId,
  ) async {
    return await repository.getLoanApplicationDetail(applicationId);
  }
}
