import 'package:ufg/features/loans/domain/entities/loan_eligibility_result_entity.dart';

class LoanEligibilityResultModel extends LoanEligibilityResultEntity {
  const LoanEligibilityResultModel({
    required super.isEligible,
    super.requiresGuarantor,
    super.message,
    super.checks,
    super.manualReviews,
  });

  factory LoanEligibilityResultModel.fromJson(Map<String, dynamic> json) {
    final isEligible = json['eligible'] as bool? ?? (json['is_eligible'] as bool? ?? false);
    final requiresGuarantor = json['requires_guarantor'] as bool? ?? false;
    final message = json['message'] as String?;

    final checks = <EligibilityCheckItem>[];
    if (json['checks'] != null && json['checks'] is List) {
      for (final c in json['checks'] as List) {
        if (c is Map) {
          checks.add(
            EligibilityCheckItem(
              code: c['check_code'] as String? ?? '',
              title: c['title'] as String? ?? c['check_code'] as String? ?? '',
              passed: c['result'] as bool? ?? false,
              details: c['reason'] as String? ?? c['details'] as String? ?? '',
            ),
          );
        }
      }
    }

    final manualReviews = <String>[];
    if (json['manual_reviews'] != null && json['manual_reviews'] is List) {
      for (final r in json['manual_reviews'] as List) {
        manualReviews.add(r.toString());
      }
    }

    return LoanEligibilityResultModel(
      isEligible: isEligible,
      requiresGuarantor: requiresGuarantor,
      message: message,
      checks: checks,
      manualReviews: manualReviews,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'eligible': isEligible,
      'requires_guarantor': requiresGuarantor,
      'message': message,
      'checks': checks
          .map((c) => {
                'check_code': c.code,
                'title': c.title,
                'result': c.passed,
                'reason': c.details,
              })
          .toList(),
      'manual_reviews': manualReviews,
    };
  }
}
