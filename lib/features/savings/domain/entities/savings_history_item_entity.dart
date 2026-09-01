import 'package:equatable/equatable.dart';

class SavingsHistoryItemEntity extends Equatable {
  final String id;
  final String reference;
  final String itemType; // 'contribution', 'withdrawal'
  final String subType;  // 'mandatory', 'voluntary', 'withdrawal'
  final double amount;
  final bool isCredit;
  final String status;
  final String description;
  final DateTime timestamp;

  const SavingsHistoryItemEntity({
    required this.id,
    required this.reference,
    required this.itemType,
    required this.subType,
    required this.amount,
    required this.isCredit,
    required this.status,
    required this.description,
    required this.timestamp,
  });

  bool get isContribution => itemType == 'contribution';
  bool get isWithdrawal => itemType == 'withdrawal';

  @override
  List<Object?> get props => [
        id,
        reference,
        itemType,
        subType,
        amount,
        isCredit,
        status,
        description,
        timestamp,
      ];
}
