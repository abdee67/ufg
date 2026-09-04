import 'package:dartz/dartz.dart';
import 'package:ufg/core/errors/failures.dart';
import 'package:ufg/features/loans/domain/entities/loan_eligibility_result_entity.dart';
import 'package:ufg/features/loans/domain/repositories/loan_repository.dart';

class EvaluateLoanEligibility {
  final LoanRepository repository;

  EvaluateLoanEligibility(this.repository);

  Future<Either<Failures, LoanEligibilityResultEntity>> call(String applicationId) async {
    return await repository.evaluateLoanEligibility(applicationId);
  }
}
