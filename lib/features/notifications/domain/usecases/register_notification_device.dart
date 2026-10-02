import 'package:dartz/dartz.dart';
import 'package:ufg/core/errors/failures.dart';
import 'package:ufg/features/notifications/domain/repositories/notification_repository.dart';

class RegisterNotificationDevice {
  final NotificationRepository repository;

  RegisterNotificationDevice(this.repository);

  Future<Either<Failures, String>> call({
    required String fcmToken,
    required String platform,
    String appType = 'member',
    String? deviceIdentifier,
    String? appVersion,
    String? appBuild,
    String? locale,
    String? timezone,
  }) async {
    return await repository.registerNotificationDevice(
      fcmToken: fcmToken,
      platform: platform,
      appType: appType,
      deviceIdentifier: deviceIdentifier,
      appVersion: appVersion,
      appBuild: appBuild,
      locale: locale,
      timezone: timezone,
    );
  }
}
