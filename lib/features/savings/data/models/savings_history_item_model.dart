import 'package:ufg/features/savings/domain/entities/savings_history_item_entity.dart';

class SavingsHistoryItemModel extends SavingsHistoryItemEntity {
  const SavingsHistoryItemModel({
    required super.id,
    required super.reference,
    required super.itemType,
    required super.subType,
    required super.amount,
    required super.isCredit,
    required super.status,
    required super.description,
    required super.timestamp,
  });

  factory SavingsHistoryItemModel.fromJson(Map<String, dynamic> json) {
    return SavingsHistoryItemModel(
      id: json['id'] as String? ?? '',
      reference: json['reference'] as String? ?? '',
      itemType: json['item_type'] as String? ?? 'contribution',
      subType: json['sub_type'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      isCredit: json['is_credit'] as bool? ?? true,
      status: json['status'] as String? ?? 'posted',
      description: json['description'] as String? ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
