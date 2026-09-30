import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ufg/core/constants/app_icons.dart';
import 'package:ufg/core/constants/app_sizes.dart';
import 'package:ufg/core/notifications/notification_navigation_service.dart';
import 'package:ufg/core/widgets/empty_state.dart';
import 'package:ufg/core/widgets/error_snackbar.dart';
import 'package:ufg/core/widgets/error_state.dart';
import 'package:ufg/core/widgets/loading_indicator.dart';
import 'package:ufg/features/notifications/domain/entities/notification_entity.dart';
import 'package:ufg/features/notifications/presentation/bloc/notification_bloc.dart';
import 'package:ufg/features/notifications/presentation/bloc/notification_event.dart';
import 'package:ufg/features/notifications/presentation/bloc/notification_state.dart';
import 'package:ufg/features/notifications/presentation/widgets/notification_tile.dart';

/// Durable in-app inbox. The database is the source of truth; this page never
/// treats a push payload as authoritative data.
class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<NotificationBloc>().add(
            const LoadNotificationInboxRequested(),
          );
    });
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 240) {
      context.read<NotificationBloc>().add(
            const LoadMoreNotificationsRequested(),
          );
    }
  }

  void _onNotificationTap(NotificationEntity notification) {
    if (!notification.isRead) {
      context.read<NotificationBloc>().add(
            MarkNotificationReadRequested(notificationId: notification.id),
          );
    }

    // Navigation is idempotent: duplicate push deliveries must not double-push.
    NotificationNavigationService.instance.handleNotificationData(
      notification.data,
    );
  }

  @override
  Widget build(BuildContext context) {
    final notificationBloc = context.read<NotificationBloc>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          BlocBuilder<NotificationBloc, NotificationState>(
            buildWhen: (previous, current) =>
                previous.unreadCount != current.unreadCount,
            builder: (context, state) => IconButton(
              tooltip: 'Mark all as read',
              onPressed: state.unreadCount == 0
                  ? null
                  : () => notificationBloc.add(
                        const MarkAllNotificationsReadRequested(),
                      ),
              icon: Icon(AppIcons.check.outline),
            ),
          ),
        ],
      ),
      body: BlocConsumer<NotificationBloc, NotificationState>(
        listenWhen: (previous, current) =>
            current is NotificationInboxLoaded &&
            current.actionMessage != null &&
            current.actionMessage !=
                (previous is NotificationInboxLoaded
                    ? previous.actionMessage
                    : null),
        listener: (context, state) {
          if (state is NotificationInboxLoaded &&
              state.actionMessage != null) {
            showInfoSnackBar(context, state.actionMessage!);
          }
        },
        builder: (context, state) {
          if (state is NotificationInitial ||
              state is NotificationInboxLoading) {
            return const Center(child: LoadingIndicator());
          }

          if (state is NotificationInboxFailure) {
            return ErrorState(
              message: state.message,
              onRetry: () => context.read<NotificationBloc>().add(
                    const LoadNotificationInboxRequested(),
                  ),
            );
          }

          if (state is NotificationInboxLoaded) {
            return _buildInbox(state);
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  // @@PAGE_CONTINUE@@
  Widget _buildInbox(NotificationInboxLoaded state) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<NotificationBloc>().add(
              const LoadNotificationInboxRequested(),
            );
      },
      child: state.notifications.isEmpty
          ? ListView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const SizedBox(height: AppSizes.spacingHero),
                EmptyState(
                  title: 'No notifications yet',
                  subtitle:
                      'Transaction alerts and workflow updates will appear here.',
                  icon: AppIcons.notifications.outline,
                ),
              ],
            )
          : ListView.separated(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.spacingL,
                vertical: AppSizes.spacingM,
              ),
              itemCount: state.notifications.length + (state.isLoadingMore ? 1 : 0),
              separatorBuilder: (_, _) =>
                  const SizedBox(height: AppSizes.spacingS),
              itemBuilder: (context, index) {
                if (index >= state.notifications.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSizes.spacingM),
                    child: Center(child: LoadingIndicator()),
                  );
                }

                final notification = state.notifications[index];
                return NotificationTile(
                  notification: notification,
                  onTap: () => _onNotificationTap(notification),
                );
              },
            ),
    );
  }
}
