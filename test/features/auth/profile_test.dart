import 'package:flutter_test/flutter_test.dart';
import 'package:ufg/features/auth/data/models/profile_model.dart';
import 'package:ufg/features/auth/domain/entities/profile_entity.dart';

void main() {
  group('ProfileEntity & ProfileModel', () {
    test('ProfileStatus enum parsing', () {
      expect(ProfileStatus.fromString('active'), ProfileStatus.active);
      expect(ProfileStatus.fromString('suspended'), ProfileStatus.suspended);
      expect(ProfileStatus.fromString('inactive'), ProfileStatus.inactive);
      expect(ProfileStatus.fromString('other'), ProfileStatus.active);
    });

    test('ProfileEntity role helpers', () {
      final nonMember = ProfileEntity(
        id: 'u1',
        fullName: 'Test User',
        status: ProfileStatus.active,
        roles: const ['non_member'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(nonMember.isNonMember, true);
      expect(nonMember.isMember, false);
      expect(nonMember.isAdmin, false);

      final member = ProfileEntity(
        id: 'u2',
        fullName: 'Member User',
        status: ProfileStatus.active,
        roles: const ['member'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(member.isMember, true);
      expect(member.isNonMember, false);

      final admin = ProfileEntity(
        id: 'u3',
        fullName: 'Admin User',
        status: ProfileStatus.active,
        roles: const ['admin'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(admin.isAdmin, true);
    });

    test('ProfileModel JSON serialization', () {
      final json = {
        'id': 'u-100',
        'full_name': 'Abebe Bikila',
        'phone': '+251911223344',
        'email': 'abebe@example.com',
        'address': 'Addis Ababa, Bole',
        'date_of_birth': '1995-05-15',
        'status': 'active',
        'created_at': '2026-01-01T00:00:00.000Z',
        'updated_at': '2026-01-01T00:00:00.000Z',
      };

      final model = ProfileModel.fromJson(json, roles: ['non_member']);

      expect(model.id, 'u-100');
      expect(model.fullName, 'Abebe Bikila');
      expect(model.phone, '+251911223344');
      expect(model.email, 'abebe@example.com');
      expect(model.address, 'Addis Ababa, Bole');
      expect(model.dateOfBirth, DateTime.parse('1995-05-15'));
      expect(model.status, ProfileStatus.active);
      expect(model.roles, ['non_member']);
      expect(model.isNonMember, true);
    });
  });
}
