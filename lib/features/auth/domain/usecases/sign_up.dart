import 'package:dartz/dartz.dart';
import 'package:ufg/core/errors/failures.dart';
import 'package:ufg/features/auth/domain/entities/customer_address_input.dart';
import 'package:ufg/features/auth/domain/repositories/auth_repository.dart';

class SignUp {
  final AuthRepository repo;
  SignUp(this.repo);

  Future<Either<Failures, void>> call(
    String email,
    String password,
    String fullName,
    String phone,
  ) {
    return repo.signUp(email, password, fullName, phone);
  }
}
