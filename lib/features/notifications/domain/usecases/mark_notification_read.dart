import 'package:dartz/dartz.dart';
import 'package:ufg/core/errors/failures.dart';
import 'package:ufg/features/notifications/domain/repositories/notification_repository.dart';

class MarkNotificationRead {
  final NotificationRepository repository;

  MarkNotificationRead(this.repository);

  Future<Either<Failures, bool>> call(String notificationId) async {
    return await repository.markNotificationRead(notificationId);
  }
}
