import 'package:equatable/equatable.dart';

enum ProfileStatus {
  active,
  suspended,
  inactive;

  static ProfileStatus fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'suspended':
        return ProfileStatus.suspended;
      case 'inactive':
        return ProfileStatus.inactive;
      case 'active':
      default:
        return ProfileStatus.active;
    }
  }

  String toDbString() => name.toLowerCase();
}

class ProfileEntity extends Equatable {
  final String id;
  final String fullName;
  final String? phone;
  final String? email;
  final String? address;
  final DateTime? dateOfBirth;
  final ProfileStatus status;
  final List<String> roles;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ProfileEntity({
    required this.id,
    required this.fullName,
    this.phone,
    this.email,
    this.address,
    this.dateOfBirth,
    required this.status,
    this.roles = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isMember => roles.contains('member');
  bool get isAdmin => roles.contains('admin') || roles.contains('super_admin');
  bool get isNonMember => roles.contains('non_member') || roles.isEmpty;

  @override
  List<Object?> get props => [
        id,
        fullName,
        phone,
        email,
        address,
        dateOfBirth,
        status,
        roles,
        createdAt,
        updatedAt,
      ];
}
