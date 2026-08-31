import 'package:ufg/features/membership/domain/entities/member_entity.dart';

class MemberModel extends MemberEntity {
  const MemberModel({
    required super.id,
    required super.profileId,
    required super.memberNumber,
    required super.membershipDate,
    required super.status,
    required super.createdAt,
    required super.updatedAt,
  });

  factory MemberModel.fromJson(Map<String, dynamic> json) {
    return MemberModel(
      id: json['id'] as String,
      profileId: json['profile_id'] as String,
      memberNumber: json['member_number'] as String,
      membershipDate: DateTime.parse(json['membership_date'] as String),
      status: MemberStatus.fromString(json['status'] as String?),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}
