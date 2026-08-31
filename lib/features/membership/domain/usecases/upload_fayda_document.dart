import 'package:dartz/dartz.dart';
import 'package:ufg/core/errors/failures.dart';
import 'package:ufg/features/membership/domain/repositories/membership_repository.dart';

class UploadFaydaDocument {
  final MembershipRepository repository;

  UploadFaydaDocument(this.repository);

  Future<Either<Failures, String>> call({
    required String filePath,
    required String fileName,
    required String mimeType,
    required int fileSizeBytes,
  }) {
    return repository.uploadFaydaDocument(
      filePath: filePath,
      fileName: fileName,
      mimeType: mimeType,
      fileSizeBytes: fileSizeBytes,
    );
  }
}
