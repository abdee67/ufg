import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:ufg/core/errors/failures.dart';
import 'package:ufg/features/membership/domain/entities/member_entity.dart';
import 'package:ufg/features/membership/domain/entities/membership_application_entity.dart';
import 'package:ufg/features/membership/domain/entities/profile_entity.dart';
import 'package:ufg/features/membership/domain/repositories/membership_repository.dart';

class MembershipStatusResult extends Equatable {
  final ProfileEntity profile;
  final MembershipApplicationEntity? application;
  final MemberEntity? member;

  const MembershipStatusResult({
    required this.profile,
    this.application,
    this.member,
  });

  bool get isApprovedMember => member != null && member!.status == MemberStatus.active;
  bool get hasPendingApplication =>
      application != null &&
      (application!.status == MembershipApplicationStatus.pending ||
          application!.status == MembershipApplicationStatus.underReview);
  bool get isRejected =>
      application != null && application!.status == MembershipApplicationStatus.rejected;
  bool get canApply => !isApprovedMember && !hasPendingApplication;

  @override
  List<Object?> get props => [profile, application, member];
}

class GetMembershipStatus {
  final MembershipRepository repository;

  GetMembershipStatus(this.repository);

  Future<Either<Failures, MembershipStatusResult>> call() async {
    final profileResult = await repository.getCurrentProfile();

    return profileResult.fold(
      (failure) => Left(failure),
      (profile) async {
        final appResult = await repository.getLatestApplication();
        final memberResult = await repository.getActiveMemberDetails();

        MembershipApplicationEntity? application;
        MemberEntity? member;

        appResult.fold((_) {}, (app) => application = app);
        memberResult.fold((_) {}, (m) => member = m);

        return Right(
          MembershipStatusResult(
            profile: profile,
            application: application,
            member: member,
          ),
        );
      },
    );
  }
}
