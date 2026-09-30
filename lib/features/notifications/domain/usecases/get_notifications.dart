import 'package:dartz/dartz.dart';
import 'package:ufg/core/errors/failures.dart';
import 'package:ufg/features/notifications/domain/entities/notification_entity.dart';
import 'package:ufg/features/notifications/domain/repositories/notification_repository.dart';

class GetNotifications {
  final NotificationRepository repository;

  GetNotifications(this.repository);

  Future<Either<Failures, List<NotificationEntity>>> call({
    int limit = 30,
    DateTime? beforeCreatedAt,
    String? beforeId,
  }) async {
    return await repository.getNotifications(
      limit: limit,
      beforeCreatedAt: beforeCreatedAt,
      beforeId: beforeId,
    );
  }
}
