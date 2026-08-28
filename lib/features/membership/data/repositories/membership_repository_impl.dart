import 'package:dartz/dartz.dart';
import 'package:ufg/core/errors/exceptions/auth_exceptions.dart';
import 'package:ufg/core/errors/failures.dart';
import 'package:ufg/features/membership/data/datasources/membership_remote_data_source.dart';
import 'package:ufg/features/membership/domain/entities/member_entity.dart';
import 'package:ufg/features/membership/domain/entities/membership_application_entity.dart';
import 'package:ufg/features/membership/domain/entities/profile_entity.dart';
import 'package:ufg/features/membership/domain/repositories/membership_repository.dart';

class MembershipRepositoryImpl implements MembershipRepository {
  final MembershipRemoteDataSource remoteDataSource;

  MembershipRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failures, ProfileEntity>> getCurrentProfile() async {
    try {
      final profile = await remoteDataSource.getCurrentProfile();
      return Right(profile);
    } on AuthExceptions catch (e) {
      return Left(Failures(message: e.message));
    } catch (e) {
      return Left(Failures(message: e.toString()));
    }
  }

  @override
  Future<Either<Failures, MembershipApplicationEntity?>> getLatestApplication() async {
    try {
      final application = await remoteDataSource.getLatestApplication();
      return Right(application);
    } on AuthExceptions catch (e) {
      return Left(Failures(message: e.message));
    } catch (e) {
      return Left(Failures(message: e.toString()));
    }
  }

  @override
  Future<Either<Failures, MemberEntity?>> getActiveMemberDetails() async {
    try {
      final member = await remoteDataSource.getActiveMemberDetails();
      return Right(member);
    } on AuthExceptions catch (e) {
      return Left(Failures(message: e.message));
    } catch (e) {
      return Left(Failures(message: e.toString()));
    }
  }

  @override
  Future<Either<Failures, MembershipApplicationEntity>> submitApplication({
    required String nationalId,
    required String address,
    required DateTime dateOfBirth,
    required String phone,
  }) async {
    try {
      final application = await remoteDataSource.submitApplication(
        nationalId: nationalId,
        address: address,
        dateOfBirth: dateOfBirth,
        phone: phone,
      );
      return Right(application);
    } on AuthExceptions catch (e) {
      return Left(Failures(message: e.message));
    } catch (e) {
      return Left(Failures(message: e.toString()));
    }
  }

  @override
  Future<Either<Failures, void>> cancelApplication(String applicationId) async {
    try {
      await remoteDataSource.cancelApplication(applicationId);
      return const Right(null);
    } on AuthExceptions catch (e) {
      return Left(Failures(message: e.message));
    } catch (e) {
      return Left(Failures(message: e.toString()));
    }
  }
}
