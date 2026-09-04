import 'package:dartz/dartz.dart';
import 'package:ufg/core/errors/failures.dart';
import 'package:ufg/features/loans/domain/entities/loan_installment_entity.dart';
import 'package:ufg/features/loans/domain/repositories/loan_repository.dart';

class GetLoanInstallments {
  final LoanRepository repository;

  GetLoanInstallments(this.repository);

  Future<Either<Failures, List<LoanInstallmentEntity>>> call(String loanId) async {
    return await repository.getLoanInstallments(loanId);
  }
}
