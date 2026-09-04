import 'package:equatable/equatable.dart';

class EligibilityCheckItem extends Equatable {
  final String code;
  final String title;
  final bool passed;
  final String details;

  const EligibilityCheckItem({
    required this.code,
    required this.title,
    required this.passed,
    required this.details,
  });

  @override
  List<Object?> get props => [code, title, passed, details];
}

class LoanEligibilityResultEntity extends Equatable {
  final bool isEligible;
  final bool requiresGuarantor;
  final String? message;
  final List<EligibilityCheckItem> checks;
  final List<String> manualReviews;

  const LoanEligibilityResultEntity({
    required this.isEligible,
    this.requiresGuarantor = false,
    this.message,
    this.checks = const [],
    this.manualReviews = const [],
  });

  @override
  List<Object?> get props => [
        isEligible,
        requiresGuarantor,
        message,
        checks,
        manualReviews,
      ];
}
