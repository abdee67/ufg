import 'package:dartz/dartz.dart';
import 'package:ufg/core/errors/failures.dart';
import 'package:ufg/features/loans/domain/repositories/loan_repository.dart';

class SubmitOutsiderLoanApplication {
  final LoanRepository repository;
  SubmitOutsiderLoanApplication(this.repository);

  Future<Either<Failures, Map<String, dynamic>>> call({
    required String loanProductId,
    required String fullName,
    required String phone,
    required String address,
    required double requestedAmount,
    required String purpose,
    required String guarantorMemberId,
  }) => repository.submitOutsiderLoanApplication(
    loanProductId: loanProductId,
    fullName: fullName,
    phone: phone,
    address: address,
    requestedAmount: requestedAmount,
    purpose: purpose,
    guarantorMemberId: guarantorMemberId,
  );
}
