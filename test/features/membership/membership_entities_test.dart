import 'package:flutter_test/flutter_test.dart';
import 'package:ufg/features/membership/domain/entities/member_entity.dart';
import 'package:ufg/features/membership/domain/entities/membership_application_entity.dart';
import 'package:ufg/features/membership/domain/entities/membership_document_entity.dart';
import 'package:ufg/features/membership/domain/usecases/get_membership_status.dart';

void main() {
  group('Membership Entities & Enums', () {
    test('MembershipApplicationStatus parsing and labels', () {
      expect(
        MembershipApplicationStatus.fromString('submitted'),
        MembershipApplicationStatus.submitted,
      );
      expect(
        MembershipApplicationStatus.fromString('under_review'),
        MembershipApplicationStatus.underReview,
      );
      expect(
        MembershipApplicationStatus.fromString('approved'),
        MembershipApplicationStatus.approved,
      );
      expect(
        MembershipApplicationStatus.fromString('rejected'),
        MembershipApplicationStatus.rejected,
      );
      expect(
        MembershipApplicationStatus.fromString('cancelled'),
        MembershipApplicationStatus.cancelled,
      );
      expect(
        MembershipApplicationStatus.fromString('unknown'),
        MembershipApplicationStatus.draft,
      );

      expect(MembershipApplicationStatus.underReview.toDbString(), 'under_review');
      expect(MembershipApplicationStatus.submitted.displayLabel, 'Submitted');
    });

    test('MemberStatus parsing and helpers', () {
      expect(MemberStatus.fromString('active'), MemberStatus.active);
      expect(MemberStatus.fromString('suspended'), MemberStatus.suspended);
      expect(MemberStatus.fromString('removed'), MemberStatus.removed);
      expect(MemberStatus.fromString('inactive'), MemberStatus.inactive);
      expect(MemberStatus.fromString('other'), MemberStatus.inactive);

      final member = MemberEntity(
        id: '123',
        profileId: 'prof-1',
        memberNumber: 'MEM-001',
        membershipDate: DateTime(2026, 1, 1),
        status: MemberStatus.active,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      expect(member.isActive, true);
    });

    test('DocumentVerificationStatus parsing', () {
      expect(
        DocumentVerificationStatus.fromString('uploaded'),
        DocumentVerificationStatus.uploaded,
      );
      expect(
        DocumentVerificationStatus.fromString('verified'),
        DocumentVerificationStatus.verified,
      );
      expect(
        DocumentVerificationStatus.fromString('rejected'),
        DocumentVerificationStatus.rejected,
      );
      expect(
        DocumentVerificationStatus.fromString('under_review'),
        DocumentVerificationStatus.underReview,
      );
    });

    test('MembershipStatusResult helper getters', () {
      final app = MembershipApplicationEntity(
        id: 'app-1',
        applicationNumber: 'MEMAPP-1',
        applicantId: 'user-1',
        status: MembershipApplicationStatus.submitted,
        submittedAt: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final result = MembershipStatusResult(application: app, member: null);

      expect(result.hasPendingApplication, true);
      expect(result.isActiveMember, false);
      expect(result.isApproved, false);
      expect(result.isRejected, false);
      expect(result.hasNoApplication, false);
    });
  });
}
