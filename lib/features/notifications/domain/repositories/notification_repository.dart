import 'package:dartz/dartz.dart';
import 'package:ufg/core/errors/failures.dart';
import 'package:ufg/features/notifications/domain/entities/notification_entity.dart';

abstract class NotificationRepository {
  /// Cursor-paginated inbox query for the authenticated profile.
  Future<Either<Failures, List<NotificationEntity>>> getNotifications({
    int limit = 30,
    DateTime? beforeCreatedAt,
    String? beforeId,
  });

  Future<Either<Failures, int>> getUnreadCount();

  Future<Either<Failures, bool>> markNotificationRead(String notificationId);

  Future<Either<Failures, int>> markAllNotificationsRead();

  Future<Either<Failures, String>> registerNotificationDevice({
    required String fcmToken,
    required String platform,
    String appType = 'member',
    String? deviceIdentifier,
    String? appVersion,
    String? appBuild,
    String? locale,
    String? timezone,
  });

  Future<Either<Failures, bool>> deactivateNotificationDevice(String fcmToken);
}
