import 'package:flutter_test/flutter_test.dart';
import 'package:ufg/features/savings/data/models/savings_history_item_model.dart';
import 'package:ufg/features/savings/data/models/savings_obligation_model.dart';
import 'package:ufg/features/savings/data/models/savings_summary_model.dart';
import 'package:ufg/features/savings/data/models/withdrawal_request_model.dart';
import 'package:ufg/features/savings/domain/entities/savings_obligation_entity.dart';
import 'package:ufg/features/savings/domain/entities/withdrawal_request_entity.dart';

void main() {
  group('Savings Models JSON Deserialization Test', () {
    test('SavingsObligationModel.fromJson maps correctly', () {
      final json = {
        'id': 'ob-123',
        'period_year': 2026,
        'period_month': 9,
        'required_amount': 2000,
        'due_date': '2026-09-12',
        'paid_amount': 0,
        'late_penalty_amount': 200,
        'status': 'late',
        'total_due': 2200,
      };

      final model = SavingsObligationModel.fromJson(json);

      expect(model.id, 'ob-123');
      expect(model.periodYear, 2026);
      expect(model.periodMonth, 9);
      expect(model.requiredAmount, 2000.0);
      expect(model.latePenaltyAmount, 200.0);
      expect(model.status, SavingsObligationStatus.late);
      expect(model.totalDue, 2200.0);
    });

    test('SavingsSummaryModel.fromJson maps nested obligation correctly', () {
      final json = {
        'member_id': 'mem-uuid-1',
        'total_savings': 15000,
        'secured_savings': 4000,
        'available_to_withdraw': 11000,
        'savings_account_status': 'active',
        'current_obligation': {
          'id': 'ob-456',
          'period_year': 2026,
          'period_month': 9,
          'required_amount': 2000,
          'due_date': '2026-09-12',
          'paid_amount': 2000,
          'late_penalty_amount': 0,
          'status': 'paid',
          'total_due': 0,
        },
      };

      final model = SavingsSummaryModel.fromJson(json);

      expect(model.memberId, 'mem-uuid-1');
      expect(model.totalSavings, 15000.0);
      expect(model.securedSavings, 4000.0);
      expect(model.availableToWithdraw, 11000.0);
      expect(model.savingsAccountStatus, 'active');
      expect(model.currentObligation?.isPaid, true);
      expect(model.currentObligation?.requiredAmount, 2000.0);
    });

    test('WithdrawalRequestModel.fromJson handles statuses accurately', () {
      final json = {
        'id': 'wdr-999',
        'member_id': 'mem-uuid-1',
        'amount': 5000,
        'status': 'delayed',
        'reason': 'Liquidity delay',
        'requested_at': '2026-09-01T10:00:00Z',
      };

      final model = WithdrawalRequestModel.fromJson(json);

      expect(model.id, 'wdr-999');
      expect(model.amount, 5000.0);
      expect(model.status, WithdrawalStatus.delayed);
      expect(model.reason, 'Liquidity delay');
    });

    test('SavingsHistoryItemModel.fromJson parses contribution and withdrawal logs', () {
      final json = {
        'id': 'hist-1',
        'reference': 'TXN-20260901-ABCDEF',
        'item_type': 'contribution',
        'sub_type': 'mandatory',
        'amount': 2000,
        'is_credit': true,
        'status': 'posted',
        'description': 'Monthly savings contribution',
        'timestamp': '2026-09-01T12:00:00Z',
      };

      final model = SavingsHistoryItemModel.fromJson(json);

      expect(model.id, 'hist-1');
      expect(model.reference, 'TXN-20260901-ABCDEF');
      expect(model.isContribution, true);
      expect(model.isCredit, true);
      expect(model.amount, 2000.0);
    });
  });
}
