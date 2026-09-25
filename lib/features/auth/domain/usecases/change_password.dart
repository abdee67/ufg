import 'package:dartz/dartz.dart';
import 'package:ufg/core/errors/failures.dart';
import 'package:ufg/features/auth/domain/repositories/auth_repository.dart';

class ChangePassword {
  ChangePassword(this._repository);

  final AuthRepository _repository;

  Future<Either<Failures, void>> call(String password) =>
      _repository.changePassword(password);
}
