import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ufg/core/config/supabase_config.dart';
import 'package:ufg/features/notifications/domain/usecases/get_notifications.dart';
import 'package:ufg/features/notifications/domain/usecases/get_unread_notification_count.dart';
import 'package:ufg/features/notifications/domain/usecases/mark_all_notifications_read.dart';
import 'package:ufg/features/notifications/domain/usecases/mark_notification_read.dart';
import 'package:ufg/features/notifications/presentation/bloc/notification_event.dart';
import 'package:ufg/features/notifications/presentation/bloc/notification_state.dart';

/// Inbox + unread badge state for the authenticated profile.
///
/// Registered as a lazy singleton so the home badge and the inbox page share
/// one Realtime subscription and one authoritative unread count.
class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  static const int pageSize = 30;
  static const Duration _realtimeDebounce = Duration(milliseconds: 800);

  final GetNotifications getNotifications;
  final GetUnreadNotificationCount getUnreadNotificationCount;
  final MarkNotificationRead markNotificationRead;
  final MarkAllNotificationsRead markAllNotificationsRead;

  RealtimeChannel? _channel;
  String? _subscribedProfileId;
  Timer? _realtimeDebounceTimer;
  bool _subscribedOnce = false;

  NotificationBloc({
    required this.getNotifications,
    required this.getUnreadNotificationCount,
    required this.markNotificationRead,
    required this.markAllNotificationsRead,
  }) : super(const NotificationInitial()) {
    on<LoadNotificationInboxRequested>(_onLoadInbox);
    on<LoadMoreNotificationsRequested>(_onLoadMore);
    on<LoadUnreadNotificationCountRequested>(_onLoadUnreadCount);
    on<MarkNotificationReadRequested>(_onMarkRead);
    on<MarkAllNotificationsReadRequested>(_onMarkAllRead);
    on<NotificationRealtimeReceived>(_onRealtimeReceived);
    on<NotificationStreamResubscribed>(_onResubscribed);
    on<ResetNotificationsRequested>(_onReset);
  }

  @override
  Future<void> close() {
    _realtimeDebounceTimer?.cancel();
    _teardownRealtime();
    return super.close();
  }

  Future<void> _onLoadInbox(
    LoadNotificationInboxRequested event,
    Emitter<NotificationState> emit,
  ) async {
    _ensureRealtimeSubscription();

    if (state is! NotificationInboxLoaded) {
      emit(NotificationInboxLoading(unreadCount: state.unreadCount));
    }

    final listResult = await getNotifications(limit: pageSize);
    final countResult = await getUnreadNotificationCount();

    final unreadCount = countResult.fold(
      (_) => state.unreadCount,
      (count) => count,
    );

    listResult.fold(
      (failure) => emit(
        NotificationInboxFailure(
          message: failure.message,
          unreadCount: unreadCount,
        ),
      ),
      (items) => emit(
        NotificationInboxLoaded(
          notifications: items,
          unreadCount: unreadCount,
          hasMore: items.length >= pageSize,
        ),
      ),
    );
  }

  Future<void> _onLoadMore(
    LoadMoreNotificationsRequested event,
    Emitter<NotificationState> emit,
  ) async {
    final current = state;
    if (current is! NotificationInboxLoaded) return;
    if (!current.hasMore || current.isLoadingMore) return;

    emit(current.copyWith(isLoadingMore: true, clearActionMessage: true));

    final last = current.notifications.isNotEmpty
        ? current.notifications.last
        : null;

    final result = await getNotifications(
      limit: pageSize,
      beforeCreatedAt: last?.createdAt,
      beforeId: last?.id,
    );

    result.fold(
      (failure) => emit(
        current.copyWith(
          isLoadingMore: false,
          actionMessage: failure.message,
        ),
      ),
      (items) {
        final existingIds = current.notifications.map((n) => n.id).toSet();
        final merged = [
          ...current.notifications,
          ...items.where((n) => !existingIds.contains(n.id)),
        ];

        emit(
          current.copyWith(
            notifications: merged,
            isLoadingMore: false,
            hasMore: items.length >= pageSize,
          ),
        );
      },
    );
  }

  // @@BLOC_CONTINUE@@
  Future<void> _onLoadUnreadCount(
    LoadUnreadNotificationCountRequested event,
    Emitter<NotificationState> emit,
  ) async {
    _ensureRealtimeSubscription();

    final result = await getUnreadNotificationCount();
    final count = result.fold((_) => null, (value) => value);

    // The badge is best-effort: a failed count must not clobber a loaded inbox.
    if (count == null) return;

    final current = state;
    if (current is NotificationInboxLoaded) {
      emit(current.copyWith(unreadCount: count));
    } else if (current is NotificationInboxLoading) {
      emit(NotificationInboxLoading(unreadCount: count));
    } else {
      emit(NotificationInboxLoaded(
        notifications: current.notifications,
        unreadCount: count,
      ));
    }
  }

  Future<void> _onMarkRead(
    MarkNotificationReadRequested event,
    Emitter<NotificationState> emit,
  ) async {
    final current = state;
    final result = await markNotificationRead(event.notificationId);

    final failureMessage = result.fold((failure) => failure.message, (_) => null);
    if (failureMessage != null) {
      if (current is NotificationInboxLoaded) {
        emit(current.copyWith(actionMessage: failureMessage));
      }
      return;
    }

    if (current is NotificationInboxLoaded) {
      final now = DateTime.now();
      final updated = current.notifications
          .map((n) => n.id == event.notificationId && !n.isRead
              ? n.copyWith(readAt: now)
              : n)
          .toList();

      emit(current.copyWith(
        notifications: updated,
        unreadCount: current.unreadCount > 0 ? current.unreadCount - 1 : 0,
      ));
    }

    // Postgres remains authoritative for the badge.
    add(const LoadUnreadNotificationCountRequested());
  }

  Future<void> _onMarkAllRead(
    MarkAllNotificationsReadRequested event,
    Emitter<NotificationState> emit,
  ) async {
    final current = state;
    final result = await markAllNotificationsRead();

    result.fold(
      (failure) {
        if (current is NotificationInboxLoaded) {
          emit(current.copyWith(actionMessage: failure.message));
        }
      },
      (updated) {
        if (current is NotificationInboxLoaded) {
          final now = DateTime.now();
          final list = current.notifications
              .map((n) => n.isRead ? n : n.copyWith(readAt: now))
              .toList();

          emit(current.copyWith(
            notifications: list,
            unreadCount: 0,
            actionMessage: updated > 0
                ? '$updated notification(s) marked as read.'
                : 'Nothing to mark as read.',
          ));
        } else {
          add(const LoadUnreadNotificationCountRequested());
        }
      },
    );
  }

  void _onRealtimeReceived(
    NotificationRealtimeReceived event,
    Emitter<NotificationState> emit,
  ) {
    // Coalesce bursts (a single financial event can create one row per device).
    _realtimeDebounceTimer?.cancel();
    _realtimeDebounceTimer = Timer(_realtimeDebounce, () {
      add(const LoadNotificationInboxRequested());
    });
  }

  void _onResubscribed(
    NotificationStreamResubscribed event,
    Emitter<NotificationState> emit,
  ) {
    // Realtime missed nothing authoritative, but a reconnect can hide rows
    // created while offline, so refetch.
    add(const LoadNotificationInboxRequested());
  }

  Future<void> _onReset(
    ResetNotificationsRequested event,
    Emitter<NotificationState> emit,
  ) async {
    _realtimeDebounceTimer?.cancel();
    _teardownRealtime();
    emit(const NotificationInitial());
  }

  void _ensureRealtimeSubscription() {
    final client = SupabaseConfig.client;
    final userId = client.auth.currentUser?.id;
    if (userId == null) return;
    if (_channel != null && _subscribedProfileId == userId) return;

    _teardownRealtime();
    _subscribedProfileId = userId;

    final channel = client.channel('notifications:$userId');

    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'recipient_profile_id',
            value: userId,
          ),
          callback: (_) => add(const NotificationRealtimeReceived()),
        )
        .subscribe((status, error) {
      if (status == RealtimeSubscribeStatus.subscribed) {
        if (_subscribedOnce) {
          add(const NotificationStreamResubscribed());
        } else {
          _subscribedOnce = true;
        }
      } else if (error != null && kDebugMode) {
        debugPrint('Notification realtime error: $error');
      }
    });

    _channel = channel;
  }

  void _teardownRealtime() {
    final channel = _channel;
    _channel = null;
    _subscribedProfileId = null;
    _subscribedOnce = false;

    if (channel != null) {
      SupabaseConfig.client.removeChannel(channel);
    }
  }
}
