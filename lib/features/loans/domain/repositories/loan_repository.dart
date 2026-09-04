import 'package:dartz/dartz.dart';
import 'package:ufg/core/errors/failures.dart';
import 'package:ufg/features/loans/domain/entities/guarantor_request_entity.dart';
import 'package:ufg/features/loans/domain/entities/loan_application_entity.dart';
import 'package:ufg/features/loans/domain/entities/loan_eligibility_result_entity.dart';
import 'package:ufg/features/loans/domain/entities/loan_entity.dart';
import 'package:ufg/features/loans/domain/entities/loan_installment_entity.dart';
import 'package:ufg/features/loans/domain/entities/loan_product_entity.dart';

abstract class LoanRepository {
  Future<Either<Failures, List<LoanProductEntity>>> getLoanProducts();

  Future<Either<Failures, List<LoanApplicationEntity>>> getMyLoanApplications();

  Future<Either<Failures, List<LoanEntity>>> getMyLoans();

  Future<Either<Failures, Map<String, dynamic>>> getLoanApplicationDetail(String applicationId);

  Future<Either<Failures, Map<String, dynamic>>> submitLoanApplication({
    required String loanProductId,
    required double requestedAmount,
    String? purpose,
  });

  Future<Either<Failures, void>> cancelLoanApplication(String applicationId);

  Future<Either<Failures, LoanEligibilityResultEntity>> evaluateLoanEligibility(String applicationId);

  Future<Either<Failures, void>> requestLoanGuarantor({
    required String loanApplicationId,
    required String guarantorMemberId,
  });

  Future<Either<Failures, List<GuarantorRequestEntity>>> getMyGuarantorRequests();

  Future<Either<Failures, void>> respondToGuarantorRequest({
    required String guarantorRequestId,
    required bool accept,
  });

  Future<Either<Failures, void>> requestLoanExtension({
    required String loanId,
    required String reason,
    DateTime? requestedNewDueDate,
  });

  Future<Either<Failures, List<LoanInstallmentEntity>>> getLoanInstallments(String loanId);

  Future<Either<Failures, Map<String, dynamic>>> submitLoanRepaymentPayment({
    required String loanId,
    required double amount,
    required String paymentMethodCode,
    required String externalReference,
    String? paymentProofPath,
    List<Map<String, dynamic>>? allocations,
  });

  Future<Either<Failures, String>> uploadPaymentProof({
    required String filePath,
    required String fileName,
    required String mimeType,
    required int fileSizeBytes,
  });
}
