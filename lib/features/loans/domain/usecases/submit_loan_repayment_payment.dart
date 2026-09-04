import 'package:dartz/dartz.dart';
import 'package:ufg/core/errors/failures.dart';
import 'package:ufg/features/loans/domain/repositories/loan_repository.dart';

class SubmitLoanRepaymentPayment {
  final LoanRepository repository;

  SubmitLoanRepaymentPayment(this.repository);

  Future<Either<Failures, Map<String, dynamic>>> call({
    required String loanId,
    required double amount,
    required String paymentMethodCode,
    required String externalReference,
    String? paymentProofPath,
    List<Map<String, dynamic>>? allocations,
  }) async {
    return await repository.submitLoanRepaymentPayment(
      loanId: loanId,
      amount: amount,
      paymentMethodCode: paymentMethodCode,
      externalReference: externalReference,
      paymentProofPath: paymentProofPath,
      allocations: allocations,
    );
  }
}
