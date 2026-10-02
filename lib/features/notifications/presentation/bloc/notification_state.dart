import 'package:equatable/equatable.dart';
import 'package:ufg/features/notifications/domain/entities/notification_entity.dart';

abstract class NotificationState extends Equatable {
  const NotificationState();

  /// Authoritative unread count from `get_my_unread_notification_count_v1()`.
  int get unreadCount => 0;

  List<NotificationEntity> get notifications => const [];

  @override
  List<Object?> get props => [];
}

class NotificationInitial extends NotificationState {
  const NotificationInitial();
}

class NotificationInboxLoading extends NotificationState {
  @override
  final int unreadCount;

  const NotificationInboxLoading({this.unreadCount = 0});

  @override
  List<Object?> get props => [unreadCount];
}

class NotificationInboxLoaded extends NotificationState {
  @override
  final List<NotificationEntity> notifications;

  @override
  final int unreadCount;

  final bool hasMore;
  final bool isLoadingMore;

  /// Transient feedback for the page (snackbar). Not persisted.
  final String? actionMessage;

  const NotificationInboxLoaded({
    required this.notifications,
    required this.unreadCount,
    this.hasMore = false,
    this.isLoadingMore = false,
    this.actionMessage,
  });

  NotificationInboxLoaded copyWith({
    List<NotificationEntity>? notifications,
    int? unreadCount,
    bool? hasMore,
    bool? isLoadingMore,
    String? actionMessage,
    bool clearActionMessage = false,
  }) {
    return NotificationInboxLoaded(
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      actionMessage: clearActionMessage ? null : (actionMessage ?? this.actionMessage),
    );
  }

  @override
  List<Object?> get props => [
        notifications,
        unreadCount,
        hasMore,
        isLoadingMore,
        actionMessage,
      ];
}

class NotificationInboxFailure extends NotificationState {
  final String message;

  @override
  final int unreadCount;

  const NotificationInboxFailure({required this.message, this.unreadCount = 0});

  @override
  List<Object?> get props => [message, unreadCount];
}
