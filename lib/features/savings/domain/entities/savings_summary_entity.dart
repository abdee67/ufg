import 'package:equatable/equatable.dart';
import 'package:ufg/features/savings/domain/entities/savings_obligation_entity.dart';

class SavingsSummaryEntity extends Equatable {
  final String memberId;
  final double totalSavings;
  final double securedSavings;
  final double availableToWithdraw;
  final String savingsAccountStatus;
  final SavingsObligationEntity? currentObligation;

  const SavingsSummaryEntity({
    required this.memberId,
    required this.totalSavings,
    required this.securedSavings,
    required this.availableToWithdraw,
    required this.savingsAccountStatus,
    this.currentObligation,
  });

  bool get hasActiveObligation => currentObligation != null;
  bool get isCurrentObligationLate => currentObligation?.isLate ?? false;
  bool get isCurrentObligationPaid => currentObligation?.isPaid ?? false;

  @override
  List<Object?> get props => [
        memberId,
        totalSavings,
        securedSavings,
        availableToWithdraw,
        savingsAccountStatus,
        currentObligation,
      ];
}
