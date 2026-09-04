import 'package:equatable/equatable.dart';

enum BorrowerType { member, outsider }

class LoanProductEntity extends Equatable {
  final String id;
  final String code;
  final String name;
  final BorrowerType borrowerType;
  final double serviceChargeRate; // e.g. 0.10 for 10%, 0.15 for 15%
  final double maxAmount; // e.g. 20000.0 ETB
  final int termMonths; // e.g. 3 months
  final bool active;

  const LoanProductEntity({
    required this.id,
    required this.code,
    required this.name,
    required this.borrowerType,
    required this.serviceChargeRate,
    required this.maxAmount,
    required this.termMonths,
    required this.active,
  });

  bool get isMemberLoan => borrowerType == BorrowerType.member;
  bool get isOutsiderLoan => borrowerType == BorrowerType.outsider;

  /// Calculates the one-time service charge amount for a given principal.
  double calculateServiceCharge(double principal) {
    return (principal * serviceChargeRate);
  }

  /// Calculates total repayment (Principal + One-Time Service Charge).
  double calculateTotalRepayment(double principal) {
    return principal + calculateServiceCharge(principal);
  }

  /// Calculates monthly installment amount.
  double calculateMonthlyInstallment(double principal) {
    if (termMonths <= 0) return 0.0;
    return calculateTotalRepayment(principal) / termMonths;
  }

  @override
  List<Object?> get props => [
        id,
        code,
        name,
        borrowerType,
        serviceChargeRate,
        maxAmount,
        termMonths,
        active,
      ];
}
