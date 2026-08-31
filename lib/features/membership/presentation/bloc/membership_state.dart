import 'package:equatable/equatable.dart';
import 'package:ufg/features/membership/domain/entities/member_entity.dart';
import 'package:ufg/features/membership/domain/entities/membership_application_entity.dart';

abstract class MembershipState extends Equatable {
  const MembershipState();

  @override
  List<Object?> get props => [];
}

class MembershipInitial extends MembershipState {}

class MembershipLoading extends MembershipState {}

/// Status has been loaded. Contains optional application and member data.
class MembershipStatusLoaded extends MembershipState {
  final MembershipApplicationEntity? application;
  final MemberEntity? member;

  const MembershipStatusLoaded({
    this.application,
    this.member,
  });

  bool get isActiveMember => member != null && member!.isActive;
  bool get hasPendingApplication =>
      application != null && application!.isPending;
  bool get isApproved =>
      application != null && application!.isApproved;
  bool get isRejected =>
      application != null && application!.isRejected;
  bool get hasNoApplication => application == null;

  @override
  List<Object?> get props => [application, member];
}

/// Application was submitted successfully.
class MembershipSubmitSuccess extends MembershipState {
  final MembershipApplicationEntity application;

  const MembershipSubmitSuccess({required this.application});

  @override
  List<Object?> get props => [application];
}

/// A generic operation (cancel) succeeded.
class MembershipOperationSuccess extends MembershipState {
  final String message;

  const MembershipOperationSuccess({required this.message});

  @override
  List<Object?> get props => [message];
}

class MembershipFailure extends MembershipState {
  final String message;

  const MembershipFailure({required this.message});

  @override
  List<Object?> get props => [message];
}
