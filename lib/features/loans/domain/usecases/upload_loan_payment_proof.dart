import 'package:dartz/dartz.dart';
import 'package:ufg/core/errors/failures.dart';
import 'package:ufg/features/loans/domain/repositories/loan_repository.dart';

class UploadLoanPaymentProof {
  final LoanRepository repository;

  UploadLoanPaymentProof(this.repository);

  Future<Either<Failures, String>> call({
    required String filePath,
    required String fileName,
    required String mimeType,
    required int fileSizeBytes,
  }) async {
    return await repository.uploadPaymentProof(
      filePath: filePath,
      fileName: fileName,
      mimeType: mimeType,
      fileSizeBytes: fileSizeBytes,
    );
  }
}
