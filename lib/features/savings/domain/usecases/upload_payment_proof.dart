import 'package:dartz/dartz.dart';
import 'package:ufg/core/errors/failures.dart';
import 'package:ufg/features/savings/domain/repositories/savings_repository.dart';

class UploadPaymentProof {
  final SavingsRepository repository;

  UploadPaymentProof(this.repository);

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
