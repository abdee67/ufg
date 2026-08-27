import 'package:dartz/dartz.dart';
import 'package:ufg/core/errors/failures.dart';
import 'package:ufg/features/auth/domain/repositories/auth_repository.dart';

class VerifyPasswordResetOtp {
  final AuthRepository authRepository;

  VerifyPasswordResetOtp(this.authRepository);

  Future<Either<Failures, void>> call(String email, String otp) {
    return authRepository.verifyPasswordResetOtp(email, otp);
  }
}
