import 'package:dartz/dartz.dart';
import 'package:ufg/core/errors/failures.dart';
import 'package:ufg/features/auth/domain/repositories/auth_repository.dart';

class CheckStartupSession {
  final AuthRepository repository;

  CheckStartupSession(this.repository);

  Future<Either<Failures, String>> call() {
    return repository.checkStartupSession();
  }
}
