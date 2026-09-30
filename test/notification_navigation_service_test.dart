import 'package:flutter_test/flutter_test.dart';
import 'package:ufg/core/constants/app_routes.dart';
import 'package:ufg/core/notifications/notification_navigation_service.dart';

void main() {
  final service = NotificationNavigationService.instance;

  group('NotificationNavigationService.routeFor', () {
    test('routes savings transactions to the savings history page', () {
      expect(
        service.routeFor({
          'type': 'transaction.posted',
          'target_type': 'transaction',
          'transaction_type': 'savings_contribution',
        }),
        AppRoutes.savingsHistory,
      );

      expect(
        service.routeFor({
          'type': 'transaction.reversed',
          'target_type': 'transaction',
          'transaction_type': 'savings_late_penalty',
        }),
        AppRoutes.savingsHistory,
      );
    });

    test('routes loan transactions to the loans page', () {
      expect(
        service.routeFor({
          'type': 'transaction.posted',
          'target_type': 'transaction',
          'transaction_type': 'loan_repayment',
        }),
        AppRoutes.loans,
      );

      expect(
        service.routeFor({
          'type': 'loan.repayment_submitted',
          'target_type': 'loan_repayment_submission',
        }),
        AppRoutes.loans,
      );
    });

    test('routes withdrawals to the withdrawal history page', () {
      expect(
        service.routeFor({
          'type': 'savings.withdrawal_requested',
          'target_type': 'withdrawal',
        }),
        AppRoutes.savingsWithdrawals,
      );

      expect(
        service.routeFor({
          'type': 'savings.withdrawal_approved',
          'target_type': 'savings_withdrawal',
        }),
        AppRoutes.savingsWithdrawals,
      );
    });

    test('routes loan and guarantor events to the loans page', () {
      expect(
        service.routeFor({
          'type': 'loan.application_submitted',
          'target_type': 'loan_application',
        }),
        AppRoutes.loans,
      );

      expect(
        service.routeFor({
          'type': 'loan.guarantor_required',
          'target_type': 'loan',
        }),
        AppRoutes.loans,
      );

      expect(
        service.routeFor({
          'type': 'loan.serious_default',
          'target_type': 'loan',
        }),
        AppRoutes.loans,
      );
    });

    test('routes membership decisions to the membership status page', () {
      expect(
        service.routeFor({
          'type': 'membership.approved',
          'target_type': 'membership_application',
        }),
        AppRoutes.membershipStatus,
      );
    });

    test('falls back to the notification family prefix', () {
      expect(
        service.routeFor({'type': 'payment.rejected'}),
        AppRoutes.savingsHistory,
      );

      expect(
        service.routeFor({'type': 'savings.withdrawal_delayed'}),
        AppRoutes.savings,
      );

      expect(
        service.routeFor({'type': 'membership.application_submitted'}),
        AppRoutes.membershipStatus,
      );
    });

    test('returns null for admin-only and unknown payloads', () {
      expect(
        service.routeFor({
          'type': 'expense.submitted',
          'target_type': 'expense',
        }),
        isNull,
      );

      expect(service.routeFor({'type': 'unknown.event'}), isNull);
      expect(service.routeFor(<String, dynamic>{}), isNull);
    });

    test('ignores empty or unknown payloads without throwing', () {
      expect(() => service.handleNotificationData(null), returnsNormally);
      expect(
        () => service.handleNotificationData(<String, dynamic>{}),
        returnsNormally,
      );
      expect(
        () => service.handleNotificationData({'type': 'expense.submitted'}),
        returnsNormally,
      );
    });
  });
}
