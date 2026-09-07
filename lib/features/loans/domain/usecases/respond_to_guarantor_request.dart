import 'package:dartz/dartz.dart';
import 'package:ufg/core/errors/failures.dart';
import 'package:ufg/features/loans/domain/repositories/loan_repository.dart';
import 'package:ufg/features/loans/domain/entities/loan_product_entity.dart';

class RespondToGuarantorRequest {
  final LoanRepository repository;

  RespondToGuarantorRequest(this.repository);

  Future<Either<Failures, void>> call({
    required String guarantorRequestId,
    required BorrowerType borrowerType,
    required bool accept,
    String? rejectionReason,
  }) async {
    return await repository.respondToGuarantorRequest(
      guarantorRequestId: guarantorRequestId,
      borrowerType: borrowerType,
      accept: accept,
      rejectionReason: rejectionReason,
    );
  }
}
