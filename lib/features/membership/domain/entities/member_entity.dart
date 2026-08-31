import 'package:equatable/equatable.dart';

enum MemberStatus {
  active,
  suspended,
  removed,
  inactive;

  static MemberStatus fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'active':
        return MemberStatus.active;
      case 'suspended':
        return MemberStatus.suspended;
      case 'removed':
        return MemberStatus.removed;
      case 'inactive':
        return MemberStatus.inactive;
      default:
        return MemberStatus.inactive;
    }
  }

  String toDbString() => name.toLowerCase();

  String get displayLabel {
    switch (this) {
      case MemberStatus.active:
        return 'Active';
      case MemberStatus.suspended:
        return 'Suspended';
      case MemberStatus.removed:
        return 'Removed';
      case MemberStatus.inactive:
        return 'Inactive';
    }
  }
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

  bool get isActive => status == MemberStatus.active;

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
