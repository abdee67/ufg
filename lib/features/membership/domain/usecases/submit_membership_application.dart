import 'package:dartz/dartz.dart';
import 'package:ufg/core/errors/failures.dart';
import 'package:ufg/features/membership/domain/entities/membership_application_entity.dart';
import 'package:ufg/features/membership/domain/repositories/membership_repository.dart';

class SubmitMembershipApplication {
  final MembershipRepository repository;

  SubmitMembershipApplication(this.repository);

  Future<Either<Failures, MembershipApplicationEntity>> call({
    required String address,
    required DateTime dateOfBirth,
    required String phone,
    required String storagePath,
    required String fileName,
    required String mimeType,
    required int fileSizeBytes,
  }) {
    return repository.submitApplication(
      address: address,
      dateOfBirth: dateOfBirth,
      phone: phone,
      storagePath: storagePath,
      fileName: fileName,
      mimeType: mimeType,
      fileSizeBytes: fileSizeBytes,
    );
  }
}
