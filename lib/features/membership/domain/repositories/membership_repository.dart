import 'package:dartz/dartz.dart';
import 'package:ufg/core/errors/failures.dart';
import 'package:ufg/features/membership/domain/entities/member_entity.dart';
import 'package:ufg/features/membership/domain/entities/membership_application_entity.dart';
import 'package:ufg/features/membership/domain/entities/profile_entity.dart';

abstract class MembershipRepository {
  Future<Either<Failures, ProfileEntity>> getCurrentProfile();
  
  Future<Either<Failures, MembershipApplicationEntity?>> getLatestApplication();

  Future<Either<Failures, MemberEntity?>> getActiveMemberDetails();

  Future<Either<Failures, MembershipApplicationEntity>> submitApplication({
    required String nationalId,
    required String address,
    required DateTime dateOfBirth,
    required String phone,
  });

  Future<Either<Failures, void>> cancelApplication(String applicationId);
}
