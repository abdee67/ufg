import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ufg/core/errors/exceptions/auth_exceptions.dart';
import 'package:ufg/core/errors/failures.dart';
import 'package:ufg/features/notifications/data/datasources/notification_remote_data_source.dart';
import 'package:ufg/features/notifications/domain/entities/notification_entity.dart';
import 'package:ufg/features/notifications/domain/repositories/notification_repository.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationRemoteDataSource remoteDataSource;

  NotificationRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failures, List<NotificationEntity>>> getNotifications({
    int limit = 30,
    DateTime? beforeCreatedAt,
    String? beforeId,
  }) async {
    try {
      final list = await remoteDataSource.getNotifications(
        limit: limit,
        beforeCreatedAt: beforeCreatedAt,
        beforeId: beforeId,
      );
      return Right(list);
    } on AuthExceptions catch (e) {
      return Left(Failures(message: e.message));
    } on PostgrestException catch (e) {
      return Left(Failures(message: e.message));
    } catch (e) {
      return Left(Failures(message: e.toString()));
    }
  }

  @override
  Future<Either<Failures, int>> getUnreadCount() async {
    try {
      final count = await remoteDataSource.getUnreadCount();
      return Right(count);
    } on AuthExceptions catch (e) {
      return Left(Failures(message: e.message));
    } on PostgrestException catch (e) {
      return Left(Failures(message: e.message));
    } catch (e) {
      return Left(Failures(message: e.toString()));
    }
  }

  @override
  Future<Either<Failures, bool>> markNotificationRead(
    String notificationId,
  ) async {
    try {
      final updated = await remoteDataSource.markNotificationRead(notificationId);
      return Right(updated);
    } on AuthExceptions catch (e) {
      return Left(Failures(message: e.message));
    } on PostgrestException catch (e) {
      return Left(Failures(message: e.message));
    } catch (e) {
      return Left(Failures(message: e.toString()));
    }
  }

  @override
  Future<Either<Failures, int>> markAllNotificationsRead() async {
    try {
      final updated = await remoteDataSource.markAllNotificationsRead();
      return Right(updated);
    } on AuthExceptions catch (e) {
      return Left(Failures(message: e.message));
    } on PostgrestException catch (e) {
      return Left(Failures(message: e.message));
    } catch (e) {
      return Left(Failures(message: e.toString()));
    }
  }

  @override
  Future<Either<Failures, String>> registerNotificationDevice({
    required String fcmToken,
    required String platform,
    String appType = 'member',
    String? deviceIdentifier,
    String? appVersion,
    String? appBuild,
    String? locale,
    String? timezone,
  }) async {
    try {
      final deviceId = await remoteDataSource.registerNotificationDevice(
        fcmToken: fcmToken,
        platform: platform,
        appType: appType,
        deviceIdentifier: deviceIdentifier,
        appVersion: appVersion,
        appBuild: appBuild,
        locale: locale,
        timezone: timezone,
      );
      return Right(deviceId);
    } on AuthExceptions catch (e) {
      return Left(Failures(message: e.message));
    } on PostgrestException catch (e) {
      return Left(Failures(message: e.message));
    } catch (e) {
      return Left(Failures(message: e.toString()));
    }
  }

  @override
  Future<Either<Failures, bool>> deactivateNotificationDevice(
    String fcmToken,
  ) async {
    try {
      final deactivated =
          await remoteDataSource.deactivateNotificationDevice(fcmToken);
      return Right(deactivated);
    } on AuthExceptions catch (e) {
      return Left(Failures(message: e.message));
    } on PostgrestException catch (e) {
      return Left(Failures(message: e.message));
    } catch (e) {
      return Left(Failures(message: e.toString()));
    }
  }
}
