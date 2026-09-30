import 'package:dartz/dartz.dart';
import 'package:ufg/core/errors/failures.dart';
import 'package:ufg/features/notifications/domain/repositories/notification_repository.dart';

class DeactivateNotificationDevice {
  final NotificationRepository repository;

  DeactivateNotificationDevice(this.repository);

  Future<Either<Failures, bool>> call(String fcmToken) async {
    return await repository.deactivateNotificationDevice(fcmToken);
  }
}
