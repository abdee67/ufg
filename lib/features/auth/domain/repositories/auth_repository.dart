import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ufg/core/errors/failures.dart';
import 'package:ufg/features/auth/domain/entities/profile_entity.dart';

abstract class AuthRepository {
  Future<Either<Failures, void>> signUp(
    String password,
    String fullName,
    String phone,
  );
  Future<Either<Failures, Session>> signIn(String phone, String password);
  Future<Either<Failures, void>> changePassword(String password);
  Future<Either<Failures, bool>> requiresPasswordChange();
  Future<Either<Failures, String>> checkStartupSession();
  Future<Either<Failures, void>> signOut();
  Future<Either<Failures, ProfileEntity>> getCurrentProfile();
}
