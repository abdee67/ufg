import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ufg/core/errors/exceptions/auth_exceptions.dart';
import 'package:ufg/core/errors/failures.dart';
import 'package:ufg/features/membership/data/datasources/membership_remote_data_source.dart';
import 'package:ufg/features/membership/domain/entities/member_entity.dart';
import 'package:ufg/features/membership/domain/entities/membership_application_entity.dart';
import 'package:ufg/features/membership/domain/repositories/membership_repository.dart';

class MembershipRepositoryImpl implements MembershipRepository {
  final MembershipRemoteDataSource remoteDataSource;

  MembershipRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failures, MembershipApplicationEntity?>>
  getMyApplication() async {
    try {
      final application = await remoteDataSource.getMyApplication();
      return Right(application);
    } on AuthExceptions catch (e) {
      return Left(Failures(message: e.message));
    } on PostgrestException catch (e) {
      return Left(Failures(message: e.message));
    } catch (e) {
      return Left(Failures(message: e.toString()));
    }
  }

  @override
  Future<Either<Failures, MemberEntity?>> getMyMemberDetails() async {
    try {
      final member = await remoteDataSource.getMyMemberDetails();
      return Right(member);
    } on AuthExceptions catch (e) {
      return Left(Failures(message: e.message));
    } on PostgrestException catch (e) {
      return Left(Failures(message: e.message));
    } catch (e) {
      return Left(Failures(message: e.toString()));
    }
  }

  @override
  Future<Either<Failures, String>> uploadFaydaDocument({
    required String filePath,
    required String fileName,
    required String mimeType,
    required int fileSizeBytes,
  }) async {
    try {
      final storagePath = await remoteDataSource.uploadFaydaDocument(
        filePath: filePath,
        fileName: fileName,
        mimeType: mimeType,
        fileSizeBytes: fileSizeBytes,
      );
      return Right(storagePath);
    } on AuthExceptions catch (e) {
      return Left(Failures(message: e.message));
    } on StorageException catch (e) {
      return Left(Failures(message: e.message));
    } catch (e) {
      return Left(Failures(message: e.toString()));
    }
  }

  @override
  Future<Either<Failures, MembershipApplicationEntity>> submitApplication({
    required String address,
    required DateTime dateOfBirth,
    required String phone,
    required String storagePath,
    required String fileName,
    required String mimeType,
    required int fileSizeBytes,
  }) async {
    try {
      final application = await remoteDataSource.submitApplication(
        address: address,
        dateOfBirth: dateOfBirth,
        phone: phone,
        storagePath: storagePath,
        fileName: fileName,
        mimeType: mimeType,
        fileSizeBytes: fileSizeBytes,
      );
      return Right(application);
    } on AuthExceptions catch (e) {
      return Left(Failures(message: e.message));
    } on PostgrestException catch (e) {
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
    } on PostgrestException catch (e) {
      return Left(Failures(message: e.message));
    } catch (e) {
      return Left(Failures(message: e.toString()));
    }
  }
}
