import 'package:dartz/dartz.dart';
import 'package:ufg/core/errors/failures.dart';
import 'package:ufg/features/membership/domain/entities/membership_application_entity.dart';
import 'package:ufg/features/membership/domain/repositories/membership_repository.dart';

class SubmitMembershipApplicationParams {
  final String nationalId;
  final String address;
  final DateTime dateOfBirth;
  final String phone;

  const SubmitMembershipApplicationParams({
    required this.nationalId,
    required this.address,
    required this.dateOfBirth,
    required this.phone,
  });
}

class SubmitMembershipApplication {
  final MembershipRepository repository;

  SubmitMembershipApplication(this.repository);

  Future<Either<Failures, MembershipApplicationEntity>> call(
    SubmitMembershipApplicationParams params,
  ) async {
    return repository.submitApplication(
      nationalId: params.nationalId,
      address: params.address,
      dateOfBirth: params.dateOfBirth,
      phone: params.phone,
    );
  }
}
