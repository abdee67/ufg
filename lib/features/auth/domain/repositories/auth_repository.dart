import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ufg/core/errors/failures.dart';

abstract class AuthRepository {
  Future<Either<Failures, void>> signUp(
    String email,
    String password,
    String fullName,
    String phone,
  );
  Future<Either<Failures, Session>> signIn(String email, String password);
  Future<Either<Failures, void>> sendOtp(String email);
  Future<Either<Failures, void>> verifyOtp(String email, String otp);
  Future<Either<Failures, void>> verifyPasswordResetOtp(
    String email,
    String otp,
  );
  Future<Either<Failures, void>> resetPassword(String email, String password);
  Future<Either<Failures, void>> forgotPassword(String email);
  Future<Either<Failures, String>> checkStartupSession();
  Future<Either<Failures, void>> signOut();

  /*  Future<Either<Failures, CustomerEntity>> getCurrentCustomer();
  Future<Either<Failures, CustomerEntity>> updateCustomerProfile(
    CustomerEntity client,
  );

  Future<Either<Failures, CustomerAddressInput>> getCurrentLocationAddress();
  Future<Either<Failures, CustomerAddressEntity>> createCustomerAddress(
    CustomerAddressInput input,
  );*/
}
