import 'package:equatable/equatable.dart';

abstract class MembershipEvent extends Equatable {
  const MembershipEvent();

  @override
  List<Object?> get props => [];
}

class LoadMembershipStatusRequested extends MembershipEvent {
  const LoadMembershipStatusRequested();
}

class SubmitMembershipApplicationRequested extends MembershipEvent {
  final String nationalId;
  final String address;
  final DateTime dateOfBirth;
  final String phone;

  const SubmitMembershipApplicationRequested({
    required this.nationalId,
    required this.address,
    required this.dateOfBirth,
    required this.phone,
  });

  @override
  List<Object?> get props => [nationalId, address, dateOfBirth, phone];
}

class CancelMembershipApplicationRequested extends MembershipEvent {
  final String applicationId;

  const CancelMembershipApplicationRequested(this.applicationId);

  @override
  List<Object?> get props => [applicationId];
}
