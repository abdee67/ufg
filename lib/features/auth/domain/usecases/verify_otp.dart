import 'package:dartz/dartz.dart';
import 'package:ufg/core/errors/failures.dart';
import 'package:ufg/features/auth/domain/repositories/auth_repository.dart';

class VerifyOTP {
  final AuthRepository repository;
  VerifyOTP(this.repository);

  Future<Either<Failures, void>> call(String email, String otp) {
    return repository.verifyOtp(email, otp);
  }
}
