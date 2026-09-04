import 'package:dartz/dartz.dart';
import 'package:ufg/core/errors/failures.dart';
import 'package:ufg/features/loans/domain/entities/guarantor_request_entity.dart';
import 'package:ufg/features/loans/domain/repositories/loan_repository.dart';

class GetMyGuarantorRequests {
  final LoanRepository repository;

  GetMyGuarantorRequests(this.repository);

  Future<Either<Failures, List<GuarantorRequestEntity>>> call() async {
    return await repository.getMyGuarantorRequests();
  }
}
