import 'package:dartz/dartz.dart';
import 'package:ufg/core/errors/failures.dart';
import 'package:ufg/features/loans/domain/repositories/loan_repository.dart';

class SubmitLoanApplication {
  final LoanRepository repository;

  SubmitLoanApplication(this.repository);

  Future<Either<Failures, Map<String, dynamic>>> call({
    required String loanProductId,
    required double requestedAmount,
    String? purpose,
  }) async {
    return await repository.submitLoanApplication(
      loanProductId: loanProductId,
      requestedAmount: requestedAmount,
      purpose: purpose,
    );
  }
}
