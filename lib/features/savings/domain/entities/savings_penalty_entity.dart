import 'package:equatable/equatable.dart';

class SavingsPenaltyEntity extends Equatable {
  final String id;
  final String obligationId;
  final double rate;
  final double amount;
  final String? transactionId;
  final DateTime chargedAt;

  const SavingsPenaltyEntity({
    required this.id,
    required this.obligationId,
    required this.rate,
    required this.amount,
    this.transactionId,
    required this.chargedAt,
  });

  @override
  List<Object?> get props => [id, obligationId, rate, amount, transactionId, chargedAt];
}
