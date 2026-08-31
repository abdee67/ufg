import 'package:ufg/features/auth/domain/entities/profile_entity.dart';

class ProfileModel extends ProfileEntity {
  const ProfileModel({
    required super.id,
    required super.fullName,
    super.phone,
    super.email,
    super.address,
    super.dateOfBirth,
    required super.status,
    super.roles = const [],
    required super.createdAt,
    required super.updatedAt,
  });

  factory ProfileModel.fromJson(
    Map<String, dynamic> json, {
    List<String> roles = const [],
  }) {
    return ProfileModel(
      id: json['id'] as String,
      fullName: json['full_name'] as String,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      address: json['address'] as String?,
      dateOfBirth: json['date_of_birth'] != null
          ? DateTime.parse(json['date_of_birth'] as String)
          : null,
      status: ProfileStatus.fromString(json['status'] as String?),
      roles: roles,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'phone': phone,
      'email': email,
      'address': address,
      'date_of_birth': dateOfBirth?.toIso8601String().split('T').first,
      'status': status.toDbString(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
