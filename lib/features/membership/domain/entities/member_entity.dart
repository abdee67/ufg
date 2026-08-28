import 'package:equatable/equatable.dart';

enum MemberStatus {
  active,
  suspended,
  removed,
  inactive;

  static MemberStatus fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'suspended':
        return MemberStatus.suspended;
      case 'removed':
        return MemberStatus.removed;
      case 'inactive':
        return MemberStatus.inactive;
      case 'active':
      default:
        return MemberStatus.active;
    }
  }

  String toDbString() => name.toLowerCase();
}

class MemberEntity extends Equatable {
  final String id;
  final String profileId;
  final String memberNumber;
  final DateTime membershipDate;
  final MemberStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MemberEntity({
    required this.id,
    required this.profileId,
    required this.memberNumber,
    required this.membershipDate,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        profileId,
        memberNumber,
        membershipDate,
        status,
        createdAt,
        updatedAt,
      ];
}
