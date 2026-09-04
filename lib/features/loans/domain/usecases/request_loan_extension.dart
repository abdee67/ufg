import 'package:dartz/dartz.dart';
import 'package:ufg/core/errors/failures.dart';
import 'package:ufg/features/loans/domain/repositories/loan_repository.dart';

class RequestLoanExtension {
  final LoanRepository repository;

  RequestLoanExtension(this.repository);

  Future<Either<Failures, void>> call({
    required String loanId,
    required String reason,
    DateTime? requestedNewDueDate,
  }) async {
    return await repository.requestLoanExtension(
      loanId: loanId,
      reason: reason,
      requestedNewDueDate: requestedNewDueDate,
    );
  }
}
