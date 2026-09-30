import 'package:ufg/features/notifications/domain/entities/notification_entity.dart';

class NotificationModel extends NotificationEntity {
  const NotificationModel({
    required super.id,
    required super.recipientProfileId,
    required super.category,
    required super.type,
    required super.title,
    required super.body,
    required super.priority,
    required super.data,
    super.sourceType,
    super.sourceId,
    super.dedupeKey,
    super.readAt,
    required super.createdAt,
    super.expiresAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      recipientProfileId: json['recipient_profile_id'] as String? ?? '',
      category: json['category'] as String? ?? 'system',
      type: json['type'] as String? ?? 'unknown',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      priority: json['priority'] as String? ?? 'normal',
      data: json['data'] is Map
          ? Map<String, dynamic>.from(json['data'] as Map)
          : <String, dynamic>{},
      sourceType: json['source_type'] as String?,
      sourceId: json['source_id'] as String?,
      dedupeKey: json['dedupe_key'] as String?,
      readAt: json['read_at'] != null
          ? DateTime.tryParse(json['read_at'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? (DateTime.tryParse(json['created_at'] as String) ?? DateTime.now())
          : DateTime.now(),
      expiresAt: json['expires_at'] != null
          ? DateTime.tryParse(json['expires_at'] as String)
          : null,
    );
  }

  @override
  NotificationModel copyWith({
    DateTime? readAt,
  }) {
    return NotificationModel(
      id: id,
      recipientProfileId: recipientProfileId,
      category: category,
      type: type,
      title: title,
      body: body,
      priority: priority,
      data: data,
      sourceType: sourceType,
      sourceId: sourceId,
      dedupeKey: dedupeKey,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt,
      expiresAt: expiresAt,
    );
  }
}
