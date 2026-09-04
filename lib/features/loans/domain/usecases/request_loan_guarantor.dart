import 'package:dartz/dartz.dart';
import 'package:ufg/core/errors/failures.dart';
import 'package:ufg/features/loans/domain/repositories/loan_repository.dart';

class RequestLoanGuarantor {
  final LoanRepository repository;

  RequestLoanGuarantor(this.repository);

  Future<Either<Failures, void>> call({
    required String loanApplicationId,
    required String guarantorMemberId,
  }) async {
    return await repository.requestLoanGuarantor(
      loanApplicationId: loanApplicationId,
      guarantorMemberId: guarantorMemberId,
    );
  }
}
