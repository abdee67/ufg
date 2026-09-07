import 'package:dartz/dartz.dart';
import 'package:ufg/core/errors/exceptions/auth_exceptions.dart';
import 'package:ufg/core/errors/failures.dart';
import 'package:ufg/features/loans/data/datasources/loans_remote_data_source.dart';
import 'package:ufg/features/loans/domain/entities/guarantor_request_entity.dart';
import 'package:ufg/features/loans/domain/entities/guarantor_candidate_entity.dart';
import 'package:ufg/features/loans/domain/entities/member_loan_limit_entity.dart';
import 'package:ufg/features/loans/domain/entities/loan_application_entity.dart';
import 'package:ufg/features/loans/domain/entities/loan_eligibility_result_entity.dart';
import 'package:ufg/features/loans/domain/entities/loan_entity.dart';
import 'package:ufg/features/loans/domain/entities/loan_installment_entity.dart';
import 'package:ufg/features/loans/domain/entities/loan_product_entity.dart';
import 'package:ufg/features/loans/domain/repositories/loan_repository.dart';

class LoanRepositoryImpl implements LoanRepository {
  final LoansRemoteDataSource remoteDataSource;

  LoanRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failures, List<LoanProductEntity>>> getLoanProducts() async {
    try {
      final result = await remoteDataSource.getLoanProducts();
      return Right(result);
    } on AuthExceptions catch (e) {
      return Left(Failures(message: e.message));
    } catch (e) {
      return Left(Failures(message: e.toString()));
    }
  }

  @override
  Future<Either<Failures, List<LoanApplicationEntity>>>
  getMyLoanApplications() async {
    try {
      final result = await remoteDataSource.getMyLoanApplications();
      return Right(result);
    } on AuthExceptions catch (e) {
      return Left(Failures(message: e.message));
    } catch (e) {
      return Left(Failures(message: e.toString()));
    }
  }

  @override
  Future<Either<Failures, List<LoanEntity>>> getMyLoans() async {
    try {
      final result = await remoteDataSource.getMyLoans();
      return Right(result);
    } on AuthExceptions catch (e) {
      return Left(Failures(message: e.message));
    } catch (e) {
      return Left(Failures(message: e.toString()));
    }
  }

  @override
  Future<Either<Failures, Map<String, dynamic>>> getLoanApplicationDetail(
    String applicationId,
  ) async {
    try {
      final result = await remoteDataSource.getLoanApplicationDetail(
        applicationId,
      );
      return Right(result);
    } on AuthExceptions catch (e) {
      return Left(Failures(message: e.message));
    } catch (e) {
      return Left(Failures(message: e.toString()));
    }
  }

  @override
  Future<Either<Failures, Map<String, dynamic>>> submitLoanApplication({
    required String loanProductId,
    required double requestedAmount,
    String? purpose,
    required String guarantorMemberId,
  }) async {
    try {
      final result = await remoteDataSource.submitLoanApplication(
        loanProductId: loanProductId,
        requestedAmount: requestedAmount,
        purpose: purpose,
        guarantorMemberId: guarantorMemberId,
      );
      return Right(result);
    } on AuthExceptions catch (e) {
      return Left(Failures(message: e.message));
    } catch (e) {
      return Left(Failures(message: e.toString()));
    }
  }

  @override
  Future<Either<Failures, MemberLoanLimitEntity>> getMyMemberLoanLimit() async {
    try {
      return Right(await remoteDataSource.getMyMemberLoanLimit());
    } on AuthExceptions catch (e) {
      return Left(Failures(message: e.message));
    } catch (e) {
      return Left(Failures(message: e.toString()));
    }
  }

  @override
  Future<Either<Failures, List<GuarantorCandidateEntity>>> searchLoanGuarantors(
    String search,
  ) async {
    try {
      return Right(await remoteDataSource.searchLoanGuarantors(search));
    } on AuthExceptions catch (e) {
      return Left(Failures(message: e.message));
    } catch (e) {
      return Left(Failures(message: e.toString()));
    }
  }

  @override
  Future<Either<Failures, LoanProductEntity>>
  getActiveOutsiderLoanProduct() async {
    try {
      return Right(await remoteDataSource.getActiveOutsiderLoanProduct());
    } on AuthExceptions catch (e) {
      return Left(Failures(message: e.message));
    } catch (e) {
      return Left(Failures(message: e.toString()));
    }
  }

  @override
  Future<Either<Failures, Map<String, dynamic>>> submitOutsiderLoanApplication({
    required String loanProductId,
    required String fullName,
    required String phone,
    required String address,
    required double requestedAmount,
    required String purpose,
    required String guarantorMemberId,
  }) async {
    try {
      return Right(
        await remoteDataSource.submitOutsiderLoanApplication(
          loanProductId: loanProductId,
          fullName: fullName,
          phone: phone,
          address: address,
          requestedAmount: requestedAmount,
          purpose: purpose,
          guarantorMemberId: guarantorMemberId,
        ),
      );
    } on AuthExceptions catch (e) {
      return Left(Failures(message: e.message));
    } catch (e) {
      return Left(Failures(message: e.toString()));
    }
  }

