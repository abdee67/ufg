import 'package:equatable/equatable.dart';

class SavingsContributionEntity extends Equatable {
  final String id;
  final String memberId;
  final String savingsAccountId;
  final String? obligationId;
  final double amount;
  final String? paymentId;
  final String? transactionId;
  final String contributionType; // 'mandatory', 'voluntary', 'adjustment'
  final DateTime createdAt;

  const SavingsContributionEntity({
    required this.id,
    required this.memberId,
    required this.savingsAccountId,
    this.obligationId,
    required this.amount,
    this.paymentId,
    this.transactionId,
    required this.contributionType,
    required this.createdAt,
  });

  bool get isMandatory => contributionType.toLowerCase() == 'mandatory';
  bool get isVoluntary => contributionType.toLowerCase() == 'voluntary';

  @override
  List<Object?> get props => [
        id,
        memberId,
        savingsAccountId,
        obligationId,
        amount,
        paymentId,
        transactionId,
        contributionType,
        createdAt,
      ];
}
