import 'package:dartz/dartz.dart';
import 'package:ufg/core/errors/failures.dart';
import 'package:ufg/features/membership/domain/repositories/membership_repository.dart';

class CancelMembershipApplication {
  final MembershipRepository repository;

  CancelMembershipApplication(this.repository);

  Future<Either<Failures, void>> call(String applicationId) async {
    return repository.cancelApplication(applicationId);
  }
}
