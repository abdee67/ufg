import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:ufg/core/constants/app_routes.dart';

/// Converts a notification payload into exactly one in-app route.
///
/// Duplicate push deliveries (the FCM provider boundary is at-least-once) can
/// produce duplicate taps; navigation here is intentionally idempotent and
/// never throws into a listener.
class NotificationNavigationService {
  NotificationNavigationService._();

  static final NotificationNavigationService instance =
      NotificationNavigationService._();

  GoRouter? _router;
  Map<String, dynamic>? _pendingPayload;

  bool get isReady => _router != null;

  /// Called by `main.dart` once the router exists. The router is built after
  /// the onboarding/session checks, so a cold-start notification tap can
  /// arrive before this point: the payload is buffered until then.
  void attachRouter(GoRouter router) {
    _router = router;

    final pending = _pendingPayload;
    if (pending != null) {
      _pendingPayload = null;
      Future.microtask(() => handleNotificationData(pending));
    }
  }

  void detachRouter() {
    _router = null;
  }

  void handleNotificationData(Map<String, dynamic>? data) {
    if (data == null || data.isEmpty) return;

    final route = routeFor(data);
    if (route == null) return;

    final router = _router;
    if (router == null) {
      _pendingPayload = data;
      return;
    }

    try {
      router.push(route);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Notification navigation failed for $route: $e');
      }
    }
  }

  /// Maps backend payload fields to a member-app route.
  ///
  /// Payload values are navigation hints only; the destination screen always
  /// reloads authoritative data from Supabase.
  String? routeFor(Map<String, dynamic> data) {
    final type = (data['type'] as String?) ?? '';
    final targetType = (data['target_type'] as String?) ?? '';
    final transactionType = (data['transaction_type'] as String?) ?? '';

    switch (targetType) {
      case 'transaction':
        if (transactionType.startsWith('loan_')) {
          return AppRoutes.loans;
        }
        return AppRoutes.savingsHistory;
      case 'payment':
        if ((data['purpose_type'] as String?)?.contains('loan') ?? false) {
          return AppRoutes.loans;
        }
        return AppRoutes.savingsHistory;
      case 'loan_repayment_submission':
        return AppRoutes.loans;
      case 'withdrawal':
      case 'savings_withdrawal':
        return AppRoutes.savingsWithdrawals;
      case 'loan':
      case 'loan_application':
        return AppRoutes.loans;
      case 'membership_application':
        return AppRoutes.membershipStatus;
      case 'expense':
        return null;
    }

    if (type.startsWith('transaction.')) return AppRoutes.savingsHistory;
    if (type.startsWith('savings.')) return AppRoutes.savings;
    if (type.startsWith('loan.')) return AppRoutes.loans;
    if (type.startsWith('payment.')) return AppRoutes.savingsHistory;
    if (type.startsWith('membership.')) return AppRoutes.membershipStatus;
    return null;
  }
}
