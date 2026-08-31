import 'package:dartz/dartz.dart';
import 'package:ufg/core/errors/failures.dart';
import 'package:ufg/features/membership/domain/entities/member_entity.dart';
import 'package:ufg/features/membership/domain/entities/membership_application_entity.dart';

/// Repository contract for membership operations.
abstract class MembershipRepository {
  /// Get the latest membership application for the current user.
  Future<Either<Failures, MembershipApplicationEntity?>> getMyApplication();

  /// Get the active member record for the current user (null if not a member).
  Future<Either<Failures, MemberEntity?>> getMyMemberDetails();

  /// Upload the Fayda identity document to Supabase Storage.
  /// Returns the storage object path on success.
  Future<Either<Failures, String>> uploadFaydaDocument({
    required String filePath,
    required String fileName,
    required String mimeType,
    required int fileSizeBytes,
  });

  /// Submit a new membership application via the atomic RPC function.
  Future<Either<Failures, MembershipApplicationEntity>> submitApplication({
    required String address,
    required DateTime dateOfBirth,
    required String phone,
    required String storagePath,
    required String fileName,
    required String mimeType,
    required int fileSizeBytes,
  });

  /// Cancel a pending membership application.
  Future<Either<Failures, void>> cancelApplication(String applicationId);
}
