import 'package:dartz/dartz.dart';
import 'package:ufg/core/errors/failures.dart';
import 'package:ufg/features/savings/domain/repositories/savings_repository.dart';

class SubmitSavingsPayment {
  final SavingsRepository repository;

  SubmitSavingsPayment(this.repository);

  Future<Either<Failures, Map<String, dynamic>>> call({
    required double amount,
    required String paymentMethodCode,
    required String externalReference,
    String? paymentProofPath,
    String? obligationId,
  }) async {
    return await repository.submitSavingsPayment(
      amount: amount,
      paymentMethodCode: paymentMethodCode,
      externalReference: externalReference,
      paymentProofPath: paymentProofPath,
      obligationId: obligationId,
    );
  }
}
