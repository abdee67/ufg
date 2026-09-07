import 'package:equatable/equatable.dart';

/// Minimal, privacy-safe identity returned by the guarantor search RPC.
class GuarantorCandidateEntity extends Equatable {
  final String memberId;
  final String memberNumber;
  final String displayName;

  const GuarantorCandidateEntity({
    required this.memberId,
    required this.memberNumber,
    required this.displayName,
  });

  @override
  List<Object?> get props => [memberId, memberNumber, displayName];
}
