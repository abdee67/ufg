import 'package:ufg/features/loans/domain/entities/guarantor_candidate_entity.dart';

class GuarantorCandidateModel extends GuarantorCandidateEntity {
  const GuarantorCandidateModel({
    required super.memberId,
    required super.memberNumber,
    required super.displayName,
  });

  factory GuarantorCandidateModel.fromJson(Map<String, dynamic> json) {
    return GuarantorCandidateModel(
      memberId: json['member_id'] as String? ?? '',
      memberNumber: json['member_number'] as String? ?? '',
      displayName: json['display_name'] as String? ?? '',
    );
  }
}
