import 'package:ufg/features/savings/data/models/savings_obligation_model.dart';
import 'package:ufg/features/savings/domain/entities/savings_summary_entity.dart';

class SavingsSummaryModel extends SavingsSummaryEntity {
  const SavingsSummaryModel({
    required super.memberId,
    required super.totalSavings,
    required super.securedSavings,
    required super.availableToWithdraw,
    required super.savingsAccountStatus,
    super.currentObligation,
  });

  factory SavingsSummaryModel.fromJson(Map<String, dynamic> json) {
    SavingsObligationModel? obligation;
    if (json['current_obligation'] != null && json['current_obligation'] is Map) {
      obligation = SavingsObligationModel.fromJson(
        Map<String, dynamic>.from(json['current_obligation'] as Map),
      );
    }

    return SavingsSummaryModel(
      memberId: json['member_id'] as String? ?? '',
      totalSavings: (json['total_savings'] as num?)?.toDouble() ?? 0.0,
      securedSavings: (json['secured_savings'] as num?)?.toDouble() ?? 0.0,
      availableToWithdraw: (json['available_to_withdraw'] as num?)?.toDouble() ?? 0.0,
      savingsAccountStatus: json['savings_account_status'] as String? ?? 'active',
      currentObligation: obligation,
    );
  }
}
