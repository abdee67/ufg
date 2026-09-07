import 'package:dartz/dartz.dart';
import 'package:ufg/core/errors/failures.dart';
import 'package:ufg/features/loans/domain/entities/member_loan_limit_entity.dart';
import 'package:ufg/features/loans/domain/repositories/loan_repository.dart';

class GetMyMemberLoanLimit {
  final LoanRepository repository;
  GetMyMemberLoanLimit(this.repository);

  Future<Either<Failures, MemberLoanLimitEntity>> call() =>
      repository.getMyMemberLoanLimit();
}