  @override
  Future<Either<Failures, void>> cancelLoanApplication(
    String applicationId,
  ) async {
    try {
      await remoteDataSource.cancelLoanApplication(applicationId);
      return const Right(null);
    } on AuthExceptions catch (e) {
      return Left(Failures(message: e.message));
    } catch (e) {
      return Left(Failures(message: e.toString()));
    }
  }

  @override
  Future<Either<Failures, LoanEligibilityResultEntity>> evaluateLoanEligibility(
    String applicationId,
  ) async {
    try {
      final result = await remoteDataSource.evaluateLoanEligibility(
        applicationId,
      );
      return Right(result);
    } on AuthExceptions catch (e) {
      return Left(Failures(message: e.message));
    } catch (e) {
      return Left(Failures(message: e.toString()));
    }
  }

  @override
  Future<Either<Failures, void>> requestLoanGuarantor({
    required String loanApplicationId,
    required String guarantorMemberId,
  }) async {
    try {
      await remoteDataSource.requestLoanGuarantor(
        loanApplicationId: loanApplicationId,
        guarantorMemberId: guarantorMemberId,
      );
      return const Right(null);
    } on AuthExceptions catch (e) {
      return Left(Failures(message: e.message));
    } catch (e) {
      return Left(Failures(message: e.toString()));
    }
  }

  @override
  Future<Either<Failures, List<GuarantorRequestEntity>>>
  getMyGuarantorRequests() async {
    try {
      final result = await remoteDataSource.getMyGuarantorRequests();
      return Right(result);
    } on AuthExceptions catch (e) {
      return Left(Failures(message: e.message));
    } catch (e) {
      return Left(Failures(message: e.toString()));
    }
  }

  @override
  Future<Either<Failures, void>> respondToGuarantorRequest({
    required String guarantorRequestId,
    required BorrowerType borrowerType,
    required bool accept,
    String? rejectionReason,
  }) async {
    try {
      await remoteDataSource.respondToGuarantorRequest(
        guarantorRequestId: guarantorRequestId,
        borrowerType: borrowerType,
        accept: accept,
        rejectionReason: rejectionReason,
      );
      return const Right(null);
    } on AuthExceptions catch (e) {
      return Left(Failures(message: e.message));
    } catch (e) {
      return Left(Failures(message: e.toString()));
    }
  }

  @override
  Future<Either<Failures, void>> requestLoanExtension({
    required String loanId,
    required String reason,
    DateTime? requestedNewDueDate,
  }) async {
    try {
      await remoteDataSource.requestLoanExtension(
        loanId: loanId,
        reason: reason,
        requestedNewDueDate: requestedNewDueDate,
      );
      return const Right(null);
    } on AuthExceptions catch (e) {
      return Left(Failures(message: e.message));
    } catch (e) {
      return Left(Failures(message: e.toString()));
    }
  }

  @override
  Future<Either<Failures, List<LoanInstallmentEntity>>> getLoanInstallments(
    String loanId,
  ) async {
    try {
      final result = await remoteDataSource.getLoanInstallments(loanId);
      return Right(result);
    } on AuthExceptions catch (e) {
      return Left(Failures(message: e.message));
    } catch (e) {
      return Left(Failures(message: e.toString()));
    }
  }

  @override
  Future<Either<Failures, Map<String, dynamic>>> submitLoanRepaymentPayment({
    required String loanId,
    required double amount,
    required String paymentMethodCode,
    required String externalReference,
    String? paymentProofPath,
    List<Map<String, dynamic>>? allocations,
  }) async {
    try {
      final result = await remoteDataSource.submitLoanRepaymentPayment(
        loanId: loanId,
        amount: amount,
        paymentMethodCode: paymentMethodCode,
        externalReference: externalReference,
        paymentProofPath: paymentProofPath,
        allocations: allocations,
      );
      return Right(result);
    } on AuthExceptions catch (e) {
      return Left(Failures(message: e.message));
    } catch (e) {
      return Left(Failures(message: e.toString()));
    }
  }

  @override
  Future<Either<Failures, String>> uploadPaymentProof({
    required String filePath,
    required String fileName,
    required String mimeType,
    required int fileSizeBytes,
  }) async {
    try {
      final result = await remoteDataSource.uploadPaymentProof(
        filePath: filePath,
        fileName: fileName,
        mimeType: mimeType,
        fileSizeBytes: fileSizeBytes,
      );
      return Right(result);
    } on AuthExceptions catch (e) {
      return Left(Failures(message: e.message));
    } catch (e) {
      return Left(Failures(message: e.toString()));
    }
  }
}
