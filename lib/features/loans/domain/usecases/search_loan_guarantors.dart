import 'package:dartz/dartz.dart';
import 'package:ufg/core/errors/failures.dart';
import 'package:ufg/features/loans/domain/entities/guarantor_candidate_entity.dart';
import 'package:ufg/features/loans/domain/repositories/loan_repository.dart';

class SearchLoanGuarantors {
  final LoanRepository repository;
  SearchLoanGuarantors(this.repository);

  Future<Either<Failures, List<GuarantorCandidateEntity>>> call(
    String search,
  ) => repository.searchLoanGuarantors(search);
}
