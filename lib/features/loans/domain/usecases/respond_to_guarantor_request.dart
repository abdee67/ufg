import 'package:dartz/dartz.dart';
import 'package:ufg/core/errors/failures.dart';
import 'package:ufg/features/loans/domain/repositories/loan_repository.dart';

class RespondToGuarantorRequest {
  final LoanRepository repository;

  RespondToGuarantorRequest(this.repository);

  Future<Either<Failures, void>> call({
    required String guarantorRequestId,
    required bool accept,
  }) async {
    return await repository.respondToGuarantorRequest(
      guarantorRequestId: guarantorRequestId,
      accept: accept,
    );
  }
}
