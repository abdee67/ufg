import 'package:equatable/equatable.dart';

abstract class NotificationEvent extends Equatable {
  const NotificationEvent();

  @override
  List<Object?> get props => [];
}

/// Loads the first page of the durable inbox (and the unread count).
class LoadNotificationInboxRequested extends NotificationEvent {
  const LoadNotificationInboxRequested();
}

/// Cursor-based pagination using `(created_at, id)`.
class LoadMoreNotificationsRequested extends NotificationEvent {
  const LoadMoreNotificationsRequested();
}

/// Refreshes only the unread badge count (used by the home shell).
class LoadUnreadNotificationCountRequested extends NotificationEvent {
  const LoadUnreadNotificationCountRequested();
}

class MarkNotificationReadRequested extends NotificationEvent {
  final String notificationId;

  const MarkNotificationReadRequested({required this.notificationId});

  @override
  List<Object?> get props => [notificationId];
}

class MarkAllNotificationsReadRequested extends NotificationEvent {
  const MarkAllNotificationsReadRequested();
}

/// A Realtime insert/update for the authenticated profile arrived.
class NotificationRealtimeReceived extends NotificationEvent {
  const NotificationRealtimeReceived();
}

/// The Realtime channel (re)connected: refetch to close any gap caused by the
/// connection loss.
class NotificationStreamResubscribed extends NotificationEvent {
  const NotificationStreamResubscribed();
}

/// Clears inbox state and drops the Realtime subscription (logout).
class ResetNotificationsRequested extends NotificationEvent {
  const ResetNotificationsRequested();
}
