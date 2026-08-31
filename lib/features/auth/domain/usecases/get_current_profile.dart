import 'package:dartz/dartz.dart';
import 'package:ufg/core/errors/failures.dart';
import 'package:ufg/features/auth/domain/entities/profile_entity.dart';
import 'package:ufg/features/auth/domain/repositories/auth_repository.dart';

class GetCurrentProfile {
  final AuthRepository repository;

  GetCurrentProfile(this.repository);

  Future<Either<Failures, ProfileEntity>> call() {
    return repository.getCurrentProfile();
  }
}
