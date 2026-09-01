import 'package:flutter_test/flutter_test.dart';
import 'package:ufg/features/savings/domain/entities/savings_obligation_entity.dart';
import 'package:ufg/features/savings/domain/entities/savings_summary_entity.dart';
import 'package:ufg/features/savings/domain/entities/withdrawal_request_entity.dart';

void main() {
  group('Savings Entities Test', () {
    test('SavingsObligationEntity calculates totalDue and status flags accurately', () {
      final obligation = SavingsObligationEntity(
        id: 'ob-1',
        periodYear: 2026,
        periodMonth: 9,
        requiredAmount: 2000.0,
        dueDate: DateTime(2026, 9, 12),
        paidAmount: 0.0,
        latePenaltyAmount: 200.0,
        status: SavingsObligationStatus.late,
        totalDue: 2200.0,
      );

      expect(obligation.isLate, true);
      expect(obligation.isPaid, false);
      expect(obligation.hasPenalty, true);
      expect(obligation.remainingRequired, 2000.0);
      expect(obligation.periodLabel, 'September 2026');
      expect(obligation.totalDue, 2200.0);
    });

    test('SavingsSummaryEntity correctly computes available and secured balance metrics', () {
      final summary = SavingsSummaryEntity(
        memberId: 'mem-1',
        totalSavings: 12000.0,
        securedSavings: 5000.0,
        availableToWithdraw: 7000.0,
        savingsAccountStatus: 'active',
        currentObligation: SavingsObligationEntity(
          id: 'ob-1',
          periodYear: 2026,
          periodMonth: 9,
          requiredAmount: 2000.0,
          dueDate: DateTime(2026, 9, 12),
          paidAmount: 2000.0,
          latePenaltyAmount: 0.0,
          status: SavingsObligationStatus.paid,
          totalDue: 0.0,
        ),
      );

      expect(summary.totalSavings, 12000.0);
      expect(summary.availableToWithdraw, 7000.0);
      expect(summary.securedSavings, 5000.0);
      expect(summary.hasActiveObligation, true);
      expect(summary.isCurrentObligationPaid, true);
      expect(summary.isCurrentObligationLate, false);
    });

    test('WithdrawalRequestEntity status helpers work as expected', () {
      final request = WithdrawalRequestEntity(
        id: 'wdr-1',
        memberId: 'mem-1',
        amount: 3000.0,
        status: WithdrawalStatus.delayed,
        reason: 'Temporary liquidity management',
        requestedAt: DateTime.now(),
      );

      expect(request.isDelayed, true);
      expect(request.isPending, false);
      expect(request.isApproved, false);
      expect(request.amount, 3000.0);
      expect(request.reason, 'Temporary liquidity management');
    });
  });
}
