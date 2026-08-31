import 'package:dartz/dartz.dart';
import 'package:ufg/core/errors/failures.dart';
import 'package:ufg/features/membership/domain/entities/member_entity.dart';
import 'package:ufg/features/membership/domain/entities/membership_application_entity.dart';
import 'package:ufg/features/membership/domain/repositories/membership_repository.dart';

/// Composite status returned by GetMembershipStatus.
class MembershipStatusResult {
  final MembershipApplicationEntity? application;
  final MemberEntity? member;

  const MembershipStatusResult({this.application, this.member});

  bool get isActiveMember => member != null && member!.isActive;
  bool get hasPendingApplication => application != null && application!.isPending;
  bool get isApproved => application != null && application!.isApproved;
  bool get isRejected => application != null && application!.isRejected;
  bool get hasNoApplication => application == null;
}

class GetMembershipStatus {
  final MembershipRepository repository;

  GetMembershipStatus(this.repository);

  Future<Either<Failures, MembershipStatusResult>> call() async {
    // Fetch application
    final appResult = await repository.getMyApplication();
    MembershipApplicationEntity? application;
    if (appResult.isRight()) {
      application = appResult.getOrElse(() => null);
    } else {
      return Left(appResult.fold((l) => l, (_) => const Failures(message: 'Unknown error')));
    }

    // Fetch member details
    final memberResult = await repository.getMyMemberDetails();
    MemberEntity? member;
    if (memberResult.isRight()) {
      member = memberResult.getOrElse(() => null);
    } else {
      return Left(memberResult.fold((l) => l, (_) => const Failures(message: 'Unknown error')));
    }

    return Right(MembershipStatusResult(
      application: application,
      member: member,
    ));
  }
}
