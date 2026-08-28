import 'package:equatable/equatable.dart';
import 'package:ufg/features/membership/domain/usecases/get_membership_status.dart';

abstract class MembershipState extends Equatable {
  const MembershipState();

  @override
  List<Object?> get props => [];
}

class MembershipInitial extends MembershipState {
  const MembershipInitial();
}

class MembershipLoading extends MembershipState {
  const MembershipLoading();
}

class MembershipStatusLoaded extends MembershipState {
  final MembershipStatusResult result;

  const MembershipStatusLoaded(this.result);

  @override
  List<Object?> get props => [result];
}

class MembershipSubmitSuccess extends MembershipState {
  final String applicationNumber;

  const MembershipSubmitSuccess(this.applicationNumber);

  @override
  List<Object?> get props => [applicationNumber];
}

class MembershipOperationSuccess extends MembershipState {
  final String message;

  const MembershipOperationSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class MembershipFailure extends MembershipState {
  final String message;

  const MembershipFailure(this.message);

  @override
  List<Object?> get props => [message];
}
