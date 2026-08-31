import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ufg/core/errors/failures.dart';
import 'package:ufg/core/errors/failures/auth_failures.dart';
import 'package:ufg/features/auth/data/datasources/auth_data_source.dart';
import 'package:ufg/features/auth/domain/entities/profile_entity.dart';
import 'package:ufg/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthDataSource remoteDataSource;
  AuthRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failures, Session>> signIn(
    String email,
    String password,
  ) async {
    return authRepositoryGuard(() async {
      final result = await remoteDataSource.signIn(email, password);
      return result;
    });
  }

  @override
  Future<Either<Failures, void>> signUp(
    String email,
    String password,
    String fullName,
    String phone,
  ) async {
    return authRepositoryGuard(() async {
      final signup = await remoteDataSource.signUp(
        email,
        password,
        fullName,
        phone,
      );
      return signup;
    });
  }

  @override
  Future<Either<Failures, void>> sendOtp(String email) async {
    return authRepositoryGuard(() async {
      return await remoteDataSource.sendOtp(email);
    });
  }

  @override
  Future<Either<Failures, void>> verifyOtp(String email, String otp) async {
    return authRepositoryGuard(() async {
      return await remoteDataSource.verifyOTP(email, otp);
    });
  }

  @override
  Future<Either<Failures, void>> verifyPasswordResetOtp(
    String email,
    String otp,
  ) async {
    return authRepositoryGuard(() async {
      return await remoteDataSource.verifyPasswordResetOtp(email, otp);
    });
  }

  @override
  Future<Either<Failures, void>> signOut() async {
    return authRepositoryGuard(() async {
      final signout = await remoteDataSource.signOut();
      return signout;
    });
  }

  @override
  Future<Either<Failures, String>> checkStartupSession() async {
    return authRepositoryGuard(() async {
      final status = await remoteDataSource.checkStartupSession();
      return status;
    });
  }

  @override
  Future<Either<Failures, void>> forgotPassword(String email) async {
    return authRepositoryGuard(() async {
      final forgotPassword = await remoteDataSource.forgotPassword(email);
      return forgotPassword;
    });
  }

  @override
  Future<Either<Failures, void>> resetPassword(
    String email,
    String password,
  ) async {
    return authRepositoryGuard(() async {
      final reset = await remoteDataSource.resetPassword(email, password);
      return reset;
    });
  }

  @override
  Future<Either<Failures, ProfileEntity>> getCurrentProfile() async {
    return authRepositoryGuard(() async {
      final profile = await remoteDataSource.getCurrentProfile();
      return profile;
    });
  }
}
