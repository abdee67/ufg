import 'package:dartz/dartz.dart';
import 'package:ufg/core/errors/failures.dart';
import 'package:ufg/features/notifications/domain/repositories/notification_repository.dart';

class MarkAllNotificationsRead {
  final NotificationRepository repository;

  MarkAllNotificationsRead(this.repository);

  Future<Either<Failures, int>> call() async {
    return await repository.markAllNotificationsRead();
  }
}
