import 'package:dartz/dartz.dart';
import 'package:ufg/core/errors/failures.dart';
import 'package:ufg/features/auth/domain/repositories/auth_repository.dart';

class ResetPassword {
  final AuthRepository authRepo;
  ResetPassword(this.authRepo);
  Future<Either<Failures, void>> call(String email, String password) async =>
      await authRepo.resetPassword(
        email,
        password,
      ); //Future<void> call(String email, String password) async {
}
